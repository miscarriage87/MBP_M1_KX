import XCTest
import Foundation
import Combine
@testable import DocumentOrganizerApp

// MARK: - XCTestCase Extension for Synchronization Helpers
extension XCTestCase {
    /// Generic helper to wait for a condition to be met
    func waitForTruth(
        timeout: TimeInterval,
        description: String,
        _ condition: @escaping () async -> Bool
    ) async {
        let start = Date()
        while !(await condition()) {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail(description)
                return
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    /// Waits until the specified CancellableOperation starts running
    func waitUntilRunning(_ op: any CancellableOperation, timeout: TimeInterval = 1.0) async {
        await waitForTruth(timeout: timeout, description: "Wait for operation to start running timed out") {
            await op.isRunning
        }
    }

    /// Waits until the specified CancellableOperation is cancelled and stops running
    func waitUntilCancelled(_ op: any CancellableOperation, timeout: TimeInterval = 1.0) async {
        await waitForTruth(timeout: timeout, description: "Wait for operation to be cancelled timed out") {
            let isCancelled = await op.isCancelled
            let isRunning = await op.isRunning
            return isCancelled && !isRunning
        }
    }
}

final class CancellationTests: XCTestCase {
    
    var documentManager: DocumentManager!
    var indexingManager: IndexingManager!
    var aiManager: AIManager!
    
    override func setUp() async throws {
        documentManager = await DocumentManager(processingDelay: 0.001)
        indexingManager = await IndexingManager(processingDelay: 0.001)
        aiManager = await AIManager(processingDelay: 0.001)
    }
    
    override func tearDown() async throws {
        // Cancel any running operations to clean up
        await documentManager.cancel()
        await indexingManager.cancel()
        await aiManager.cancel()
        
        documentManager = nil
        indexingManager = nil
        aiManager = nil
    }
    
    // MARK: - DocumentManager Tests
    
    func testDocumentManagerCancellation() async throws {
        // Given: A mock directory with test files
        let tempDir = createTemporaryDirectory()
        createMockFiles(in: tempDir)
        
        // When: Start scanning and wait for it to start
        await documentManager.scanDirectory(tempDir)
        
        // Wait for operation to start running
        await waitUntilRunning(documentManager)
        
        // Verify operation started
        await Task { @MainActor in
            XCTAssertTrue(documentManager.isRunning)
            XCTAssertFalse(documentManager.isCancelled)
        }.value
        
        // Cancel the operation
        await documentManager.cancel()
        
        // Wait for operation to be cancelled
        await waitUntilCancelled(documentManager)
        
        // Then: Operation should be cancelled
        await Task { @MainActor in
            XCTAssertTrue(documentManager.isCancelled)
            XCTAssertFalse(documentManager.isRunning)
        }.value
        
        cleanupTemporaryDirectory(tempDir)
    }
    
    func testDocumentManagerCancellationDuringScanning() async throws {
        let tempDir = createTemporaryDirectory()
        createManyMockFiles(in: tempDir, count: 1000) // Create many files to ensure cancellation during scanning
        
        // Start scanning
        await documentManager.scanDirectory(tempDir)
        
        // Wait for scanning to start
        await waitUntilRunning(documentManager)
        
        // Cancel during scanning
        await documentManager.cancel()
        
        // Wait for cancellation to complete
        await waitUntilCancelled(documentManager)
        
        // Should remain cancelled and not running
        await Task { @MainActor in
            XCTAssertTrue(documentManager.isCancelled)
            XCTAssertFalse(documentManager.isRunning)
        }.value
        
        cleanupTemporaryDirectory(tempDir)
    }
    
    func testDocumentManagerReset() async throws {
        // Given: A cancelled operation
        await documentManager.cancel()
        await Task { @MainActor in
            XCTAssertTrue(documentManager.isCancelled)
        }.value
        
        // When: Reset is called
        await documentManager.reset()
        
        // Then: State should be reset
        await Task { @MainActor in
            XCTAssertFalse(documentManager.isCancelled)
            XCTAssertFalse(documentManager.isRunning)
            XCTAssertEqual(documentManager.progress, 0.0)
        }.value
    }
    
    // MARK: - IndexingManager Tests
    
    func testIndexingManagerCancellation() async throws {
        // Create mock documents
        let mockDocuments = createMockDocumentItems(count: 100)
        
        // Start indexing
        await indexingManager.indexDocuments(mockDocuments)
        
        // Wait for operation to start running
        await waitUntilRunning(indexingManager)
        
        // Verify operation started
        await Task { @MainActor in
            XCTAssertTrue(indexingManager.isRunning)
        }.value
        
        // Cancel the operation
        await indexingManager.cancel()
        
        // Wait for cancellation to complete
        await waitUntilCancelled(indexingManager)
        
        // Verify cancellation
        await Task { @MainActor in
            XCTAssertTrue(indexingManager.isCancelled)
            XCTAssertFalse(indexingManager.isRunning)
        }.value
    }
    
    func testIndexingManagerCancellationDuringProcessing() async throws {
        let mockDocuments = createMockDocumentItems(count: 500)
        
        // Start indexing
        await indexingManager.indexDocuments(mockDocuments)
        
        // Wait for processing to start
        await waitUntilRunning(indexingManager)
        
        // Cancel during processing
        await indexingManager.cancel()
        
        // Wait for cancellation to complete
        await waitUntilCancelled(indexingManager)
        
        // Verify cancellation
        await Task { @MainActor in
            XCTAssertTrue(indexingManager.isCancelled)
            XCTAssertFalse(indexingManager.isRunning)
        }.value
    }
    
    // MARK: - AIManager Tests
    
    func testAIManagerCancellation() async throws {
        // Set up a mock API key
        await aiManager.saveAPIKey("test-key-for-cancellation-test")
        
        let mockDocuments = createMockDocumentItems(count: 10)
        let mockIndexedContent = createMockIndexedContent(for: mockDocuments)
        
        // Start analysis
        await aiManager.analyzeDocuments(mockDocuments, indexedContent: mockIndexedContent)
        
        // Wait for operation to start running
        await waitUntilRunning(aiManager)
        
        // Verify operation started
        await Task { @MainActor in
            XCTAssertTrue(aiManager.isRunning)
        }.value
        
        // Cancel immediately
        await aiManager.cancel()
        
        // Wait for cancellation to complete
        await waitUntilCancelled(aiManager)
        
        // Verify cancellation
        await Task { @MainActor in
            XCTAssertTrue(aiManager.isCancelled)
            XCTAssertFalse(aiManager.isRunning)
        }.value
    }
    
    // MARK: - Memory Leak Tests
    
    func testNoCancellableOperationMemoryLeaks() async throws {
        // Create and cancel multiple operations to test for memory leaks
        for _ in 0..<10 {
            let tempManager = await DocumentManager(processingDelay: 0.001)
            let tempDir = createTemporaryDirectory()
            createMockFiles(in: tempDir)
            
            await tempManager.scanDirectory(tempDir)
            await waitUntilRunning(tempManager)
            await tempManager.cancel()
            await waitUntilCancelled(tempManager)
            
            // Verify clean state
            await Task { @MainActor in
                XCTAssertTrue(tempManager.isCancelled)
                XCTAssertFalse(tempManager.isRunning)
            }.value
            
            cleanupTemporaryDirectory(tempDir)
        }
    }
    
    func testProgressUpdatesStopAfterCancellation() async throws {
        let tempDir = createTemporaryDirectory()
        createManyMockFiles(in: tempDir, count: 100)
        
        // Start scanning
        await documentManager.scanDirectory(tempDir)
        
        // Wait for operation to start and record initial progress
        await waitUntilRunning(documentManager)
        let progressBeforeCancellation = await documentManager.progress
        
        // Cancel
        await documentManager.cancel()
        
        // Wait for cancellation to complete
        await waitUntilCancelled(documentManager)
        let progressAfterCancellation = await documentManager.progress
        
        // Progress should not have increased after cancellation
        XCTAssertLessThanOrEqual(progressAfterCancellation, progressBeforeCancellation)
        
        cleanupTemporaryDirectory(tempDir)
    }
    
    // MARK: - Concurrent Cancellation Tests
    
    func testConcurrentOperationsCancellation() async throws {
        let tempDir = createTemporaryDirectory()
        createMockFiles(in: tempDir)
        let mockDocuments = createMockDocumentItems(count: 50)
        let mockIndexedContent = createMockIndexedContent(for: mockDocuments)
        
        // Start all operations concurrently
        await documentManager.scanDirectory(tempDir)
        await indexingManager.indexDocuments(mockDocuments)
        await aiManager.saveAPIKey("test-key")
        await aiManager.analyzeDocuments(mockDocuments, indexedContent: mockIndexedContent)
        
        // Wait for all operations to start
        await waitUntilRunning(documentManager)
        await waitUntilRunning(indexingManager)
        await waitUntilRunning(aiManager)
        
        // Cancel all operations
        await documentManager.cancel()
        await indexingManager.cancel()
        await aiManager.cancel()
        
        // Wait for all operations to be cancelled
        await waitUntilCancelled(documentManager)
        await waitUntilCancelled(indexingManager)
        await waitUntilCancelled(aiManager)
        
        // Verify all are cancelled and not running
        await Task { @MainActor in
            XCTAssertTrue(documentManager.isCancelled)
            XCTAssertTrue(indexingManager.isCancelled)
            XCTAssertTrue(aiManager.isCancelled)
            XCTAssertFalse(documentManager.isRunning)
            XCTAssertFalse(indexingManager.isRunning)
            XCTAssertFalse(aiManager.isRunning)
        }.value
        
        cleanupTemporaryDirectory(tempDir)
    }
    
    // MARK: - Helper Methods
    
    private func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }
    
    private func cleanupTemporaryDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    private func createMockFiles(in directory: URL) {
        let fileTypes = ["pdf", "docx", "xlsx", "pptx", "txt"]
        
        for i in 0..<10 {
            for fileType in fileTypes {
                let fileURL = directory.appendingPathComponent("test_file_\(i).\(fileType)")
                try! "Mock file content for testing".write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func createManyMockFiles(in directory: URL, count: Int) {
        let fileTypes = ["pdf", "docx", "xlsx", "pptx", "txt"]
        
        for i in 0..<count {
            let fileType = fileTypes[i % fileTypes.count]
            let fileURL = directory.appendingPathComponent("test_file_\(i).\(fileType)")
            try! "Mock file content for testing cancellation".write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    private func createMockDocumentItems(count: Int) -> [DocumentItem] {
        var documents: [DocumentItem] = []
        
        for i in 0..<count {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("mock_doc_\(i).pdf")
            let document = DocumentItem(
                url: tempURL,
                name: "Mock Document \(i)",
                size: 1024 * (i + 1),
                modificationDate: Date(),
                type: "pdf",
                category: .documentation
            )
            documents.append(document)
        }
        
        return documents
    }
    
    private func createMockIndexedContent(for documents: [DocumentItem]) -> [String: IndexingManager.DocumentIndex] {
        var indexedContent: [String: IndexingManager.DocumentIndex] = [:]
        
        for document in documents {
            let metadata = IndexingManager.DocumentMetadata(
                author: "Test Author",
                creationDate: Date(),
                modificationDate: document.modificationDate,
                pageCount: 10,
                wordCount: 500,
                language: "en",
                size: Int64(document.size)
            )
            
            let index = IndexingManager.DocumentIndex(
                id: document.url.absoluteString,
                url: document.url,
                title: document.name,
                content: "Mock content for \(document.name)",
                keywords: ["test", "mock", "document"],
                category: document.category,
                metadata: metadata,
                extractedText: "Mock extracted text",
                summary: "Mock summary for testing"
            )
            
            indexedContent[document.url.absoluteString] = index
        }
        
        return indexedContent
    }
}
