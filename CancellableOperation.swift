import Foundation
import SwiftUI

/// A protocol that defines the interface for cancellable operations
/// Provides UI-friendly properties to query operation state and control cancellation
protocol CancellableOperation: ObservableObject {
    /// Indicates if the operation is currently running
    var isRunning: Bool { get }
    
    /// Progress of the operation (0.0 to 1.0)
    var progress: Double { get }
    
    /// Indicates if the operation has been cancelled
    var isCancelled: Bool { get }
    
    /// Cancels the running operation
    func cancel()
}

/// A base class that provides common cancellation infrastructure
@MainActor class BaseCancellableOperation: CancellableOperation {
    @Published var isRunning: Bool = false
    @Published var progress: Double = 0.0
    @Published var isCancelled: Bool = false
    
    private var currentTask: Task<Void, Error>?
    
    init() {
        // Default initializer for base class
    }
    
    func cancel() {
        // Set isCancelled BEFORE calling currentTask?.cancel() to avoid late observers
        isCancelled = true
        
        // Cancel the current task if it exists
        if let task = currentTask {
            task.cancel()
            
            // Wait for the task to complete to ensure proper cleanup
            Task {
                _ = try? await task.value
                // Nil out the reference so ARC can release it
                await MainActor.run {
                    self.currentTask = nil
                }
            }
        }
        
        isRunning = false
    }
    
    /// Starts a cancellable task and tracks it
    func startTask<T>(_ operation: @escaping () async throws -> T) -> Task<T, Error> {
        let task = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { throw CancellationError() }
            await self.setRunningState()
            do {
                let result = try await operation()
                await self.setStoppedState()
                return result
            } catch {
                await self.setStoppedState()
                throw error
            }
        }
        currentTask = task.mapToVoid()         // small helper to keep reference
        return task
    }
    
    /// Sets the running state - called from detached task
    private func setRunningState() {
        isRunning = true
        isCancelled = false
    }
    
    /// Sets the stopped state - called from detached task
    private func setStoppedState() {
        isRunning = false
    }
    
    /// Checks if the current task should be cancelled and throws if so
    func checkCancellation() async throws {
        if isCancelled {
            throw CancellationError()
        }
        try Task.checkCancellation()
    }
    
    /// Updates progress on the main thread
    func updateProgress(_ newProgress: Double) {
        progress = newProgress
    }
    
    /// Resets the operation state
    func reset() {
        isRunning = false
        progress = 0.0
        isCancelled = false
        currentTask = nil
    }
    
    /// Deinitializer ensures proper cleanup
    deinit {
        // Can't call async method from deinit, just cancel the task
        currentTask?.cancel()
    }
}

// MARK: - Task Extensions
extension Task {
    /// Maps a Task<T, Error> to Task<Void, Error> to keep a reference without the value
    func mapToVoid() -> Task<Void, Error> {
        return Task<Void, Error> {
            _ = try await self.value
        }
    }
}
