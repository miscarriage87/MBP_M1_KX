import Foundation
import SwiftUI
import Combine
import OSLog
import PDFKit
import UniformTypeIdentifiers

class IndexingManager: BaseCancellableOperation {
    private let processingDelay: TimeInterval
    
    init(processingDelay: TimeInterval = 0) {
        self.processingDelay = processingDelay
        super.init()
    }
    private let logger = Logger(subsystem: "DocumentOrganizer", category: "IndexingManager")
    
    @Published var isIndexing = false
    @Published var indexingProgress: Double = 0.0
    @Published var searchResults: [SearchResult] = []
    @Published var indexedCount = 0
    
    private var _documentIndex: [String: DocumentIndex] = [:]
    
    var documentIndex: [String: DocumentIndex] {
        return _documentIndex
    }
    private var contentIndex: [String: Set<String>] = [:] // Word to document IDs mapping
    private let indexQueue = DispatchQueue(label: "indexing.queue", qos: .utility)
    private let searchQueue = DispatchQueue(label: "search.queue", qos: .userInitiated)
    
    
    // LLM-optimized metadata extraction
    struct DocumentIndex {
        let id: String
        let url: URL
        let title: String
        let content: String
        let keywords: [String]
        let category: DocumentCategory
        let metadata: DocumentMetadata
        let extractedText: String
        let summary: String
    }
    
    struct DocumentMetadata {
        let author: String?
        let creationDate: Date?
        let modificationDate: Date
        let pageCount: Int?
        let wordCount: Int
        let language: String?
        let size: Int64
    }
    
    func indexDocuments(_ documents: [DocumentItem]) {
        guard !documents.isEmpty else { return }
        
        _ = startTask {
            try await self.performIndexing(documents)
        }
    }
    
    private func performIndexing(_ documents: [DocumentItem]) async throws {
        let totalCount = documents.count
        var processedCount = 0
        
        await MainActor.run {
            self.isIndexing = true
            self.indexingProgress = 0.0
            self.indexedCount = 0
            self._documentIndex.removeAll()
            self.contentIndex.removeAll()
        }
        
        for document in documents {
            try await checkCancellation() // Check for cancellation before processing each document
            
            // Add processing delay for testing observability
            if processingDelay > 0 {
                try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
            }
            
            autoreleasepool {
                if let index = extractDocumentContent(document) {
                    _documentIndex[index.id] = index
                    
                    // Build inverted index for fast search
                    let words = tokenizeText(index.content + " " + index.title + " " + index.keywords.joined(separator: " "))
                    for word in words {
                        if contentIndex[word] == nil {
                            contentIndex[word] = Set<String>()
                        }
                        contentIndex[word]?.insert(index.id)
                    }
                }
                
                processedCount += 1
                
                Task { @MainActor in
                    self.indexingProgress = Double(processedCount) / Double(totalCount)
                    self.indexedCount = processedCount
                }
            }
        }
        
        await MainActor.run {
            self.isIndexing = false
            self.logger.info("Indexing completed. Processed \(processedCount) documents")
        }
    }
    
    private func extractDocumentContent(_ document: DocumentItem) -> DocumentIndex? {
        let id = document.url.absoluteString
        var extractedText = ""
        var title = document.name
        var keywords: [String] = []
        var metadata = DocumentMetadata(
            author: nil,
            creationDate: nil,
            modificationDate: document.modificationDate,
            pageCount: nil,
            wordCount: 0,
            language: nil,
            size: Int64(document.size)
        )
        
        switch document.type.lowercased() {
        case "pdf":
            if let pdfContent = extractPDFContent(document.url) {
                extractedText = pdfContent.text
                title = pdfContent.title ?? title
                metadata = DocumentMetadata(
                    author: pdfContent.author,
                    creationDate: pdfContent.creationDate,
                    modificationDate: document.modificationDate,
                    pageCount: pdfContent.pageCount,
                    wordCount: pdfContent.wordCount,
                    language: pdfContent.language,
                    size: Int64(document.size)
                )
            }
            
        case "txt", "rtf":
            extractedText = extractTextContent(document.url) ?? ""
            
        case "xlsx", "xls", "csv":
            extractedText = extractSpreadsheetMetadata(document.url)
            
        case "pptx", "ppt":
            extractedText = extractPresentationMetadata(document.url)
            
        default:
            extractedText = document.name
        }
        
        // Generate keywords based on SAP SuccessFactors context
        keywords = generateKeywords(from: extractedText, fileName: document.name, category: document.category)
        
        // Generate summary for LLM consumption
        let summary = generateSummary(from: extractedText, title: title, category: document.category)
        
        return DocumentIndex(
            id: id,
            url: document.url,
            title: title,
            content: extractedText,
            keywords: keywords,
            category: document.category,
            metadata: metadata,
            extractedText: extractedText,
            summary: summary
        )
    }
    
