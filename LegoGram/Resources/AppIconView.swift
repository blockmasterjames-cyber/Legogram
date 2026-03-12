import SwiftUI

// =============================================================
// HOW TO GENERATE AND INSTALL THE BRICKFEED APP ICON
// =============================================================
//
// Run this ONE terminal command from the project root directory:
//
//   xcodebuild -project LegoGram.xcodeproj -scheme BrickFeed \
//     -destination 'platform=iOS Simulator,name=iPhone 15' build \
//   && xcrun simctl boot "iPhone 15" 2>/dev/null; \
//   xcrun simctl install booted /path/to/BrickFeed.app
//
// ------ SIMPLER OPTION (recommended for dad) ------
//
// 1. Open the app in Xcode.
// 2. In the Preview canvas below, select the AppIconPreview.
// 3. Right-click the canvas and choose "Save Current Frame as PNG".
//    Save it as AppIcon-1024.png.
// 4. Drag the saved PNG into:
//    LegoGram/Resources/Assets.xcassets/AppIcon.appiconset/
//    and replace any existing 1024x1024 entry.
// 5. Xcode will auto-generate all smaller sizes.
//
// =============================================================

/// SwiftUI rendering of the BrickFeed app icon.
/// Use the #Preview below to screenshot it and install it in Assets.
struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // LEGO red background
            Color.legoRed

            VStack(spacing: size * 0.05) {
                // Camera-brick design
                cameraBrick
                // BrickFeed logotype
                HStack(spacing: 0) {
                    Text("Brick")
                        .font(.system(size: size * 0.13, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Feed")
                        .font(.system(size: size * 0.13, weight: .black, design: .rounded))
                        .foregroundColor(.legoYellow)
                }
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(size * 0.225) // iOS icon rounding
    }

    // MARK: - Camera Brick

    private var cameraBrick: some View {
        ZStack {
            // Brick body
            RoundedRectangle(cornerRadius: size * 0.07)
                .fill(Color.white.opacity(0.92))
                .frame(width: size * 0.58, height: size * 0.40)

            // Camera lens
            Circle()
                .fill(Color.legoRed)
                .frame(width: size * 0.24, height: size * 0.24)
                .overlay(
                    Circle()
                        .fill(Color.black.opacity(0.45))
                        .frame(width: size * 0.13, height: size * 0.13)
                )

            // LEGO studs across the top of the brick
            HStack(spacing: size * 0.055) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.82))
                        .frame(width: size * 0.075, height: size * 0.075)
                }
            }
            .offset(y: -(size * 0.40 / 2) + size * 0.045)
        }
    }
}

#Preview("App Icon — 300pt preview") {
    AppIconView(size: 300)
        .padding(20)
        .background(Color.gray.opacity(0.3))
}
