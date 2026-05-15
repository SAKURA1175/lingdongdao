import SwiftUI
import AppKit

@main
struct LingdongdaoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("灵动岛", systemImage: "music.note") {
            AppMenuContent(settingsStore: appDelegate.settingsStore)
        }


        Settings {
            SettingsView(state: appDelegate.overlayState)
                .frame(width: 480, height: 580)
        }
    }
}

struct AppMenuContent: View {
    @ObservedObject var settingsStore: OverlaySettingsStore

    var body: some View {
        Toggle("显示灵动岛", isOn: $settingsStore.showIsland)
            .keyboardShortcut("d", modifiers: [.command, .shift])

        Divider()

        Toggle("显示底部歌词", isOn: $settingsStore.showBottomLyrics)
            .keyboardShortcut("b", modifiers: [.command, .shift])

        Toggle("显示翻译", isOn: $settingsStore.showTranslation)
            .keyboardShortcut("t", modifiers: [.command, .shift])

        Divider()

        if #available(macOS 14.0, *) {
            SettingsLink {
                Text("设置...")
            }
            .keyboardShortcut(",", modifiers: .command)
        } else {
            Button("设置...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        Button("退出") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
