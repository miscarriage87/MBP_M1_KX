import Foundation
import SwiftUI
import Combine
import OSLog

class DocumentManager: BaseCancellableOperation {
    private let processingDelay: TimeInterval
    
    init(processingDelay: TimeInterval = 0) {
        self.processingDelay = processingDelay
        super.init()
        setupDirectoryStructure()
    }
    private let logger = Logger(subsystem: "DocumentOrganizer", category: "DocumentManager")
    
    @Published var documents: [DocumentItem] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var totalDocuments = 0
    @Published var organizedDocuments = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    private let documentQueue = DispatchQueue(label: "document.processing", qos: .userInitiated)
    
    // Supported file types for HR/SAP SuccessFactors consulting
    private let supportedTypes: Set<String> = [
        "pdf", "ppt", "pptx", "xls", "xlsx", "doc", "docx", 
        "txt", "rtf", "csv", "json", "xml", "zip"
    ]
    
    
    private func setupDirectoryStructure() {
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let organizedURL = homeURL.appendingPathComponent("OrganizedDocuments")
        
        // Create base directory if it doesn't exist
        if !fileManager.fileExists(atPath: organizedURL.path) {
            try? fileManager.createDirectory(at: organizedURL, withIntermediateDirectories: true)
        }
    }
    
    func scanDirectory(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Failed to access directory: \(url.path)")
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        _ = startTask {
            try await self.performDirectoryScan(url)
        }
    }
    
    private func performDirectoryScan(_ url: URL) async throws {
        let resourceKeys: [URLResourceKey] = [
            .isRegularFileKey, .typeIdentifierKey, .fileSizeKey,
            .contentModificationDateKey, .nameKey, .pathKey
        ]
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            await MainActor.run {
                self.isScanning = false
            }
            return
        }
        
        var foundDocuments: [DocumentItem] = []
        var processedCount = 0
        
        await MainActor.run {
            self.isScanning = true
            self.scanProgress = 0.0
            self.documents.removeAll()
        }
        
        // Convert enumerator to array to avoid async iteration issues
        let allURLs = Array(enumerator.compactMap { $0 as? URL })
        
