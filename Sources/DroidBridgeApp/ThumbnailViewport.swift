import AppKit
import SwiftUI

struct ThumbnailViewport: NSViewRepresentable {
    let changed: (Bool) -> Void

    func makeNSView(context: Context) -> ThumbnailViewportView {
        ThumbnailViewportView(frame: .zero)
    }

    func updateNSView(_ view: ThumbnailViewportView, context: Context) {
        view.changed = changed
        view.scheduleCheck()
    }

    static func dismantleNSView(_ view: ThumbnailViewportView, coordinator: ()) {
        view.stop()
    }
}

final class ThumbnailViewportView: NSView {
    var changed: ((Bool) -> Void)?
    private weak var viewport: NSClipView?
    private var lastVisibility: Bool?
    private var scheduled = false

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        observeViewport()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observeViewport()
    }

    override func layout() {
        super.layout()
        scheduleCheck()
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func stop() {
        NotificationCenter.default.removeObserver(self)
        viewport = nil
        changed = nil
    }

    private func observeViewport() {
        let clip = enclosingScrollView?.contentView
        if viewport !== clip {
            NotificationCenter.default.removeObserver(self)
            viewport = clip
            if let clip {
                clip.postsBoundsChangedNotifications = true
                NotificationCenter.default.addObserver(
                    self, selector: #selector(scheduleCheck),
                    name: NSView.boundsDidChangeNotification, object: clip
                )
            }
        }
        scheduleCheck()
    }

    @objc func scheduleCheck() {
        guard !scheduled else { return }
        scheduled = true
        DispatchQueue.main.async { [weak self] in self?.checkVisibility() }
    }

    private func checkVisibility() {
        scheduled = false
        guard let changed else { return }
        let visible = viewport.map { clip in
            window != nil && !bounds.isEmpty && !convert(bounds, to: clip).intersection(clip.bounds).isEmpty
        } ?? false
        guard visible != lastVisibility else { return }
        lastVisibility = visible
        changed(visible)
    }
}
