import Foundation
import SwiftUI
import Combine
import OSLog

class AIManager: ObservableObject {
    private let logger = Logger(subsystem: "DocumentOrganizer", category: "AIManager")
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var analysisResults: [DocumentAnalysis] = []
    @Published var apiKey: String = ""
    @Published var hasValidKey = false
    
    private let openAIBaseURL = "https://api.openai.com/v1"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    struct DocumentAnalysis: Identifiable {
        let id = UUID()
        let documentUrl: URL
        let documentName: String
        let category: DocumentCategory
        let aiSummary: String
        let extractedKeywords: [String]
        let recommendedActions: [String]
        let sapRelevanceScore: Double
        let documentType: String
        let confidence: Double
        let businessValue: BusinessValue
        let suggestedTags: [String]
    }
    
    struct BusinessValue {
        let implementationRelevance: Double
        let configurationRelevance: Double
        let trainingRelevance: Double
        let dataRelevance: Double
        let complianceRelevance: Double
    }
    
    init() {
        loadAPIKey()
    }
    
    private func loadAPIKey() {
        // Try to load from Keychain or UserDefaults
        if let key = UserDefaults.standard.string(forKey: "OpenAI_API_Key"), !key.isEmpty {
            apiKey = key
            hasValidKey = true
        }
    }
    
