//
//  ImageFullscreenOverlay.swift
//  Dropin
//
//  Created by baptiste sansierra on 05/5/26.
//

import SwiftUI
import UIKit

struct ImageFullscreenOverlay: View {

    // MARK: private properties
    private let thumbnails: [(id: UUID, state: ImageLoadState)]
    private let loadFull: (UUID) async -> Data?
    private let onDismiss: () -> Void

    // MARK: States
    @State private var currentIndex: Int
    @State private var fullImages: [UUID: Data] = [:]

    // MARK: init
    init(thumbnails: [(id: UUID, state: ImageLoadState)],
         initialIndex: Int,
         loadFull: @escaping (UUID) async -> Data?,
         onDismiss: @escaping () -> Void) {
        self.thumbnails = thumbnails
        self.loadFull = loadFull
        self.onDismiss = onDismiss
        self._currentIndex = State(initialValue: initialIndex)
    }

    // MARK: body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            pagerView
            closeBtView
            pageIndicatorView
        }
        .statusBarHidden()
        .onChange(of: currentIndex) { _, newIdx in
            loadFullImageIfNeeded(at: newIdx)
        }
        .task {
            loadFullImageIfNeeded(at: currentIndex)
        }
    }

    // MARK: subviews
    private var pagerView: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(thumbnails.enumerated()), id: \.element.id) { index, item in
                ZStack {
                    if let placeholder = fullImages[item.id] ?? item.state.data {
                        ZoomableImageView(imageData: placeholder)
                    } else {
                        Color.black
                    }
                    if fullImages[item.id] == nil {
                        VStack {
                            Spacer()
                            ProgressView()
                                .tint(.white)
                                .padding(.bottom, 30)
                        }
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var closeBtView: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.5))
                            .frame(width: 35, height: 35)
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundStyle(.white)
                    }
                }
                .padding()
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var pageIndicatorView: some View {
        if thumbnails.count > 1 {
            VStack {
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<thumbnails.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? .white : .white.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: private methods
    private func loadFullImageIfNeeded(at index: Int) {
        guard index >= 0 && index < thumbnails.count else { return }
        let item = thumbnails[index]
        guard fullImages[item.id] == nil else { return }
        Task {
            if let data = await loadFull(item.id) {
                fullImages[item.id] = data
            }
        }
        let next = index + 1
        if next < thumbnails.count && fullImages[thumbnails[next].id] == nil {
            Task {
                if let data = await loadFull(thumbnails[next].id) {
                    fullImages[thumbnails[next].id] = data
                }
            }
        }
    }
}

// MARK: - ZoomableImageView

private struct ZoomableImageView: UIViewRepresentable {
    let imageData: Data

    func makeUIView(context: Context) -> ZoomScrollView {
        let view = ZoomScrollView()
        if let image = UIImage(data: imageData) {
            view.setImage(image)
        }
        return view
    }

    func updateUIView(_ uiView: ZoomScrollView, context: Context) {
        guard let image = UIImage(data: imageData) else { return }
        uiView.setImage(image)
    }
}

// MARK: - ZoomScrollView

private class ZoomScrollView: UIScrollView, UIScrollViewDelegate {

    private let imageView = UIImageView()
    private var currentFittedSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 4
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bouncesZoom = true
        backgroundColor = .clear
        // Single-finger touches pass through to the parent TabView for page swiping
        panGestureRecognizer.minimumNumberOfTouches = 2

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    func setImage(_ image: UIImage) {
        imageView.image = image
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let image = imageView.image else { return }
        let boundsSize = bounds.size
        guard boundsSize.width > 0, boundsSize.height > 0 else { return }

        let nativeSize = image.size
        let fitScale = min(boundsSize.width / nativeSize.width,
                           boundsSize.height / nativeSize.height)
        let fittedSize = CGSize(width: (nativeSize.width * fitScale).rounded(),
                                height: (nativeSize.height * fitScale).rounded())

        if fittedSize != currentFittedSize {
            currentFittedSize = fittedSize
            imageView.frame = CGRect(origin: .zero, size: fittedSize)
            contentSize = fittedSize
            zoomScale = minimumZoomScale
        }

        centerImageView()
    }

    private func centerImageView() {
        let offsetX = max((bounds.width - contentSize.width) / 2, 0)
        let offsetY = max((bounds.height - contentSize.height) / 2, 0)
        imageView.center = CGPoint(
            x: contentSize.width / 2 + offsetX,
            y: contentSize.height / 2 + offsetY
        )
    }

    private func recenterContent(animated: Bool) {
        // When zoomed in: clamp to valid scroll range so no empty space appears at any edge.
        // When content fits in screen: snap to origin (centerImageView handles visual centering).
        let maxOffsetX = max(contentSize.width - bounds.width, 0)
        let maxOffsetY = max(contentSize.height - bounds.height, 0)
        let target = CGPoint(
            x: min(max(contentOffset.x, 0), maxOffsetX),
            y: min(max(contentOffset.y, 0), maxOffsetY)
        )
        guard target != contentOffset else { return }
        if animated {
            UIView.animate(withDuration: 0.35, delay: 0,
                           usingSpringWithDamping: 0.8, initialSpringVelocity: 0,
                           options: .allowUserInteraction) {
                self.contentOffset = target
            }
        } else {
            contentOffset = target
        }
    }

    // MARK: UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        recenterContent(animated: true)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { recenterContent(animated: true) }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        recenterContent(animated: true)
    }

    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        if zoomScale > minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let location = recognizer.location(in: imageView)
            let zoomWidth = imageView.bounds.width / 2.5
            let zoomHeight = imageView.bounds.height / 2.5
            let zoomRect = CGRect(
                x: location.x - zoomWidth / 2,
                y: location.y - zoomHeight / 2,
                width: zoomWidth,
                height: zoomHeight
            )
            zoom(to: zoomRect, animated: true)
        }
    }
}
