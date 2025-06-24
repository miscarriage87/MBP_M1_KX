import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var indexingManager: IndexingManager
    @StateObject private var aiManager = AIManager()
    
    @State private var selectedDirectory: URL?
    @State private var searchText = ""
    @State private var selectedCategory: DocumentCategory? = nil
    @State private var showingFileImporter = false
    @State private var showingAIAnalysis = false
    @State private var showingExportSheet = false
    
    var filteredDocuments: [DocumentItem] {
        var documents = documentManager.documents
        
        if let category = selectedCategory {
            documents = documents.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            documents = documents.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return documents
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Document Organizer")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("SAP SuccessFactors HR Documents")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        showingFileImporter = true
                    }) {
                        Label("Select Directory", systemImage: "folder.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if !documentManager.documents.isEmpty {
                        Button(action: {
                            documentManager.organizeDocuments()
                        }) {
                            Label("Organize Files", systemImage: "folder.badge.gearshape")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            indexingManager.indexDocuments(documentManager.documents)
                        }) {
                            Label("Build Index", systemImage: "magnifyingglass.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            showingAIAnalysis = true
                        }) {
                            Label("AI Analysis", systemImage: "brain.head.profile")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Categories
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categories")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            CategoryRow(
                                category: nil,
                                count: documentManager.documents.count,
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(DocumentCategory.allCases, id: \.self) { category in
                                let count = documentManager.documents.filter { $0.category == category }.count
                                if count > 0 {
                                    CategoryRow(
                                        category: category,
                                        count: count,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Status
                if documentManager.isScanning || indexingManager.isIndexing {
                    VStack(alignment: .leading, spacing: 8) {
                        if documentManager.isScanning {
                            Text("Scanning...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ProgressView(value: documentManager.scanProgress)
                                .progressViewStyle(.linear)
                        }
                        
                        if indexingManager.isIndexing {
                            Text("Indexing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ProgressView(value: indexingManager.indexingProgress)
                                .progressViewStyle(.linear)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(minWidth: 250)
            
        } content: {
            // Main Content
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search documents...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) {
                            if !searchText.isEmpty {
                                indexingManager.search(searchText)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            indexingManager.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Document List
                if !searchText.isEmpty && !indexingManager.searchResults.isEmpty {
                    // Search Results
                    List(indexingManager.searchResults) { result in
                        SearchResultRow(result: result)
                    }
                    .listStyle(.plain)
                } else {
                    // Document List
                    if filteredDocuments.isEmpty {
                        ContentUnavailableView(
                            "No Documents",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Select a directory to scan for documents")
                        )
                    } else {
                        List(filteredDocuments) { document in
                            DocumentRow(document: document)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            
        } detail: {
            // Detail View
            if let selectedDocument = getSelectedDocument() {
                DocumentDetailView(document: selectedDocument)
                    .environmentObject(aiManager)
            } else {
                ContentUnavailableView(
                    "Select a Document",
                    systemImage: "doc.text",
                    description: Text("Choose a document to view details and AI analysis")
                )
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedDirectory = url
                    documentManager.scanDirectory(url)
                }
            case .failure(let error):
                print("Error selecting directory: \(error)")
            }
        }
        .sheet(isPresented: $showingAIAnalysis) {
            AIAnalysisView()
                .environmentObject(aiManager)
                .environmentObject(documentManager)
                .environmentObject(indexingManager)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
                .environmentObject(indexingManager)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Export LLM Index") {
                        showingExportSheet = true
                    }
                    
                    Button("AI Analysis") {
                        showingAIAnalysis = true
                    }
                    
                    Divider()
                    
                    Button("Refresh") {
                        if let url = selectedDirectory {
                            documentManager.scanDirectory(url)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private func getSelectedDocument() -> DocumentItem? {
        // This would be implemented with proper selection state management
        return filteredDocuments.first
    }
}

struct CategoryRow: View {
    let category: DocumentCategory?
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category?.icon ?? "folder")
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category?.rawValue ?? "All Documents")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    if count > 0 {
                        Text("\(count) items")
                            .font(.system(size: 11))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DocumentRow: View {
    let document: DocumentItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.category.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(document.category.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(document.formattedSize)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(DateFormatter.localizedString(from: document.modificationDate, dateStyle: .short, timeStyle: .none))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.document.category.icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.document.title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    
                    Text(result.document.category.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(String(format: "%.0f%%", result.relevanceScore * 100))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text(result.matchingText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(DocumentManager())
        .environmentObject(IndexingManager())
}
