import Foundation
import IOKit
import IOKit.ps
import ServiceManagement

enum BatteryStatus {
    case onBattery(minutesToEmpty: Int?)
    case charging(minutesToFull: Int?)
    case chargeLimited
    case charged
}

struct BatterySample {
    let time: Date
    let percent: Int
    let isCharging: Bool
}

struct BatteryHealthInfo {
    let cycleCount: Int
    let healthPercentage: Int
}

final class BatteryMonitor: ObservableObject {
    @Published var percentage: Int = 0
    @Published var status: BatteryStatus = .onBattery(minutesToEmpty: nil)
    @Published var batteryHealth: BatteryHealthInfo? = nil
    @Published var temperature: Double? = nil
    @Published var dischargeRate: Int? = nil
    @Published var history: [BatterySample] = []
    @Published var launchAtLoginEnabled: Bool = SMAppService.mainApp.status == .enabled

    private var runLoopSource: CFRunLoopSource?
    private var statusTimer: Timer?
    private var healthTimer: Timer?

    init() {
        refresh()
        refreshTemperature()
        refreshHealth()
        subscribeToChanges()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refresh()
            self?.refreshTemperature()
        }
        healthTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.refreshHealth()
        }
    }

    deinit {
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .defaultMode)
        }
        statusTimer?.invalidate()
        healthTimer?.invalidate()
    }

    private func subscribeToChanges() {
        let ctx = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        runLoopSource = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            Unmanaged<BatteryMonitor>.fromOpaque(ctx).takeUnretainedValue().refresh()
        }, ctx)?.takeRetainedValue()

        if let src = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), src, .defaultMode)
        }
    }

    private func refreshTemperature() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any],
              let rawTemp = dict["Temperature"] as? Int else { return }

        // Temperature is stored in hundredths of a degree Celsius
        temperature = Double(rawTemp) / 100.0
    }

    func refresh() {
        guard
            let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
            let first = sources.first,
            let desc = IOPSGetPowerSourceDescription(snapshot, first)?.takeUnretainedValue() as? [String: Any]
        else { return }

        let cap = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
        let max = desc[kIOPSMaxCapacityKey] as? Int ?? 100
        percentage = max > 0 ? Int(Double(cap) / Double(max) * 100) : cap

        let isOnAC = (desc[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        let isActuallyCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
        let isCharged = (desc[kIOPSIsChargedKey] as? Bool) ?? false

        let rawEmpty = desc[kIOPSTimeToEmptyKey] as? Int ?? 0
        let rawFull = desc[kIOPSTimeToFullChargeKey] as? Int ?? 0

        if isCharged {
            status = .charged
        } else if isActuallyCharging {
            status = .charging(minutesToFull: rawFull > 0 ? rawFull : nil)
        } else if isOnAC {
            status = .chargeLimited
        } else {
            status = .onBattery(minutesToEmpty: rawEmpty > 0 ? rawEmpty : nil)
        }

        let cutoff = Date.now.addingTimeInterval(-7 * 3600)
        history.append(BatterySample(time: .now, percent: percentage, isCharging: isActuallyCharging))
        history.removeAll { $0.time < cutoff }

        updateDischargeRate()
    }

    private func updateDischargeRate() {
        guard case .onBattery(let mins) = status,
              let mins, mins > 0, percentage > 0 else {
            dischargeRate = nil
            return
        }
        dischargeRate = max(1, Int((Double(percentage) / (Double(mins) / 60.0)).rounded()))
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {}
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    func refreshHealth() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else { return }

        guard let cycleCount = dict["CycleCount"] as? Int else { return }

        let healthPct: Int
        if let batteryData = dict["BatteryData"] as? [String: Any],
           let pct = batteryData["MaxCapacity"] as? Int {
            healthPct = pct
        } else if let design = dict["DesignCapacity"] as? Int,
                  let raw = dict["AppleRawMaxCapacity"] as? Int,
                  design > 0 {
            healthPct = Int((Double(raw) / Double(design) * 100).rounded())
        } else { return }

        batteryHealth = BatteryHealthInfo(cycleCount: cycleCount, healthPercentage: healthPct)
    }
}
