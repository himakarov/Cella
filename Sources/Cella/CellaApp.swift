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
    @AppStorage("menuBar.showIcon") private var showIcon = true
    @AppStorage("menuBar.showPercentage") private var showPercentage = true
    @AppStorage("menuBar.showTime") private var showTime = true

    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
            }
            let text = labelText
            if !text.isEmpty {
                Text(text)
            }
        }
    }

    private var labelText: String {
        var parts: [String] = []
        if showPercentage { parts.append("\(battery.percentage)%") }
        if showTime, let t = timeString { parts.append(t) }
        return parts.joined(separator: " · ")
    }

    private var timeString: String? {
        switch battery.status {
        case .onBattery(let mins):
            guard let mins else { return "Расчёт…" }
            return formatHM(mins)
        case .charging(let mins):
            guard let mins else { return "Заряжается" }
            return formatHM(mins)
        case .chargeLimited:
            return nil
        case .charged:
            return "Заряжено"
        }
    }

    private var iconName: String {
        switch battery.status {
        case .charging: return chargingBatteryIcon(for: battery.percentage)
        default:        return batteryIcon(for: battery.percentage)
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
    @State private var showSettings = false

    var body: some View {
        if showSettings {
            SettingsView(battery: battery, showSettings: $showSettings)
        } else {
            batteryView
        }
    }

    private var batteryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Image(systemName: popoverIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(popoverIconColor)
                Text("\(battery.percentage)%")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
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

struct SettingsView: View {
    @ObservedObject var battery: BatteryMonitor
    @Binding var showSettings: Bool

    @AppStorage("menuBar.showIcon") private var showIcon = true
    @AppStorage("menuBar.showPercentage") private var showPercentage = true
    @AppStorage("menuBar.showTime") private var showTime = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    showSettings = false
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("Настройки")
                    .font(.headline)
                Spacer()
                // balance spacer so title is centered
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                    Text("Назад")
                }
                .hidden()
            }
            .padding(.bottom, 10)

            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Иконка", isOn: $showIcon)
                Toggle("Процент заряда", isOn: $showPercentage)
                Toggle("Время до разряда/заряда", isOn: $showTime)
            }
            .padding(.top, 8)

            Divider()
                .padding(.vertical, 8)

            Toggle("Запускать при входе", isOn: Binding(
                get: { battery.launchAtLoginEnabled },
                set: { battery.setLaunchAtLogin($0) }
            ))

            Divider()
                .padding(.vertical, 8)

            Button("Завершить Cella") { NSApp.terminate(nil) }
                .foregroundStyle(.red)
        }
        .font(.subheadline)
        .padding()
        .frame(minWidth: 220)
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
