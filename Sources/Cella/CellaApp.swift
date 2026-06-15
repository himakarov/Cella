import SwiftUI

@main
struct CellaApp: App {
    @StateObject private var battery = BatteryMonitor()

    var body: some Scene {
        MenuBarExtra(content: {
            BatteryPopover(battery: battery)
        }, label: {
            MenuBarLabel(battery: battery)
        })
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    @ObservedObject var battery: BatteryMonitor

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
            Text(title)
        }
    }

    private var title: String {
        let pct = "\(battery.percentage)%"
        switch battery.status {
        case .onBattery(let mins):
            guard let mins else { return "\(pct) · Расчёт времени…" }
            return "\(pct) · \(formatHM(mins))"
        case .charging(let mins):
            guard let mins else { return "\(pct) · Заряжается" }
            return "\(pct) · \(formatHM(mins))"
        case .chargeLimited:
            return pct
        case .charged:
            return "\(pct) · Заряжено"
        }
    }

    private var iconName: String {
        switch battery.status {
        case .charging:
            return chargingBatteryIcon(for: battery.percentage)
        default:
            return batteryIcon(for: battery.percentage)
        }
    }

    private var iconColor: Color {
        switch battery.status {
        case .onBattery:
            return battery.percentage <= 20 ? .red : .primary
        case .charging, .chargeLimited, .charged:
            return .green
        }
    }
}

struct BatteryPopover: View {
    @ObservedObject var battery: BatteryMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: popoverIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(popoverIconColor)
                Text("\(battery.percentage)%")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
            }
            Divider()
            Text(statusLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let detail = detailLine {
                Text(detail)
                    .font(.subheadline)
            }
            if let health = battery.batteryHealth {
                Divider()
                Text("Здоровье батареи: \(health.healthPercentage)% · Циклы: \(health.cycleCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            Toggle("Запускать при входе", isOn: Binding(
                get: { battery.launchAtLoginEnabled },
                set: { battery.setLaunchAtLogin($0) }
            ))
            .font(.subheadline)
            Divider()
            Button("Завершить Cella") { NSApp.terminate(nil) }
                .font(.subheadline)
        }
        .padding()
        .frame(minWidth: 220)
    }

    private var popoverIcon: String {
        switch battery.status {
        case .charging: return chargingBatteryIcon(for: battery.percentage)
        default:        return batteryIcon(for: battery.percentage)
        }
    }

    private var popoverIconColor: Color {
        switch battery.status {
        case .onBattery:
            return battery.percentage <= 20 ? .red : .primary
        case .charging, .chargeLimited, .charged:
            return .green
        }
    }

    private var statusLine: String {
        switch battery.status {
        case .onBattery:     return "На батарее"
        case .charging:      return "Заряжается"
        case .chargeLimited: return "Заряд ограничен (лимит \(battery.percentage)%)"
        case .charged:       return "Заряжена"
        }
    }

    private var detailLine: String? {
        switch battery.status {
        case .onBattery(let mins):
            guard let mins else { return "Расчёт времени…" }
            return "\(formatHM(mins)) до разряда"
        case .charging(let mins):
            guard let mins else { return nil }
            return "\(formatHM(mins)) до полной зарядки"
        case .chargeLimited, .charged:
            return nil
        }
    }
}

private func batteryIcon(for percentage: Int) -> String {
    switch percentage {
    case 76...: return "battery.100"
    case 51...: return "battery.75"
    case 26...: return "battery.50"
    case 11...: return "battery.25"
    default:    return "battery.0"
    }
}

private func chargingBatteryIcon(for percentage: Int) -> String {
    switch percentage {
    case 76...: return "battery.100.bolt"
    case 51...: return "battery.75.bolt"
    case 26...: return "battery.50.bolt"
    case 11...: return "battery.25.bolt"
    default:    return "battery.0.bolt"
    }
}

private func formatHM(_ mins: Int) -> String {
    let h = mins / 60
    let m = mins % 60
    return h > 0 ? "\(h)ч \(m)м" : "\(m)м"
}
