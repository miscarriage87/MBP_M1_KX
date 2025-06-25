# CancellableOperation Bug Report

**Report Date:** 2025-06-24  
**Test Environment:** Swift 6.1.2, macOS arm64  
**Total Failing Tests:** 4 out of 9  
**Total Assertion Failures:** 16  

## Bug Summaries

### CANCEL-001: DocumentManager Race Condition
**Test Method:** `testDocumentManagerCancellation`  
**File:** `Tests/CancellationTests.swift:66`  

**Failing Assertions:**
- Line 79: `XCTAssertTrue(documentManager.isRunning)` ❌
- Line 91: `XCTAssertTrue(documentManager.isCancelled)` ❌

**Root Cause:**  
The `BaseCancellableOperation.startTask()` method uses asynchronous state updates via `await self.setRunningState()`, creating a race condition where tests check `isRunning` before the async state update completes.

**Stack-Level Analysis:**
```
DocumentManager.scanDirectory() → BaseCancellableOperation.startTask() → 
Task.detached { await self.setRunningState() } [ASYNC RACE CONDITION]
```

**Technical Detail:**  
The `setRunningState()` method is called from within a detached task, causing a timing gap between task creation and state visibility to the main thread.

---

### CANCEL-002: IndexingManager State Synchronization
**Test Method:** `testIndexingManagerCancellation`  
**File:** `Tests/CancellationTests.swift:143`  

**Failing Assertions:**
- Line 155: `XCTAssertTrue(indexingManager.isRunning)` ❌

**Root Cause:**  
Identical to CANCEL-001 - the `IndexingManager.indexDocuments()` method inherits the same race condition from `BaseCancellableOperation.startTask()`.

**Stack-Level Analysis:**
```
IndexingManager.indexDocuments() → BaseCancellableOperation.startTask() →
Task.detached { await self.setRunningState() } [ASYNC RACE CONDITION]
```

---

### CANCEL-003: AIManager Dual State Issues  
**Test Method:** `testAIManagerCancellation`  
**File:** `Tests/CancellationTests.swift:195`  

**Failing Assertions:**
- Line 210: `XCTAssertTrue(aiManager.isRunning)` ❌
- Line 222: `XCTAssertFalse(aiManager.isRunning)` ❌

**Root Cause:**  
Compound issue combining the race condition from CANCEL-001/002 plus improper cleanup in the cancellation flow.

**Stack-Level Analysis:**
```
AIManager.analyzeDocuments() → BaseCancellableOperation.startTask() →
[Race condition + cancellation cleanup issues]
```

---

### CANCEL-004: Memory Leak Loop State Persistence
**Test Method:** `testNoCancellableOperationMemoryLeaks`  
**File:** `Tests/CancellationTests.swift:228`  

**Failing Assertions:**  
- Line 242: `XCTAssertTrue(tempManager.isCancelled)` ❌ (Repeated 10 times)

**Root Cause:**  
The cancellation state is not properly persisting across the loop iterations due to improper cleanup in the `cancel()` method and async task completion timing.

**Stack-Level Analysis:**
```
Loop iteration → DocumentManager.cancel() → Task cleanup → 
State reset race condition → Next iteration fails
```

## Code Snippets from `BaseCancellableOperation.swift`
```swift
// Race condition in state management
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
    currentTask = task.mapToVoid()
    return task
}

// Cancellation handling
func cancel() {
    isCancelled = true
    if let task = currentTask {
        task.cancel()
        Task {
            _ = try? await task.value
            await MainActor.run {
                self.currentTask = nil
            }
        }
    }
    isRunning = false
}
```

## Immediate Fix Recommendation
Replace async state updates with synchronous `@MainActor` method calls:
```swift
@MainActor
func startTask<T>(_ operation: @escaping () async throws -> T) -> Task<T, Error> {
    self.isRunning = true
    self.isCancelled = false
    
    let task = Task<T, Error> {
        defer {
            Task { @MainActor in
                self.isRunning = false
            }
        }
        return try await operation()
    }
    currentTask = Task { _ = try await task.value }
    
    return task
}
```

## Technical Analysis

