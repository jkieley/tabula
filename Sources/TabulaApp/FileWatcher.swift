import Foundation

/// Watches one file path, surviving atomic saves (delete/rename + recreate) by re-arming on the path.
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private let onUnavailable: (String) -> Void
    private var source: DispatchSourceFileSystemObject?
    private var retryTimer: Timer?
    private var pending: DispatchWorkItem?

    init(url: URL, onChange: @escaping () -> Void, onUnavailable: @escaping (String) -> Void) {
        self.url = url
        self.onChange = onChange
        self.onUnavailable = onUnavailable
    }

    func start() {
        if !arm() { becomeUnavailable() }
        // Catches edits made between the CLI read and the window opening.
        scheduleChange()
    }

    func stop() {
        source?.cancel()
        source = nil
        retryTimer?.invalidate()
        retryTimer = nil
        pending?.cancel()
        pending = nil
    }

    private func arm() -> Bool {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return false }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .attrib, .delete, .rename],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.handle(source.data) }
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        self.source = source
        return true
    }

    private func handle(_ event: DispatchSource.FileSystemEvent) {
        guard event.contains(.delete) || event.contains(.rename) else {
            scheduleChange()
            return
        }
        source?.cancel()
        source = nil
        // Atomic saves have usually put the new file in place already.
        if arm() {
            scheduleChange()
        } else {
            becomeUnavailable()
        }
    }

    private func becomeUnavailable() {
        onUnavailable("\(url.lastPathComponent) was moved or deleted")
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.arm() else { return }
                self.retryTimer?.invalidate()
                self.retryTimer = nil
                self.scheduleChange()
            }
        }
    }

    private func scheduleChange() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.onChange() }
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150), execute: work)
    }
}
