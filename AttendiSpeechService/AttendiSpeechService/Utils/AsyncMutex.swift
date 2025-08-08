import Foundation

/// An `actor` that provides mutual exclusion for asynchronous tasks.
///
/// `AsyncMutex` ensures that only one task can access a critical section of code at a time.
/// Tasks that attempt to acquire the lock while it is already held will be suspended until the lock becomes available.
///
/// Note: AsyncMutex is created as it is not part of the Swift standard libraries prior to iOS 18 min SDK target.
/// When migrating to min target SDK iOS 18, this actor can be removed and `Mutex` from the `Synchronization` framework can be used instead.
actor AsyncMutex {

    /// Indicates whether the mutex is currently locked.
    private var isLocked = false

    /// Queue of continuations representing tasks waiting for the lock to be released.
    private var waitQueue: [CheckedContinuation<Void, Never>] = []

    /// Acquires the lock asynchronously.
    ///
    /// If the lock is not held, this method acquires it immediately.
    /// Otherwise, the current task is suspended until the lock becomes available.
    func lock() async {
        if !isLocked {
            isLocked = true
        } else {
            await withCheckedContinuation { continuation in
                waitQueue.append(continuation)
            }
        }
    }

    /// Releases the lock.
    ///
    /// If there are tasks waiting for the lock, the first one in the queue is resumed.
    /// Otherwise, the lock is simply marked as available.
    func unlock() {
        if let next = waitQueue.first {
            waitQueue.removeFirst()
            next.resume()
        } else {
            isLocked = false
        }
    }

    /// Executes a block of code with the lock held.
    ///
    /// This is a convenience method that automatically acquires the lock,
    /// executes the given async block, and then releases the lock when the block completes,
    /// even if the block throws an error.
    ///
    /// - Parameter block: An asynchronous block of code to execute while holding the lock.
    /// - Returns: The result returned by the block.
    /// - Throws: Rethrows any error thrown by the block.
    func withLock<T>(
        _ block: () async throws -> T
    ) async rethrows -> T {
        await lock()
        defer {
            unlock()
        }
        return try await block()
    }
}
