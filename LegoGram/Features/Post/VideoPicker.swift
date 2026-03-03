import SwiftUI
import PhotosUI
import AVFoundation

/// Lets the user pick a video from their photo library for a new post.
/// Videos must be under 60 seconds for kid safety — longer videos are rejected with a friendly message.
struct VideoPicker: UIViewControllerRepresentable {

    /// Binding to the selected video file URL (nil if nothing chosen yet).
    @Binding var selectedVideoURL: URL?

    /// Set to true if the picked video is over 60 seconds so we can show an alert.
    @Binding var videoTooLong: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker

        init(_ parent: VideoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else { return }

            // Load the video file URL
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, error in
                guard let self, let url, error == nil else { return }

                // Copy to a temporary location so the file stays accessible
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension)

                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
                } catch {
                    print("VideoPicker: failed to copy video — \(error)")
                    return
                }

                // Check duration — max 60 seconds for kid safety
                let asset = AVURLAsset(url: tempURL)
                Task {
                    do {
                        let duration = try await asset.load(.duration)
                        let seconds = CMTimeGetSeconds(duration)
                        await MainActor.run {
                            if seconds > 60 {
                                self.parent.videoTooLong = true
                            } else {
                                self.parent.selectedVideoURL = tempURL
                            }
                        }
                    } catch {
                        print("VideoPicker: failed to load duration — \(error)")
                    }
                }
            }
        }
    }
}
