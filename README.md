# 灵动岛歌词胶囊 (LingdongDao)

macOS 顶部常驻歌词胶囊工具，灵动岛优先。

## 产品形态

### 收起态 — 歌词胶囊
- 歌词为视觉中心
- Album badge 和 Mini Visualizer 仅做弱辅助
- 底部歌词支持渐隐截断（非硬截断）
- 支持单行/双行歌词 + 翻译副行

### 展开态 — 歌词沉浸面板
- 当前句最大最强（30pt bold）
- 上一句/下一句只做环境信息
- 翻译作为副行
- 封面和播放信息仅保留最小存在感（紧凑 header）

## 工程结构

```
Sources/lingdongdao/
├── lingdongdao.swift          # App 入口
├── AppDelegate.swift          # 生命周期
├── AnimationTokens.swift      # 统一动画 token
├── OverlaySettingsStore.swift # 配置持久化
├── OverlayPresentationState.swift # 展示状态机
├── LyricsOverlayState.swift   # 聚合状态
├── OverlayCoordinator.swift   # 数据协调
├── LyricsOverlayController.swift # 窗口/hover 控制
├── OverlayWindowManager.swift # NSPanel 管理
├── LyricsModels.swift         # 数据模型
├── LyricsThemeEngine.swift    # 主题引擎
├── LyricsLayoutEngine.swift   # 布局引擎
├── NowPlayingBridge.swift     # 播放/歌词/缓存协议 + Mock
├── LyricsOverlayRootView.swift # 根视图（薄层）
├── CollapsedCapsuleView.swift # 收起态胶囊视图
├── ExpandedImmersiveView.swift # 展开态沉浸面板
├── AlbumBadge.swift           # 封面徽章组件
├── MiniVisualizer.swift       # 迷你可视化组件
├── FadeTruncationModifier.swift # 渐隐截断修饰器
└── SettingsView.swift         # 设置页
```

## 状态机

`OverlayDisplayPhase`:
- `collapsed` → 收起待命
- `hoverExpanding` → 正在展开
- `expanded` → 歌词沉浸
- `hoverCollapsing` → 即将收起
- `trackTransition` → 切歌过渡
- `lyricTransition` → 歌词切换

## 真实接入点

以下协议已拆出正式接口，当前运行于 Mock 数据源：
- `PlaybackSource` — 播放状态数据源
- `LyricsSource` — 歌词获取源
- `LyricsCache` — 歌词缓存层

后续可接入 Apple Music、Spotify 或自定义来源。

## 构建

```bash
swift build
swift test
```

需要 macOS 14+ 和 Swift 6.3+。
