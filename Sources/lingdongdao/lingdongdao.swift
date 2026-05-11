import SwiftUI

@main
struct LingdongdaoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(state: appDelegate.overlayState)
                .frame(width: 460, height: 540)
        }
        .commands {
            CommandMenu("灵动岛") {
                Button(appDelegate.settingsStore.showIsland ? "隐藏灵动岛" : "显示灵动岛") {
                    appDelegate.settingsStore.toggleIslandVisibility()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Button(appDelegate.overlayState.isExpanded ? "收起灵动岛" : "展开灵动岛") {
                    appDelegate.overlayState.toggleExpanded()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()

                Button(appDelegate.settingsStore.showBottomLyrics ? "隐藏底部歌词" : "显示底部歌词") {
                    appDelegate.settingsStore.toggleBottomLyrics()
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])

                Button(appDelegate.settingsStore.showTranslation ? "隐藏翻译" : "显示翻译") {
                    appDelegate.settingsStore.toggleTranslation()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
        }
    }
}
