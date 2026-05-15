import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: LyricsOverlayState

    var body: some View {
        Form {
            Section("显示") {
                Toggle("显示灵动岛", isOn: $state.settings.showIsland)
                Toggle("灵动岛底部歌词", isOn: $state.settings.showBottomLyrics)
                Toggle("显示翻译", isOn: $state.settings.showTranslation)
                Toggle("使用封面主色", isOn: $state.settings.useArtworkColors)
                Toggle("切歌动画", isOn: $state.settings.enableTrackAnimation)
                Toggle("全屏时隐藏", isOn: $state.settings.hideInFullScreen)
                Toggle("简洁动效模式", isOn: $state.settings.reduceMotion)
                Toggle("卡拉OK模式 (滚动染色)", isOn: $state.settings.karaokeMode)
                    .help("开启后，歌词会随着播放进度双色填充滚动。")
                
                if state.settings.karaokeMode {
                    Picker("卡拉OK渲染方向", selection: $state.settings.karaokeFillDirection) {
                        ForEach(KaraokeFillDirection.allCases) { direction in
                            Text(direction.label).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section("位置") {
                Picker("垂直位置", selection: $state.settings.verticalAnchor) {
                    ForEach(OverlayVerticalAnchor.allCases) { anchor in
                        Text(anchor.label).tag(anchor)
                    }
                }
                .pickerStyle(.segmented)

                Picker("水平位置", selection: $state.settings.horizontalAnchor) {
                    ForEach(OverlayHorizontalAnchor.allCases) { anchor in
                        Text(anchor.label).tag(anchor)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("布局") {
                Picker("胶囊样式", selection: $state.settings.islandStyle) {
                    ForEach(IslandStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }

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

                LabeledContent("行距") {
                    HStack {
                        Slider(value: $state.settings.lyricLineSpacing, in: 0...12, step: 1)
                            .frame(width: 180)
                        Text("\(Int(state.settings.lyricLineSpacing))")
                            .monospacedDigit()
                            .frame(width: 24, alignment: .trailing)
                    }
                }

                Picker("字体颜色", selection: $state.settings.lyricColorStyle) {
                    ForEach(LyricsColorStyle.allCases) { style in
                        Text(style.label).tag(style)
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