### Core Race Condition Issue
The fundamental problem lies in the `BaseCancellableOperation.startTask()` method at lines 54-69 of `CancellableOperation.swift`. The method creates a detached task that asynchronously updates the `isRunning` state:

```swift
// PROBLEMATIC: Asynchronous state update
let task = Task.detached(priority: .userInitiated) { [weak self] in
    guard let self else { throw CancellationError() }
    await self.setRunningState()  // ← This happens asynchronously!
    // ... rest of operation
}
```

### Timing Diagram
```
Test Thread:           Manager Thread:        Task Thread:
    ↓                      ↓                      ↓
    startTask() ──────────→ createTask() ─────────→ detached task starts
    XCTAssertTrue() ←─────── returns immediately    ↓
    [FAILS] ←─────────────────────────────────────── setRunningState() (async)
```

### Memory Leak Root Cause
The `cancel()` method at lines 32-51 has a nested async cleanup pattern that doesn't guarantee completion:

```swift
// PROBLEMATIC: Nested async cleanup
Task {
    _ = try? await task.value
    await MainActor.run {
        self.currentTask = nil  // ← May not complete before next iteration
    }
}
```

## Immediate Fix Recommendation

### Primary Fix: Synchronous State Updates
Replace the async state initialization with immediate synchronous updates:

```swift
@MainActor
func startTask<T>(_ operation: @escaping () async throws -> T) -> Task<T, Error> {
    // IMMEDIATE state update - no race condition
    self.isRunning = true
    self.isCancelled = false
    
    let task = Task<T, Error> {
        defer {
            Task { @MainActor in
                self.isRunning = false
            }
        }
        return try await operation()
    }
    
    // Keep task reference for cancellation
    currentTask = task.mapToVoid()
    return task
}
```

### Secondary Fix: Simplified Cancellation
Streamline the cancellation logic to avoid nested async patterns:

```swift
@MainActor
func cancel() {
    isCancelled = true
    isRunning = false
    currentTask?.cancel()
    currentTask = nil
}
```

### Alternative Approach: Combine Publishers
For a more robust solution, consider using Combine for state management:

```swift
@MainActor
class BaseCancellableOperation: CancellableOperation {
    @Published var isRunning: Bool = false
    @Published var progress: Double = 0.0
    @Published var isCancelled: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Error>?
    
    func startTask<T>(_ operation: @escaping () async throws -> T) -> Task<T, Error> {
        isRunning = true
        isCancelled = false
        
        let task = Task<T, Error> {
            defer { 
                Task { @MainActor in 
                    self.isRunning = false 
                }
            }
            return try await operation()
        }
        
        currentTask = task.mapToVoid()
        return task
    }
}
```

## Long-Term Refactor Ideas

### Operation Queue Integration
- Implement `OperationQueue` with custom `Operation` subclasses
- Provides built-in cancellation and dependency management
- Better resource management and prioritization

### Combine Publisher Approach
- Use `@Published` properties with `sink` subscribers
- Implement `Cancellable` protocol from Combine
- Leverage `Publishers.Zip` for complex operation coordination

### Actor-Based Concurrency
- Migrate to `actor` types for inherent thread safety
- Eliminate `@MainActor` annotations through proper isolation
- Use `async let` for concurrent operations

### Structured Concurrency Patterns
- Implement `TaskGroup` for batch operations
- Use `withTaskCancellationHandler` for cleanup
- Adopt `AsyncSequence` for progress reporting

## Testing Recommendations

### Immediate Test Fixes
1. Add explicit delays in tests after operation start
2. Use `expectation` with `fulfill()` for async state changes
3. Implement proper cleanup in `tearDown()` methods

### Enhanced Test Coverage
1. Add stress tests for rapid start/cancel cycles
2. Test cancellation during different operation phases
3. Verify memory management with instruments
4. Add performance benchmarks for state transitions

---

**Priority:** Critical  
**Estimated Effort:** 2-4 hours for immediate fixes, 1-2 days for refactoring  
**Risk Level:** Low (fixes are isolated to base class)

*This document should be updated after implementing fixes to track resolution status.*
