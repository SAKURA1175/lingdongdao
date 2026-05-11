import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: LyricsOverlayState

    var body: some View {
        Form {
            Section("显示") {
                Toggle("显示灵动岛", isOn: $state.settings.showIsland)
                Toggle("鼠标停靠自动展开", isOn: $state.settings.expandOnHover)
                Toggle("灵动岛底部歌词", isOn: $state.settings.showBottomLyrics)
                Toggle("显示翻译", isOn: $state.settings.showTranslation)
                Toggle("使用封面主色", isOn: $state.settings.useArtworkColors)
                Toggle("切歌动画", isOn: $state.settings.enableTrackAnimation)
                Toggle("全屏时隐藏", isOn: $state.settings.hideInFullScreen)
                Toggle("简洁动效模式", isOn: $state.settings.reduceMotion)
            }

            Section("布局") {
                Picker("歌词布局", selection: $state.settings.lineMode) {
                    ForEach(LyricsLineMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }

                Picker("宽度模式", selection: $state.settings.widthMode) {
                    ForEach(OverlayWidthMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }

                Picker("歌词对齐", selection: $state.settings.lyricsAlignment) {
                    ForEach(LyricsTextAlignmentOption.allCases) { alignment in
                        Text(alignment.label).tag(alignment)
                    }
                }
            }

            Section("实时预览") {
                LabeledContent("当前歌曲", value: state.nowPlaying.title)
                LabeledContent("艺术家", value: state.nowPlaying.artist)
                LabeledContent("当前歌词", value: state.activeLine?.text ?? "等待歌词")

                if state.settings.showTranslation, let translation = state.activeLine?.translation {
                    LabeledContent("翻译", value: translation)
                }
            }

            Section("说明") {
                Text("本轮只做灵动岛主线。播放源、歌词源和缓存层已经拆出正式接口，后续可以继续接 Apple Music 或其他来源。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
