import SwiftUI

/// Sprint 6 Feature 3 — Background image crop & centering tool.
/// Shows the full photo with drag-to-pan and pinch-to-zoom so the user can
/// frame the image exactly. The crop window matches the profile header
/// proportions (full screen width, 160 pt tall).
/// Tapping Done crops the image to the selected region and returns it.
/// Tapping Cancel dismisses without saving.
struct CropView: View {

    let image: UIImage
    let onDone: (UIImage) -> Void
    let onCancel: () -> Void

    // Profile header height used as the crop window height
    private let cropHeight: CGFloat = 160

    @State private var scale: CGFloat       = 1.0
    @State private var lastScale: CGFloat   = 1.0
    @State private var offset: CGSize       = .zero
    @State private var lastOffset: CGSize   = .zero

    var body: some View {
        GeometryReader { geo in
            let cropY = (geo.size.height - cropHeight) / 2

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
                cropOverlay(geo: geo, cropY: cropY)
            }
            // MARK: Done / Cancel buttons
            .overlay(alignment: .bottom) {
                actionButtons(geo: geo, cropY: cropY)
            }
        }
        .ignoresSafeArea()
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

    private func cropOverlay(geo: GeometryProxy, cropY: CGFloat) -> some View {
        ZStack {
            // Top dark strip
            Rectangle()
                .fill(Color.black.opacity(0.55))
                .frame(width: geo.size.width, height: max(0, cropY))
                .position(x: geo.size.width / 2, y: cropY / 2)

            // Bottom dark strip
            let bottomH = geo.size.height - cropY - cropHeight
            Rectangle()
                .fill(Color.black.opacity(0.55))
                .frame(width: geo.size.width, height: max(0, bottomH))
                .position(
                    x: geo.size.width / 2,
                    y: cropY + cropHeight + bottomH / 2
                )

            // White crop frame border
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: geo.size.width, height: cropHeight)
                .position(x: geo.size.width / 2, y: cropY + cropHeight / 2)

            // Hint label below the crop frame
            Text("Drag and pinch to position")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.black.opacity(0.45))
                .cornerRadius(6)
                .position(
                    x: geo.size.width / 2,
                    y: cropY + cropHeight + 26
                )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Action Buttons

    private func actionButtons(geo: GeometryProxy, cropY: CGFloat) -> some View {
        HStack {
            Button("Cancel") { onCancel() }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 28).padding(.vertical, 14)
                .background(Color.gray.opacity(0.55))
                .cornerRadius(12)

            Spacer()

            Button("Done") {
                let cropped = cropImage(geo: geo, cropY: cropY)
                onDone(cropped)
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
    /// given the current pan/zoom state, then returns that region as a UIImage.
    private func cropImage(geo: GeometryProxy, cropY: CGFloat) -> UIImage {
        let vW = geo.size.width
        let vH = geo.size.height
        let iW = image.size.width
        let iH = image.size.height
        let imgAspect = iW / iH

        // How large is the image displayed on screen right now?
        var dispW: CGFloat
        var dispH: CGFloat
        if imgAspect > vW / vH {
            // image wider → height fills view
            dispH = vH * scale
            dispW = dispH * imgAspect
        } else {
            // image taller → width fills view
            dispW = vW * scale
            dispH = dispW / imgAspect
        }

        // Top-left of the displayed image in view coordinates
        let imgLeft = vW / 2 + offset.width  - dispW / 2
        let imgTop  = vH / 2 + offset.height - dispH / 2

        // Crop window in view coordinates (full width, cropHeight, at cropY)
        // → as fraction of the displayed image
        let relL = -imgLeft          / dispW
        let relT = (cropY - imgTop)  / dispH
        let relW = vW                / dispW
        let relH = cropHeight        / dispH

        // Convert fractions to original image pixels
        var pxL = relL * iW
        var pxT = relT * iH
        var pxW = relW * iW
        var pxH = relH * iH

        // Clamp to image bounds
        pxL = max(0, min(pxL, iW - 1))
        pxT = max(0, min(pxT, iH - 1))
        pxW = max(1, min(pxW, iW - pxL))
        pxH = max(1, min(pxH, iH - pxT))

        let cropRect = CGRect(x: pxL, y: pxT, width: pxW, height: pxH)
        if let cgImg = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImg, scale: image.scale,
                           orientation: image.imageOrientation)
        }
        return image
    }
}

#Preview {
    CropView(
        image: UIImage(systemName: "photo.fill") ?? UIImage(),
        onDone: { _ in },
        onCancel: {}
    )
}
