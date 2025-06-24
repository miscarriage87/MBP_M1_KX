import SwiftUI
import QuickLook

// MARK: - API Key Input View
struct APIKeyInputView: View {
    @EnvironmentObject var aiManager: AIManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey = ""
    @State private var isSecure = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("OpenAI API Key")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your OpenAI API key to enable AI document analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // API Key Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.headline)
                    
                    HStack {
                        Group {
                            if isSecure {
                                SecureField("sk-...", text: $apiKey)
                            } else {
                                TextField("sk-...", text: $apiKey)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        
                        Button(action: {
                            isSecure.toggle()
                        }) {
                            Image(systemName: isSecure ? "eye" : "eye.slash")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("Your API key will be stored securely in your system preferences")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to get an API key:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Visit platform.openai.com", systemImage: "1.circle.fill")
                        Label("Sign in to your account", systemImage: "2.circle.fill")
                        Label("Go to API Keys section", systemImage: "3.circle.fill")
                        Label("Create a new secret key", systemImage: "4.circle.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save API Key") {
                        aiManager.saveAPIKey(apiKey)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)
                }
            }
            .padding()
            .navigationTitle("API Configuration")
        }
        .frame(width: 500, height: 600)
        .onAppear {
            apiKey = aiManager.apiKey
        }
    }
}

// MARK: - Document Detail View
struct DocumentDetailView: View {
    let document: DocumentItem
    @EnvironmentObject var aiManager: AIManager
    
    @State private var showingQuickLook = false
    @State private var quickLookURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: document.category.icon)
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(3)
                            
                            Text(document.category.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // File Info
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(title: "Size", value: document.formattedSize)
                        InfoRow(title: "Type", value: document.type.uppercased())
                        InfoRow(title: "Modified", value: DateFormatter.localizedString(from: document.modificationDate, dateStyle: .medium, timeStyle: .short))
                        InfoRow(title: "Location", value: document.url.path)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // AI Analysis Results
                if let analysis = aiManager.analysisResults.first(where: { $0.documentUrl == document.url }) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Analysis")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // Summary
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Summary")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(analysis.aiSummary)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            
                            Divider()
                            
                            // Keywords
                            if !analysis.extractedKeywords.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Keywords")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    FlowLayout(spacing: 6) {
                                        ForEach(analysis.extractedKeywords, id: \.self) { keyword in
                                            Text(keyword)
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(Color.accentColor.opacity(0.1))
                                                .foregroundColor(.accentColor)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                
                                Divider()
                            }
                            
                            // Business Value
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Business Value Assessment")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                VStack(spacing: 8) {
                                    BusinessValueRow(title: "Implementation Relevance", value: analysis.businessValue.implementationRelevance)
                                    BusinessValueRow(title: "Configuration Relevance", value: analysis.businessValue.configurationRelevance)
                                    BusinessValueRow(title: "Training Relevance", value: analysis.businessValue.trainingRelevance)
                                    BusinessValueRow(title: "Data Relevance", value: analysis.businessValue.dataRelevance)
                                    BusinessValueRow(title: "Compliance Relevance", value: analysis.businessValue.complianceRelevance)
                                }
                            }
                            
                            // Recommended Actions
                            if !analysis.recommendedActions.isEmpty {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recommended Actions")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(analysis.recommendedActions, id: \.self) { action in
                                            HStack(spacing: 8) {
                                                Image(systemName: "checkmark.circle")
                                                    .foregroundColor(.accentColor)
                                                
                                                Text(action)
                                                    .font(.body)
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                    }
                }
                
                // Actions
                HStack(spacing: 12) {
                    Button("Open in Finder") {
                        NSWorkspace.shared.selectFile(document.url.path, inFileViewerRootedAtPath: "")
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Quick Look") {
                        quickLookURL = document.url
                        showingQuickLook = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(document.name)
        .quickLookPreview($quickLookURL)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct BusinessValueRow: View {
    let title: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                ProgressView(value: value)
                    .progressViewStyle(.linear)
                    .frame(width: 100)
                
                Text("\(Int(value * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var indexingManager: IndexingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
            
            GroupBox("Document Processing") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Auto-organize new documents", isOn: .constant(true))
                    Toggle("Enable background indexing", isOn: .constant(true))
                    Toggle("Extract text from images", isOn: .constant(false))
                }
                .padding()
            }
            
            GroupBox("AI Integration") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable AI analysis", isOn: .constant(true))
                    Toggle("Auto-generate summaries", isOn: .constant(false))
                    Toggle("Smart categorization", isOn: .constant(true))
                }
                .padding()
            }
            
            GroupBox("Performance") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Index cache size")
                        Spacer()
                        Text("125 MB")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Indexed documents")
                        Spacer()
                        Text("\(indexingManager.indexedCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Cache") {
                        // Clear cache implementation
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Export View
struct ExportView: View {
    @EnvironmentObject var indexingManager: IndexingManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat = ExportFormat.markdown
    @State private var includeContent = true
    @State private var includeMetadata = true
    
    enum ExportFormat: String, CaseIterable {
        case markdown = "Markdown"
        case json = "JSON"
        case csv = "CSV"
        
        var fileExtension: String {
            switch self {
            case .markdown: return "md"
            case .json: return "json"
            case .csv: return "csv"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Document Index")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Format")
                        .font(.headline)
                    
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Include")
                            .font(.headline)
                        
                        Toggle("Document content", isOn: $includeContent)
                        Toggle("Metadata", isOn: $includeMetadata)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Export") {
                        exportIndex()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Export")
        }
        .frame(width: 400, height: 300)
    }
    
    private func exportIndex() {
        let content = indexingManager.exportLLMIndex()
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "document_index.\(selectedFormat.fileExtension)"
        
        panel.begin { result in
            if result == .OK, let url = panel.url {
                try? content.write(to: url, atomically: true, encoding: .utf8)
                dismiss()
            }
        }
    }
}

#Preview("API Key Input") {
    APIKeyInputView()
        .environmentObject(AIManager())
}

#Preview("Settings") {
    SettingsView()
        .environmentObject(DocumentManager())
        .environmentObject(IndexingManager())
}
