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
    @AppStorage("language") private var lang = "ru"

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
        if showTime, let time = timeString { parts.append(time) }
        return parts.joined(separator: " · ")
    }

    private var timeString: String? {
        switch battery.status {
        case .onBattery(let mins):
            guard let mins else { return t("Расчёт…", "Calc…") }
            return formatHM(mins, lang: lang)
        case .charging(let mins):
            guard let mins else { return t("Заряжается", "Charging") }
            return formatHM(mins, lang: lang)
        case .chargeLimited:
            return nil
        case .charged:
            return t("Заряжено", "Charged")
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

    private func t(_ ru: String, _ en: String) -> String { lang == "en" ? en : ru }
}

struct BatteryPopover: View {
    @ObservedObject var battery: BatteryMonitor
    @State private var showSettings = false
    @AppStorage("language") private var lang = "ru"

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
                Text(t(
                    "Здоровье батареи: \(health.healthPercentage)% · Циклы: \(health.cycleCount)",
                    "Battery health: \(health.healthPercentage)% · Cycles: \(health.cycleCount)"
                ))
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
        case .onBattery:     return t("На батарее", "On battery")
        case .charging:      return t("Заряжается", "Charging")
        case .chargeLimited: return t("Заряд ограничен (лимит \(battery.percentage)%)",
                                      "Charge limited (\(battery.percentage)%)")
        case .charged:       return t("Заряжена", "Charged")
        }
    }

    private var detailLine: String? {
        switch battery.status {
        case .onBattery(let mins):
            guard let mins else { return t("Расчёт времени…", "Calculating…") }
            return t("\(formatHM(mins, lang: lang)) до разряда",
                     "\(formatHM(mins, lang: lang)) until empty")
        case .charging(let mins):
            guard let mins else { return nil }
            return t("\(formatHM(mins, lang: lang)) до полной зарядки",
                     "\(formatHM(mins, lang: lang)) until full")
        case .chargeLimited, .charged:
            return nil
        }
    }

    private func t(_ ru: String, _ en: String) -> String { lang == "en" ? en : ru }
}

struct SettingsView: View {
    @ObservedObject var battery: BatteryMonitor
    @Binding var showSettings: Bool

    @AppStorage("menuBar.showIcon") private var showIcon = true
    @AppStorage("menuBar.showPercentage") private var showPercentage = true
    @AppStorage("menuBar.showTime") private var showTime = true
    @AppStorage("language") private var lang = "ru"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    showSettings = false
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.left")
                        Text(t("Назад", "Back"))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Spacer()
                Text(t("Настройки", "Settings"))
                    .font(.headline)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                    Text(t("Назад", "Back"))
                }
                .hidden()
            }
            .padding(.bottom, 10)

            Divider()
            VStack(alignment: .leading, spacing: 10) {
                Toggle(t("Иконка", "Icon"), isOn: $showIcon)
                Toggle(t("Процент заряда", "Battery percentage"), isOn: $showPercentage)
                Toggle(t("Время до разряда/заряда", "Time remaining"), isOn: $showTime)
            }
            .padding(.top, 8)

            Divider()
                .padding(.vertical, 8)

            Toggle(t("Запускать при входе", "Launch at login"), isOn: Binding(
                get: { battery.launchAtLoginEnabled },
                set: { battery.setLaunchAtLogin($0) }
            ))

            Divider()
                .padding(.vertical, 8)

            HStack {
                Text(t("Язык", "Language"))
                Spacer()
                Picker("", selection: $lang) {
                    Text("RU").tag("ru")
                    Text("EN").tag("en")
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            Divider()
                .padding(.vertical, 8)

            Button(t("Завершить Cella", "Quit Cella")) { NSApp.terminate(nil) }
                .foregroundStyle(.red)
        }
        .font(.subheadline)
        .padding()
        .frame(minWidth: 220)
    }

    private func t(_ ru: String, _ en: String) -> String { lang == "en" ? en : ru }
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

private func formatHM(_ mins: Int, lang: String) -> String {
    let h = mins / 60
    let m = mins % 60
    if lang == "en" {
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    return h > 0 ? "\(h)ч \(m)м" : "\(m)м"
}
