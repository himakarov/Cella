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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if showSettings {
                SettingsView(battery: battery, showSettings: $showSettings)
            } else {
                batteryView
            }
        }
        .onDisappear { showSettings = false }
    }

    private var batteryView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 13) {
                    BatteryIconView(percentage: battery.percentage, isCharging: isCharging)
                    Text("\(battery.percentage)%")
                        .font(.system(size: 34, weight: .bold))
                        .tracking(-1)
                }
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.45))
                }
                .buttonStyle(.plain)
            }

            customDivider

            VStack(alignment: .leading, spacing: 0) {
                Text(t("СТАТУС", "STATUS"))
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 7)

                HStack(spacing: 6) {
                    if isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(chargeAccentColor)
                    }
                    Text(statusLine)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isCharging ? chargeAccentColor : .primary)
                }
                .padding(.bottom, 3)

                if let detail = detailLine {
                    Text(detail)
                        .font(.system(size: 15))
                }
            }

            if battery.batteryHealth != nil || battery.temperature != nil {
                customDivider
                HStack(alignment: .top, spacing: 8) {
                    if let health = battery.batteryHealth {
                        statCell(value: "\(health.healthPercentage)%", label: t("Здоровье", "Health"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        statCell(value: "\(health.cycleCount)", label: t("Циклы", "Cycles"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let temp = battery.temperature {
                        statCell(value: String(format: "%.1f°", temp), label: t("Темп.", "Temp."))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(width: 300)
    }

    @ViewBuilder
    private func statCell(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .semibold))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var isCharging: Bool {
        if case .charging = battery.status { return true }
        return false
    }

    private var chargeAccentColor: Color {
        colorScheme == .dark
            ? Color(red: 0.196, green: 0.843, blue: 0.294)
            : Color(red: 0.157, green: 0.655, blue: 0.271)
    }

    private var customDivider: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.10))
            .frame(height: 0.5)
            .padding(.vertical, 14)
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

struct BatteryIconView: View {
    let percentage: Int
    let isCharging: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var borderColor: Color {
        colorScheme == .dark ? .white.opacity(0.85) : .black.opacity(0.55)
    }

    private var fillColor: Color {
        colorScheme == .dark
            ? Color(red: 0.196, green: 0.843, blue: 0.294)
            : Color(red: 0.204, green: 0.78, blue: 0.349)
    }

    var body: some View {
        HStack(spacing: 1) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: 2)
                GeometryReader { geo in
                    let pad: CGFloat = 4.5
                    let fillW = max(0, (geo.size.width - pad * 2) * CGFloat(percentage) / 100)
                    let fillH = geo.size.height - pad * 2
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(fillColor)
                            .frame(width: fillW, height: fillH)
                        Spacer(minLength: 0)
                    }
                    .padding(pad)
                }
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 46, height: 23)
            RoundedRectangle(cornerRadius: 2)
                .fill(borderColor)
                .frame(width: 2.5, height: 8)
        }
    }
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

            HStack {
                Spacer()
                VStack(spacing: 3) {
                    Text("Cella \(appVersion)")
                        .fontWeight(.medium)
                    Text("by himakarov")
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                Spacer()
            }

            Divider()
                .padding(.vertical, 8)

            Button(t("Завершить Cella", "Quit Cella")) { NSApp.terminate(nil) }
                .foregroundStyle(.red)
        }
        .font(.body)
        .padding()
        .frame(minWidth: 220)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
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
