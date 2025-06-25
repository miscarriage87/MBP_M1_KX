import SwiftUI

struct AIAnalysisView: View {
    @EnvironmentObject var aiManager: AIManager
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var indexingManager: IndexingManager
@Environment(\.dismiss) private var dismiss

@State private var showingAPIKeyInput = false
@State private var isCompact = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("AI Document Analysis")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Powered by OpenAI GPT-4")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // API Key Status
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: aiManager.hasValidKey ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(aiManager.hasValidKey ? .green : .orange)
                        
                        Text(aiManager.hasValidKey ? "OpenAI API Key Configured" : "OpenAI API Key Required")
                            .font(.headline)
                    }
                    
                    if !aiManager.hasValidKey {
                        Button("Configure API Key") {
                            showingAPIKeyInput = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Analysis Status
                if aiManager.isAnalyzing {
                    VStack(spacing: 12) {
                        ProgressView(value: aiManager.analysisProgress)
                            .progressViewStyle(.linear)
                        
                        Text("Analyzing \(documentManager.documents.count) documents...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(aiManager.analysisProgress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Analysis Results
                if !aiManager.analysisResults.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Analysis Results")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(aiManager.analysisResults.count) documents analyzed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(aiManager.analysisResults) { analysis in
                                    AnalysisResultCard(analysis: analysis)
                                }
                            }
                        }
                        .frame(maxHeight: 400)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Actions
                VStack(spacing: 12) {
                    if aiManager.hasValidKey && !documentManager.documents.isEmpty {
                        Button(action: {
                            let indexedContent = Dictionary(uniqueKeysWithValues: 
                                indexingManager.documentIndex.map { ($0.key, $0.value) }
                            )
                            aiManager.analyzeDocuments(documentManager.documents, indexedContent: indexedContent)
                        }) {
                            Label("Start AI Analysis", systemImage: "brain.filled.head.profile")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(aiManager.isAnalyzing)
                    }
                    
                    if !aiManager.analysisResults.isEmpty {
                        Button("Export LLM-Optimized Index") {
                            exportLLMIndex()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("AI Analysis")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAPIKeyInput) {
            APIKeyInputView()
                .environmentObject(aiManager)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    private func exportLLMIndex() {
        let llmIndex = aiManager.generateLLMOptimizedIndex(documentManager.documents, analyses: aiManager.analysisResults)
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "SAP_SuccessFactors_LLM_Index.md"
        
        panel.begin { result in
            if result == .OK, let url = panel.url {
                try? llmIndex.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

struct AnalysisResultCard: View {
    let analysis: AIManager.DocumentAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: analysis.category.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(analysis.documentName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(analysis.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(Int(analysis.sapRelevanceScore * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text("Confidence: \(Int(analysis.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Summary
            Text(analysis.aiSummary)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .lineLimit(3)
            
            // Keywords
            if !analysis.extractedKeywords.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(analysis.extractedKeywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Business Value Scores
            VStack(alignment: .leading, spacing: 6) {
                Text("Business Value")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    BusinessValueIndicator(title: "Implementation", value: analysis.businessValue.implementationRelevance)
                    BusinessValueIndicator(title: "Configuration", value: analysis.businessValue.configurationRelevance)
                    BusinessValueIndicator(title: "Training", value: analysis.businessValue.trainingRelevance)
                    BusinessValueIndicator(title: "Data", value: analysis.businessValue.dataRelevance)
                }
            }
            
            // Recommended Actions
            if !analysis.recommendedActions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended Actions")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(analysis.recommendedActions, id: \.self) { action in
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                            
                            Text(action)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

struct BusinessValueIndicator: View {
    let title: String
    let value: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            ZStack {
                Circle()
                    .stroke(Color(NSColor.separatorColor), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color(for: value), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(value * 100))")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
    }
    
    private func color(for value: Double) -> Color {
        if value >= 0.7 { return .green }
        if value >= 0.4 { return .orange }
        return .red
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets
        
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        let containerWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var currentPosition = CGPoint.zero
        var lineHeight: CGFloat = 0
        var maxY: CGFloat = 0
        
        for size in sizes {
            if currentPosition.x + size.width > containerWidth && currentPosition.x > 0 {
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
            }
            
            offsets.append(currentPosition)
            currentPosition.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxY = max(maxY, currentPosition.y + size.height)
        }
        
        return (offsets, CGSize(width: containerWidth, height: maxY))
    }
}

#Preview {
    AIAnalysisView()
        .environmentObject(AIManager())
        .environmentObject(DocumentManager())
        .environmentObject(IndexingManager())
}
