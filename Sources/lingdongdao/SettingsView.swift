import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: LyricsOverlayState

    var body: some View {
        Form {
            Section("灵动岛显示") {
                Toggle("显示灵动岛", isOn: $state.settings.showIsland)
                Toggle("鼠标停靠自动展开", isOn: $state.settings.expandOnHover)
                Toggle("灵动岛底部歌词", isOn: $state.settings.showBottomLyrics)
                Toggle("显示翻译", isOn: $state.settings.showTranslation)
                Toggle("使用封面主色", isOn: $state.settings.useArtworkColors)
                Toggle("切歌动画", isOn: $state.settings.enableTrackAnimation)
                Toggle("全屏时隐藏", isOn: $state.settings.hideInFullScreen)
                Toggle("简洁动效模式", isOn: $state.settings.reduceMotion)
            }

            Section("歌词布局") {
                Picker("歌词行数", selection: $state.settings.lineMode) {
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

            Section("快捷操作") {
                Button {
                    state.settings.toggleIslandVisibility()
                } label: {
                    Label(
                        state.settings.showIsland ? "隐藏灵动岛" : "显示灵动岛",
                        systemImage: state.settings.showIsland ? "eye.slash" : "eye"
                    )
                }

                Button {
                    state.toggleExpanded()
                } label: {
                    Label(
                        state.isExpanded ? "收起灵动岛" : "展开灵动岛",
                        systemImage: state.isExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical"
                    )
                }

                Button {
                    state.settings.toggleBottomLyrics()
                } label: {
                    Label(
                        state.settings.showBottomLyrics ? "关闭底部歌词" : "打开底部歌词",
                        systemImage: state.settings.showBottomLyrics ? "text.line.last.and.arrowtriangle.forward" : "text.line.first.and.arrowtriangle.forward"
                    )
                }

                Button {
                    state.settings.toggleTranslation()
                } label: {
                    Label(
                        state.settings.showTranslation ? "隐藏翻译" : "显示翻译",
                        systemImage: state.settings.showTranslation ? "character.bubble.fill" : "character.bubble"
                    )
                }
            }

            Section("实时预览") {
                LabeledContent("当前歌曲", value: state.nowPlaying.title)
                LabeledContent("艺术家", value: state.nowPlaying.artist)
                LabeledContent("当前歌词", value: state.activeLine?.text ?? "等待歌词")

                if state.settings.showTranslation, let translation = state.activeLine?.translation {
                    LabeledContent("翻译", value: translation)
                }

                LabeledContent("展示阶段", value: state.phaseTitle)
            }

            Section("说明") {
                Text("本设置页仅控制灵动岛歌词胶囊。播放源（PlaybackSource）、歌词源（LyricsSource）和缓存层（LyricsCache）已拆出正式协议接口，当前运行于 Mock 数据源。后续可接入 Apple Music、Spotify 或自定义来源。")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
