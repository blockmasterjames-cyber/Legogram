import SwiftUI
import UIKit

/// Drag-to-pan + pinch-to-zoom image cropper.
///
/// The crop window is parameterized by `cropAspect` (width / height):
///   • `1.0` → a SQUARE crop window (used by the post composer).
///   • other ratios → a banner-style window (e.g. profile header).
/// The window is sized to the largest rectangle of that aspect that fits the
/// available space, centered on screen.
///
/// Tapping Done crops the image to the region the user framed and returns it
/// as a UIImage whose aspect ratio matches the crop window (a real pixel crop,
/// not a visual mask). Tapping Cancel dismisses without saving.
struct CropView: View {

    let image: UIImage
    let onDone: (UIImage) -> Void
    let onCancel: () -> Void

    /// Aspect ratio (width / height) of the crop window. `1.0` == square.
    var cropAspect: CGFloat = 1.0

    @State private var scale: CGFloat       = 1.0
    @State private var lastScale: CGFloat   = 1.0
    @State private var offset: CGSize       = .zero
    @State private var lastOffset: CGSize   = .zero

    var body: some View {
        GeometryReader { geo in
            let crop = cropRect(in: geo.size)

            ZStack {
                Color.black.ignoresSafeArea()

                // MARK: Pannable / Zoomable image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width:  geo.size.width  * scale,
                        height: geo.size.height * scale
                    )
                    .offset(offset)
                    .clipped()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .simultaneousGesture(dragGesture)
                    .simultaneousGesture(magnificationGesture)

                // MARK: Crop overlay
                cropOverlay(geo: geo, crop: crop)
            }
            // MARK: Done / Cancel buttons
            .overlay(alignment: .bottom) {
                actionButtons(geo: geo, crop: crop)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Crop Window Geometry

    /// Largest rect of `cropAspect` that fits inside `size`, centered.
    private func cropRect(in size: CGSize) -> CGRect {
        var w = size.width
        var h = w / cropAspect
        if h > size.height {
            h = size.height
            w = h * cropAspect
        }
        let x = (size.width  - w) / 2
        let y = (size.height - h) / 2
        return CGRect(x: x, y: y, width: w, height: h)
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                offset = CGSize(
                    width:  lastOffset.width  + v.translation.width,
                    height: lastOffset.height + v.translation.height
                )
            }
            .onEnded { _ in lastOffset = offset }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { v in scale = max(0.5, min(5.0, lastScale * v)) }
            .onEnded   { _ in lastScale = scale }
    }

    // MARK: - Overlay (dark strips + border)

    private func cropOverlay(geo: GeometryProxy, crop: CGRect) -> some View {
        let fullW = geo.size.width
        let fullH = geo.size.height
        let bottomH = fullH - crop.maxY
        let rightW  = fullW - crop.maxX
        return ZStack {
            // Dim everything outside the crop window with four strips.
            dimStrip(w: fullW,       h: crop.minY, x: fullW / 2,            y: crop.minY / 2)
            dimStrip(w: fullW,       h: bottomH,   x: fullW / 2,            y: crop.maxY + bottomH / 2)
            dimStrip(w: crop.minX,   h: crop.height, x: crop.minX / 2,      y: crop.midY)
            dimStrip(w: rightW,      h: crop.height, x: crop.maxX + rightW / 2, y: crop.midY)

            // White crop frame border
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: crop.width, height: crop.height)
                .position(x: crop.midX, y: crop.midY)

            // Hint label below the crop frame
            Text("Drag and pinch to position")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.black.opacity(0.45))
                .cornerRadius(6)
                .position(x: crop.midX, y: crop.maxY + 26)
        }
        .allowsHitTesting(false)
    }

    private func dimStrip(w: CGFloat, h: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Rectangle()
            .fill(Color.black.opacity(0.55))
            .frame(width: max(0, w), height: max(0, h))
            .position(x: x, y: y)
    }

    // MARK: - Action Buttons

    private func actionButtons(geo: GeometryProxy, crop: CGRect) -> some View {
        HStack {
            Button("Cancel") { onCancel() }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 28).padding(.vertical, 14)
                .background(Color.gray.opacity(0.55))
                .cornerRadius(12)

            Spacer()

            Button("Done") {
                onDone(cropImage(geo: geo, crop: crop))
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 28).padding(.vertical, 14)
            .background(Color.legoRed)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 52)
    }

    // MARK: - Crop Math

    /// Calculates the pixel region of `image` visible inside the crop window
    /// given the current pan/zoom state, then returns that region as a UIImage
    /// whose aspect ratio matches the crop window.
    private func cropImage(geo: GeometryProxy, crop: CGRect) -> UIImage {
        // Normalize orientation so the CGImage pixel grid matches `size`
        // (portrait photos often carry orientation metadata that would
        // otherwise misalign the crop).
        let src = normalizedImage(image)
        guard let cg = src.cgImage else { return image }

        let vW = geo.size.width
        let vH = geo.size.height
        let iW = src.size.width
        let iH = src.size.height
        let imgAspect = iW / iH

        // Displayed (pre-clip) size of the full image under scaledToFill
        // into the (vW*scale × vH*scale) frame.
        var dispW: CGFloat
        var dispH: CGFloat
        if imgAspect > vW / vH {
            // image wider → height fills
            dispH = vH * scale
            dispW = dispH * imgAspect
        } else {
            // image taller → width fills
            dispW = vW * scale
            dispH = dispW / imgAspect
        }

        // Top-left of the displayed image in view coordinates
        let imgLeft = vW / 2 + offset.width  - dispW / 2
        let imgTop  = vH / 2 + offset.height - dispH / 2

        // Crop window as fractions of the displayed image
        let relL = (crop.minX - imgLeft) / dispW
        let relT = (crop.minY - imgTop)  / dispH
        let relW = crop.width  / dispW
        let relH = crop.height / dispH

        // Convert fractions to CGImage pixels
        let pW = CGFloat(cg.width)
        let pH = CGFloat(cg.height)
        var pxL = relL * pW
        var pxT = relT * pH
        var pxW = relW * pW
        var pxH = relH * pH

        // For a square window, scaledToFill scales uniformly so pxW ≈ pxH;
        // snap to an exact square to guard against float drift / clamping.
        if abs(cropAspect - 1) < 0.001 {
            let side = min(pxW, pxH)
            pxW = side
            pxH = side
        }

        // Clamp to image bounds while preserving the crop size where possible
        pxW = max(1, min(pxW, pW))
        pxH = max(1, min(pxH, pH))
        pxL = max(0, min(pxL, pW - pxW))
        pxT = max(0, min(pxT, pH - pxH))

        let cropRect = CGRect(x: pxL, y: pxT, width: pxW, height: pxH)
        if let cgImg = cg.cropping(to: cropRect) {
            return UIImage(cgImage: cgImg, scale: src.scale, orientation: .up)
        }
        return src
    }

    /// Redraws the image with an `.up` orientation if needed so the CGImage
    /// pixel buffer aligns with `image.size`.
    private func normalizedImage(_ img: UIImage) -> UIImage {
        guard img.imageOrientation != .up else { return img }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = img.scale
        let renderer = UIGraphicsImageRenderer(size: img.size, format: format)
        return renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: img.size))
        }
    }
}

#Preview {
    CropView(
        image: UIImage(systemName: "photo.fill") ?? UIImage(),
        onDone: { _ in },
        onCancel: {}
    )
}
