import Foundation
import Combine

@MainActor
public final class NetworkGuardManager: ObservableObject {
    public static let shared = NetworkGuardManager()

    @Published public private(set) var currentDownloadSpeedKB: Double = 0
    @Published public private(set) var currentUploadSpeedKB: Double = 0
    @Published public private(set) var formattedDownloadSpeed: String = "0 KB/s"
    @Published public private(set) var isGuardActive: Bool = false
    @Published public private(set) var triggeredByNetwork: Bool = false
    @Published public private(set) var graceRemainingSeconds: Double = 0

    private var monitorTimer: Timer?
    private var lastRxBytes: UInt64 = 0
    private var lastTxBytes: UInt64 = 0
    private var lastSampleDate: Date?

    private init() {
        if UserDefaults.standard.bool(forKey: "isNetworkGuardEnabled") {
            startMonitoring()
        }
    }

    public func startMonitoring() {
        stopMonitoring()
        let (rx, tx) = fetchNetworkBytes()
        lastRxBytes = rx
        lastTxBytes = tx
        lastSampleDate = Date()

        monitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sampleNetworkThroughput()
            }
        }
        RunLoop.current.add(monitorTimer!, forMode: .common)
    }

    public func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        currentDownloadSpeedKB = 0
        currentUploadSpeedKB = 0
        formattedDownloadSpeed = "0 KB/s"
        isGuardActive = false
    }

    public func toggleGuardEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "isNetworkGuardEnabled")
        if enabled {
            startMonitoring()
        } else {
            if triggeredByNetwork && AppState.shared.status.isRunning {
                AppState.shared.stopSession(reason: "Network guard disabled")
            }
            triggeredByNetwork = false
            stopMonitoring()
        }
    }

    private func sampleNetworkThroughput() {
        guard let lastDate = lastSampleDate else {
            lastSampleDate = Date()
            return
        }

        let now = Date()
        let interval = now.timeIntervalSince(lastDate)
        guard interval > 0.5 else { return }

        let (rx, tx) = fetchNetworkBytes()
        lastSampleDate = now

        let rxDelta = rx >= lastRxBytes ? Double(rx - lastRxBytes) : 0
        let txDelta = tx >= lastTxBytes ? Double(tx - lastTxBytes) : 0

        lastRxBytes = rx
        lastTxBytes = tx

        let rxSpeedKB = (rxDelta / interval) / 1024.0
        let txSpeedKB = (txDelta / interval) / 1024.0

        self.currentDownloadSpeedKB = rxSpeedKB
        self.currentUploadSpeedKB = txSpeedKB
        self.formattedDownloadSpeed = formatSpeed(rxSpeedKB)

        evaluateThroughputThreshold(rxSpeedKB: rxSpeedKB)
    }

    private func evaluateThroughputThreshold(rxSpeedKB: Double) {
        let thresholdKB = UserDefaults.standard.object(forKey: "networkSpeedThresholdKB") as? Double ?? 1024.0
        let graceTotal = UserDefaults.standard.object(forKey: "networkGracePeriodSeconds") as? Double ?? 20.0

        if rxSpeedKB >= thresholdKB {
            isGuardActive = true
            graceRemainingSeconds = graceTotal

            if !AppState.shared.status.isRunning {
                triggeredByNetwork = true
                AppState.shared.selectedMode = .unlimited
                AppState.shared.startSession()

                NotificationManager.shared.sendNotification(
                    title: "Download Guard Active",
                    body: "Awake engaged: Active download at \(formattedDownloadSpeed).",
                    identifier: "network-guard-start"
                )
            }
        } else {
            if triggeredByNetwork && isGuardActive {
                if graceRemainingSeconds > 0 {
                    graceRemainingSeconds -= 2.0
                } else {
                    isGuardActive = false
                    triggeredByNetwork = false
                    if AppState.shared.status.isRunning {
                        AppState.shared.stopSession(reason: "Download completed")
                        NotificationManager.shared.sendNotification(
                            title: "Download Finished",
                            body: "Network throughput returned to idle. System power defaults restored.",
                            identifier: "network-guard-stop"
                        )
                    }
                }
            } else {
                isGuardActive = false
            }
        }
    }

    private func formatSpeed(_ kbps: Double) -> String {
        if kbps >= 1024.0 {
            return String(format: "%.1f MB/s", kbps / 1024.0)
        } else {
            return String(format: "%.0f KB/s", kbps)
        }
    }

    private func fetchNetworkBytes() -> (rx: UInt64, tx: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }

        var rx: UInt64 = 0
        var tx: UInt64 = 0

        var ptr = Optional(firstAddr)
        while let addr = ptr {
            let flags = Int32(addr.pointee.ifa_flags)
            let family = addr.pointee.ifa_addr.pointee.sa_family

            if family == UInt8(AF_LINK) && (flags & IFF_LOOPBACK) == 0 && (flags & IFF_UP) != 0 {
                if let data = addr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    rx += UInt64(networkData.ifi_ibytes)
                    tx += UInt64(networkData.ifi_obytes)
                }
            }
            ptr = addr.pointee.ifa_next
        }
        return (rx, tx)
    }

    public func resetTriggerFlag() {
        triggeredByNetwork = false
        isGuardActive = false
    }
}