    private func extractPDFContent(_ url: URL) -> (text: String, title: String?, author: String?, creationDate: Date?, pageCount: Int, wordCount: Int, language: String?)? {
        guard let pdfDocument = PDFDocument(url: url) else { return nil }
        
        var fullText = ""
        let pageCount = pdfDocument.pageCount
        
        for i in 0..<pageCount {
            if let page = pdfDocument.page(at: i) {
                fullText += page.string ?? ""
                fullText += "\n"
            }
        }
        
        let title = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        let author = pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
        let creationDate = pdfDocument.documentAttributes?[PDFDocumentAttribute.creationDateAttribute] as? Date
        
        let wordCount = fullText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        return (
            text: fullText,
            title: title,
            author: author,
            creationDate: creationDate,
            pageCount: pageCount,
            wordCount: wordCount,
            language: detectLanguage(fullText)
        )
    }
    
    private func extractTextContent(_ url: URL) -> String? {
        return try? String(contentsOf: url, encoding: .utf8)
    }
    
    private func extractSpreadsheetMetadata(_ url: URL) -> String {
        // For spreadsheets, we extract metadata and sheet names
        let fileName = url.lastPathComponent
        return "Spreadsheet: \(fileName). Contains data tables, potentially including HR data, employee information, reports, or SAP SuccessFactors export data."
    }
    
    private func extractPresentationMetadata(_ url: URL) -> String {
        // For presentations, we extract metadata
        let fileName = url.lastPathComponent
        return "Presentation: \(fileName). Likely contains slides for training, project presentations, or client deliverables related to SAP SuccessFactors implementation."
    }
    
    private func generateKeywords(from text: String, fileName: String, category: DocumentCategory) -> [String] {
        var keywords: [String] = []
        let lowercaseText = (text + " " + fileName).lowercased()
        
        // SAP SuccessFactors specific keywords
        let sapKeywords = [
            "successfactors", "sf", "sap", "employee central", "performance management",
            "recruitment", "onboarding", "learning management", "compensation", "benefits",
            "time tracking", "analytics", "reporting", "integration", "odata", "api",
            "hcm", "hr transformation", "talent management", "organizational management"
        ]
        
        // Technical implementation keywords
        let techKeywords = [
            "configuration", "setup", "implementation", "go-live", "testing", "deployment",
            "data migration", "integration", "security", "roles", "permissions", "workflow",
            "business rules", "calculated fields", "picklist", "import", "export"
        ]
        
        // HR process keywords
        let hrKeywords = [
            "employee", "manager", "hierarchy", "position", "job", "department", "location",
            "skills", "competencies", "goals", "performance", "review", "feedback",
            "development", "training", "certification", "succession planning"
        ]
        
        let allKeywords = sapKeywords + techKeywords + hrKeywords
        
        for keyword in allKeywords {
            if lowercaseText.contains(keyword) {
                keywords.append(keyword)
            }
        }
        
        // Add category-specific keywords
        keywords.append(category.rawValue.lowercased())
        
        return Array(Set(keywords)) // Remove duplicates
    }
    