        for fileURL in allURLs {
            try await checkCancellation() // Check for cancellation before processing each file
            
            // Add processing delay for testing observability
            if processingDelay > 0 {
                try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
            }
            
            autoreleasepool {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                    
                    guard let isRegularFile = resourceValues.isRegularFile,
                          isRegularFile,
                          let fileExtension = fileURL.pathExtension.lowercased().isEmpty ? nil : fileURL.pathExtension.lowercased(),
                          supportedTypes.contains(fileExtension) else {
                        return
                    }
                    
                    let document = DocumentItem(
                        url: fileURL,
                        name: resourceValues.name ?? fileURL.lastPathComponent,
                        size: resourceValues.fileSize ?? 0,
                        modificationDate: resourceValues.contentModificationDate ?? Date(),
                        type: fileExtension,
                        category: categorizeDocument(fileURL.lastPathComponent, type: fileExtension)
                    )
                    
                    foundDocuments.append(document)
                    processedCount += 1
                    
                    if processedCount % 100 == 0 {
                        Task { @MainActor in
                            self.scanProgress = min(Double(processedCount) / 10000.0, 0.9) // Rough estimate, cap at 90%
                            self.totalDocuments = processedCount
                        }
                    }
                    
                } catch {
                    logger.error("Error processing file \(fileURL.path): \(error)")
                }
            }
        }
        
        await MainActor.run {
            self.documents = foundDocuments.sorted { $0.modificationDate > $1.modificationDate }
            self.totalDocuments = foundDocuments.count
            self.isScanning = false
            self.scanProgress = 1.0
            self.logger.info("Scan completed. Found \(foundDocuments.count) documents")
        }
    }
    
    private func categorizeDocument(_ fileName: String, type: String) -> DocumentCategory {
        let lowerName = fileName.lowercased()
        
        // SAP SuccessFactors specific categorization
        if lowerName.contains("successfactors") || lowerName.contains("sf") || lowerName.contains("sap") {
            if lowerName.contains("config") || lowerName.contains("setup") {
                return .configuration
            } else if lowerName.contains("template") || lowerName.contains("form") {
                return .templates
            } else if lowerName.contains("training") || lowerName.contains("guide") {
                return .training
            } else {
                return .sapDocuments
            }
        }
        
        // HR specific categorization
        if lowerName.contains("hr") || lowerName.contains("human") || lowerName.contains("employee") {
            return .hrDocuments
        }
        
        // Implementation and project docs
        if lowerName.contains("implementation") || lowerName.contains("project") || lowerName.contains("requirement") {
            return .implementation
        }
        
        // Data and reports
        if type == "xlsx" || type == "xls" || type == "csv" || lowerName.contains("data") || lowerName.contains("report") {
            return .dataFiles
        }
        
        // Presentations
        if type == "ppt" || type == "pptx" {
            return .presentations
        }
        
        // Documentation
        if type == "pdf" || type == "doc" || type == "docx" || lowerName.contains("manual") || lowerName.contains("guide") {
            return .documentation
        }
        
        return .other
    }
    
    func organizeDocuments() {
        guard !documents.isEmpty else { return }
        
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let organizedURL = homeURL.appendingPathComponent("OrganizedDocuments")
        
        createOrganizedStructure(at: organizedURL)
        
        _ = startTask {
            try await self.performDocumentOrganization(to: organizedURL)
        }
    }
    
    private func createOrganizedStructure(at baseURL: URL) {
        let categories = DocumentCategory.allCases
        
        for category in categories {
            let categoryURL = baseURL.appendingPathComponent(category.folderName)
            try? fileManager.createDirectory(at: categoryURL, withIntermediateDirectories: true)
        }
    }
    
    private func performDocumentOrganization(to baseURL: URL) async throws {
        let totalCount = documents.count
        var processedCount = 0
        
        for document in documents {
            try await checkCancellation() // Check for cancellation before each document
            
            autoreleasepool {
                let categoryFolder = baseURL.appendingPathComponent(document.category.folderName)
                let destinationURL = categoryFolder.appendingPathComponent(document.name)
                
                do {
                    // Create symbolic link instead of copying to save space
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    
                    try fileManager.createSymbolicLink(at: destinationURL, withDestinationURL: document.url)
                    
                    processedCount += 1
                    
                    Task { @MainActor in
                        self.organizedDocuments = processedCount
                        await self.updateProgress(Double(processedCount) / Double(totalCount))
                    }
                    
                } catch {
                    logger.error("Failed to organize document \(document.name): \(error)")
                }
            }
        }
        
        await MainActor.run {
            self.logger.info("Organization completed. Processed \(processedCount) documents")
        }
    }
}

struct DocumentItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int
    let modificationDate: Date
    let type: String
    let category: DocumentCategory
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: DocumentItem, rhs: DocumentItem) -> Bool {
        lhs.url == rhs.url
    }
}

enum DocumentCategory: String, CaseIterable {
    case sapDocuments = "SAP SuccessFactors"
    case hrDocuments = "HR Documents"
    case implementation = "Implementation"
    case configuration = "Configuration"
    case templates = "Templates"
    case training = "Training Materials"
    case dataFiles = "Data & Reports"
    case presentations = "Presentations"
    case documentation = "Documentation"
    case other = "Other"
    
    var folderName: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .sapDocuments: return "building.2.crop.circle"
        case .hrDocuments: return "person.crop.circle"
        case .implementation: return "hammer.circle"
        case .configuration: return "gearshape.circle"
        case .templates: return "doc.text.image"
        case .training: return "graduationcap.circle"
        case .dataFiles: return "chart.bar.xaxis"
        case .presentations: return "rectangle.on.rectangle"
        case .documentation: return "doc.circle"
        case .other: return "folder.circle"
        }
    }
}
