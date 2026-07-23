import Foundation
import TransmissionRPC

// MARK: - PollingCoordinator

@MainActor
final class PollingCoordinator {
    private var pollingTask: Task<Void, Never>?
    private var freeSpaceTask: Task<Void, Never>?

    weak var service: AppService?

    init(service: AppService? = nil) {
        self.service = service
    }

    func startPolling(interval: Duration = .seconds(2)) {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.service?.refresh()
                guard !Task.isCancelled else { break }
                try? await Task.sleep(for: interval)
            }
        }

        // Free-space poll every 30s
        freeSpaceTask?.cancel()
        freeSpaceTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.service?.refreshFreeSpace()
                guard !Task.isCancelled else { break }
                try? await Task.sleep(for: .seconds(30))
            }
        }
        // Port sync fires in refresh() on first successful connection.
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        freeSpaceTask?.cancel()
        freeSpaceTask = nil
    }
}
