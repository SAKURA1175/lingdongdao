import AppKit
import Combine

@MainActor
final class LyricsOverlayController: NSResponder {
    let state: LyricsOverlayState

    private let coordinator: OverlayCoordinator
    private let windowManager: OverlayWindowManager
    private var cancellables: Set<AnyCancellable> = []

    init(
        state: LyricsOverlayState,
        coordinator: OverlayCoordinator,
        windowManager: OverlayWindowManager = OverlayWindowManager()
    ) {
        self.state = state
        self.coordinator = coordinator
        self.windowManager = windowManager
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWindow() {
        windowManager.installIfNeeded(state: state)
        coordinator.start()
        wireState()
        updateVisibility(showIsland: state.settings.showIsland)
        windowManager.position(using: state, animated: false)
    }

    func stop() {
        coordinator.stop()
    }

    private func wireState() {
        guard cancellables.isEmpty else { return }

        state.settings.$showIsland
            .removeDuplicates()
            .sink { [weak self] showIsland in
                self?.updateVisibility(showIsland: showIsland)
            }
            .store(in: &cancellables)

        state.settings.$hideInFullScreen
            .removeDuplicates()
            .sink { [weak self] hideInFullScreen in
                self?.windowManager.applyCollectionBehavior(hideInFullScreen: hideInFullScreen)
            }
            .store(in: &cancellables)

        Publishers.MergeMany(
            state.settings.$verticalAnchor.map { _ in () }.eraseToAnyPublisher(),
            state.settings.$horizontalAnchor.map { _ in () }.eraseToAnyPublisher(),
            state.settings.$islandStyle.map { _ in () }.eraseToAnyPublisher(),
            state.settings.$showBottomLyrics.map { _ in () }.eraseToAnyPublisher(),
            state.settings.$lineMode.map { _ in () }.eraseToAnyPublisher(),
            state.settings.$widthMode.map { _ in () }.eraseToAnyPublisher(),
            state.settings.$showTranslation.map { _ in () }.eraseToAnyPublisher()
        )
        .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            guard let self, self.state.settings.showIsland else { return }
            self.windowManager.position(using: self.state, animated: true)
        }
        .store(in: &cancellables)
    }

    private func updateVisibility(showIsland: Bool) {
        if showIsland {
            windowManager.show()
            windowManager.position(using: state, animated: false)
        } else {
            windowManager.hide()
        }
    }
}