    func saveAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: "OpenAI_API_Key")
        hasValidKey = !key.isEmpty
    }
    
    func analyzeDocuments(_ documents: [DocumentItem], indexedContent: [String: IndexingManager.DocumentIndex]) {
        guard !apiKey.isEmpty else {
            logger.error("OpenAI API key not provided")
            return
        }
        
        isAnalyzing = true
        analysisProgress = 0.0
        analysisResults.removeAll()
        
        Task {
            await performBatchAnalysis(documents, indexedContent: indexedContent)
        }
    }
    
    @MainActor
    private func performBatchAnalysis(_ documents: [DocumentItem], indexedContent: [String: IndexingManager.DocumentIndex]) async {
        let totalCount = documents.count
        var processedCount = 0
        
        // Process documents in batches to avoid rate limits
        let batchSize = 5
        let batches = documents.chunked(into: batchSize)
        
        for batch in batches {
            await withTaskGroup(of: DocumentAnalysis?.self) { group in
                for document in batch {
                    group.addTask {
                        await self.analyzeDocument(document, indexedContent: indexedContent)
                    }
                }
                
                for await result in group {
                    if let analysis = result {
                        analysisResults.append(analysis)
                    }
                    
                    processedCount += 1
                    analysisProgress = Double(processedCount) / Double(totalCount)
                }
            }
            
            // Rate limiting delay between batches
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        isAnalyzing = false
        logger.info("AI analysis completed for \(analysisResults.count) documents")
    }
    
    private func analyzeDocument(_ document: DocumentItem, indexedContent: [String: IndexingManager.DocumentIndex]) async -> DocumentAnalysis? {
        let documentId = document.url.absoluteString
        let indexedDoc = indexedContent[documentId]
        
        let prompt = createAnalysisPrompt(document: document, indexedDocument: indexedDoc)
        
        do {
            let response = await callOpenAI(prompt: prompt)
            return parseAnalysisResponse(response, document: document)
        } catch {
            logger.error("Error analyzing document \(document.name): \(error)")
            return nil
        }
    }
    
    private func createAnalysisPrompt(document: DocumentItem, indexedDocument: IndexingManager.DocumentIndex?) -> String {
        let content = indexedDocument?.content ?? ""
        let truncatedContent = String(content.prefix(2000)) // Limit content size
        
        return """
        Analyze this SAP SuccessFactors HR document and provide structured insights:
        
        Document Name: \(document.name)
        File Type: \(document.type)
        Current Category: \(document.category.rawValue)
        Size: \(document.formattedSize)
        
        Content Preview:
        \(truncatedContent)
        
        Please analyze and respond with JSON in this exact format:
        {
            "summary": "Brief description of document content and purpose",
            "keywords": ["keyword1", "keyword2", "keyword3"],
            "recommended_actions": ["action1", "action2"],
            "sap_relevance_score": 0.85,
            "confidence": 0.90,
            "business_value": {
                "implementation_relevance": 0.8,
                "configuration_relevance": 0.6,
                "training_relevance": 0.4,
                "data_relevance": 0.7,
                "compliance_relevance": 0.5
            },
            "suggested_tags": ["tag1", "tag2", "tag3"]
        }
        
        Focus on:
        - SAP SuccessFactors implementation relevance
        - HR transformation value
        - Technical configuration aspects
        - Training and documentation quality
        - Data migration and integration aspects
        - Compliance and security considerations
        """
    }
    
    private func callOpenAI(prompt: String) async -> String {
        do {
            let request = createOpenAIRequest(prompt: prompt)
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw AIError.invalidResponse
            }
            
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return openAIResponse.choices.first?.message.content ?? ""
            
        } catch {
            logger.error("OpenAI API call failed: \(error)")
            throw error
        }
    }
    
    private func createOpenAIRequest(prompt: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "\(openAIBaseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: [
                OpenAIMessage(role: "system", content: "You are an expert SAP SuccessFactors consultant analyzing HR transformation documents. Provide structured, actionable insights."),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: 0.3,
            maxTokens: 1500
        )
        
        request.httpBody = try? JSONEncoder().encode(requestBody)
        return request
    }
    
    private func parseAnalysisResponse(_ response: String, document: DocumentItem) -> DocumentAnalysis? {
        // Extract JSON from response (OpenAI sometimes adds extra text)
        let jsonStartIndex = response.range(of: "{")?.lowerBound ?? response.startIndex
        let jsonEndIndex = response.range(of: "}", options: .backwards)?.upperBound ?? response.endIndex
        let jsonString = String(response[jsonStartIndex..<jsonEndIndex])
        
        guard let jsonData = jsonString.data(using: .utf8),
              let analysisData = try? JSONDecoder().decode(AnalysisResponse.self, from: jsonData) else {
            logger.error("Failed to parse AI analysis response for \(document.name)")
            return createFallbackAnalysis(document: document)
        }
        
        return DocumentAnalysis(
            documentUrl: document.url,
            documentName: document.name,
            category: document.category,
            aiSummary: analysisData.summary,
            extractedKeywords: analysisData.keywords,
            recommendedActions: analysisData.recommendedActions,
            sapRelevanceScore: analysisData.sapRelevanceScore,
            documentType: document.type,
            confidence: analysisData.confidence,
            businessValue: BusinessValue(
                implementationRelevance: analysisData.businessValue.implementationRelevance,
                configurationRelevance: analysisData.businessValue.configurationRelevance,
                trainingRelevance: analysisData.businessValue.trainingRelevance,
                dataRelevance: analysisData.businessValue.dataRelevance,
                complianceRelevance: analysisData.businessValue.complianceRelevance
            ),
            suggestedTags: analysisData.suggestedTags
        )
    }
    
    private func createFallbackAnalysis(document: DocumentItem) -> DocumentAnalysis {
        return DocumentAnalysis(
            documentUrl: document.url,
            documentName: document.name,
            category: document.category,
            aiSummary: "Document analysis unavailable - manual review recommended",
            extractedKeywords: [document.category.rawValue.lowercased()],
            recommendedActions: ["Manual review required"],
            sapRelevanceScore: 0.5,
            documentType: document.type,
            confidence: 0.1,
            businessValue: BusinessValue(
                implementationRelevance: 0.5,
                configurationRelevance: 0.5,
                trainingRelevance: 0.5,
                dataRelevance: 0.5,
                complianceRelevance: 0.5
            ),
            suggestedTags: ["needs-review"]
        )
    }
    
    func generateLLMOptimizedIndex(_ documents: [DocumentItem], analyses: [DocumentAnalysis]) -> String {
        var llmIndex = ""
        
        llmIndex += "# SAP SuccessFactors Document Collection - LLM Optimized Index\n\n"
        llmIndex += "## Overview\n"
        llmIndex += "This collection contains \(documents.count) documents related to SAP SuccessFactors HR transformation.\n"
        llmIndex += "All documents have been analyzed and categorized for optimal LLM consumption.\n\n"
        
        llmIndex += "## Document Categories and AI Analysis\n\n"
        
        let groupedAnalyses = Dictionary(grouping: analyses) { $0.category }
        
        for category in DocumentCategory.allCases {
            guard let categoryAnalyses = groupedAnalyses[category], !categoryAnalyses.isEmpty else { continue }
            
            llmIndex += "### \(category.rawValue) (\(categoryAnalyses.count) documents)\n\n"
            
            // Category-level insights
            let avgRelevance = categoryAnalyses.map(\.sapRelevanceScore).reduce(0, +) / Double(categoryAnalyses.count)
            llmIndex += "**Category Relevance Score:** \(String(format: "%.1f", avgRelevance * 100))%\n\n"
            
            // Top keywords for category
            let allKeywords = categoryAnalyses.flatMap(\.extractedKeywords)
            let keywordCounts = Dictionary(grouping: allKeywords) { $0 }.mapValues(\.count)
            let topKeywords = keywordCounts.sorted { $0.value > $1.value }.prefix(10).map(\.key)
            llmIndex += "**Key Topics:** \(topKeywords.joined(separator: ", "))\n\n"
            
            // Individual documents
            for analysis in categoryAnalyses.sorted(by: { $0.sapRelevanceScore > $1.sapRelevanceScore }) {
                llmIndex += "#### \(analysis.documentName)\n"
                llmIndex += "- **Path:** \(analysis.documentUrl.path)\n"
                llmIndex += "- **SAP Relevance:** \(String(format: "%.0f", analysis.sapRelevanceScore * 100))%\n"
                llmIndex += "- **Confidence:** \(String(format: "%.0f", analysis.confidence * 100))%\n"
                llmIndex += "- **Summary:** \(analysis.aiSummary)\n"
                llmIndex += "- **Keywords:** \(analysis.extractedKeywords.joined(separator: ", "))\n"
                llmIndex += "- **Recommended Actions:** \(analysis.recommendedActions.joined(separator: "; "))\n"
                llmIndex += "- **Business Value Scores:**\n"
                llmIndex += "  - Implementation: \(String(format: "%.0f", analysis.businessValue.implementationRelevance * 100))%\n"
                llmIndex += "  - Configuration: \(String(format: "%.0f", analysis.businessValue.configurationRelevance * 100))%\n"
                llmIndex += "  - Training: \(String(format: "%.0f", analysis.businessValue.trainingRelevance * 100))%\n"
                llmIndex += "  - Data: \(String(format: "%.0f", analysis.businessValue.dataRelevance * 100))%\n"
                llmIndex += "  - Compliance: \(String(format: "%.0f", analysis.businessValue.complianceRelevance * 100))%\n"
                llmIndex += "- **Tags:** \(analysis.suggestedTags.joined(separator: ", "))\n\n"
            }
        }
        
        return llmIndex
    }
}

// MARK: - OpenAI API Models
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

// MARK: - Analysis Response Models
struct AnalysisResponse: Codable {
    let summary: String
    let keywords: [String]
    let recommendedActions: [String]
    let sapRelevanceScore: Double
    let confidence: Double
    let businessValue: BusinessValueResponse
    let suggestedTags: [String]
    
    enum CodingKeys: String, CodingKey {
        case summary, keywords, confidence
        case recommendedActions = "recommended_actions"
        case sapRelevanceScore = "sap_relevance_score"
        case businessValue = "business_value"
        case suggestedTags = "suggested_tags"
    }
}

struct BusinessValueResponse: Codable {
    let implementationRelevance: Double
    let configurationRelevance: Double
    let trainingRelevance: Double
    let dataRelevance: Double
    let complianceRelevance: Double
    
    enum CodingKeys: String, CodingKey {
        case implementationRelevance = "implementation_relevance"
        case configurationRelevance = "configuration_relevance"
        case trainingRelevance = "training_relevance"
        case dataRelevance = "data_relevance"
        case complianceRelevance = "compliance_relevance"
    }
}

enum AIError: Error {
    case invalidResponse
    case networkError
    case parseError
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