    private func generateSummary(from text: String, title: String, category: DocumentCategory) -> String {
        let truncatedText = String(text.prefix(500)) // First 500 characters
        
        return """
        Document: \(title)
        Category: \(category.rawValue)
        Content Preview: \(truncatedText)
        
        This document appears to be related to SAP SuccessFactors HR transformation and implementation work. It contains information relevant to \(category.rawValue.lowercased()) and may include technical specifications, business requirements, or process documentation for HR system implementation.
        """
    }
    
    private func detectLanguage(_ text: String) -> String? {
        let recognizer = NSLinguisticTagger(tagSchemes: [.language], options: 0)
        recognizer.string = text
        return recognizer.dominantLanguage
    }
    
    private func tokenizeText(_ text: String) -> Set<String> {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 } // Filter out very short words
            .filter { !stopWords.contains($0) }
        
        return Set(words)
    }
    
    private let stopWords: Set<String> = [
        "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by",
        "a", "an", "is", "are", "was", "were", "be", "been", "have", "has", "had",
        "do", "does", "did", "will", "would", "could", "should", "may", "might",
        "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they"
    ]
    
    func search(_ query: String) {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }
        
        searchQueue.async { [weak self] in
            self?.performSearch(query)
        }
    }
    
    private func performSearch(_ query: String) {
        let queryWords = tokenizeText(query)
        var documentScores: [String: Double] = [:]
        
        // Calculate relevance scores
        for word in queryWords {
            if let matchingDocs = contentIndex[word] {
                let weight = 1.0 / Double(matchingDocs.count) // TF-IDF style weighting
                
                for docId in matchingDocs {
                    documentScores[docId, default: 0.0] += weight
                }
            }
        }
        
        // Convert to search results and sort by relevance
        let results = documentScores.compactMap { (docId, score) -> SearchResult? in
            guard let index = _documentIndex[docId] else { return nil }
            
            return SearchResult(
                document: index,
                relevanceScore: score,
                matchingText: extractMatchingText(from: index.content, query: query)
            )
        }.sorted { $0.relevanceScore > $1.relevanceScore }
        
        DispatchQueue.main.async {
            self.searchResults = Array(results.prefix(50)) // Limit to top 50 results
        }
    }
    
    private func extractMatchingText(from content: String, query: String) -> String {
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let sentences = content.components(separatedBy: ". ")
        
        for sentence in sentences {
            if queryWords.allSatisfy({ sentence.lowercased().contains($0) }) {
                return String(sentence.prefix(200)) + "..."
            }
        }
        
        return String(content.prefix(200)) + "..."
    }
    
    // Export index for LLM consumption
    func exportLLMIndex() -> String {
        var llmIndex = ""
        
        llmIndex += "# SAP SuccessFactors Document Index\n\n"
        llmIndex += "## Document Categories and Structure\n\n"
        
        let groupedDocs = Dictionary(grouping: _documentIndex.values) { $0.category }
        
        for category in DocumentCategory.allCases {
            if let docs = groupedDocs[category], !docs.isEmpty {
                llmIndex += "### \(category.rawValue) (\(docs.count) documents)\n\n"
                
                for doc in docs.sorted(by: { $0.metadata.modificationDate > $1.metadata.modificationDate }) {
                    llmIndex += "**\(doc.title)**\n"
                    llmIndex += "- Path: \(doc.url.path)\n"
                    llmIndex += "- Modified: \(DateFormatter.localizedString(from: doc.metadata.modificationDate, dateStyle: .medium, timeStyle: .short))\n"
                    llmIndex += "- Size: \(ByteCountFormatter.string(fromByteCount: doc.metadata.size, countStyle: .file))\n"
                    llmIndex += "- Keywords: \(doc.keywords.joined(separator: ", "))\n"
                    llmIndex += "- Summary: \(doc.summary)\n\n"
                }
            }
        }
        
        return llmIndex
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let document: IndexingManager.DocumentIndex
    let relevanceScore: Double
    let matchingText: String
}
