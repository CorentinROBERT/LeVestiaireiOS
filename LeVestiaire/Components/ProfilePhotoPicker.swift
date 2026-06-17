//
//  ProfilePhotoPicker.swift
//  LeVestaire
//
//  Created by Corentin Robert on 14/06/2026.
//

import PhotosUI
import SwiftUI
import UIKit

struct ProfilePhotoPicker: View {
    @Binding var selectedImage: UIImage?
    var isUploading = false

    @State private var showSourceDialog = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(AppPalette.Primary.soft)
                        .frame(width: 120, height: 120)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(AppPalette.Primary.muted)
                        }
                }

                Circle()
                    .strokeBorder(AppPalette.Primary.main.opacity(0.35), lineWidth: 2)
                    .frame(width: 120, height: 120)

                if isUploading {
                    Circle()
                        .fill(Color.black.opacity(0.45))
                        .frame(width: 120, height: 120)
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                }
            }

            Button {
                showSourceDialog = true
            } label: {
                Label(L10n.choosePhoto, systemImage: "camera.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.Primary.main)
            }
            .buttonStyle(.plain)
            .disabled(isUploading)
        }
        .frame(maxWidth: .infinity)
        .confirmationDialog(L10n.profilePhoto, isPresented: $showSourceDialog, titleVisibility: .visible) {
            Button(L10n.camera) {
                showCamera = true
            }
            Button(L10n.photoLibrary) {
                showPhotoLibrary = true
            }
            if selectedImage != nil {
                Button(L10n.deletePhoto, role: .destructive) {
                    selectedImage = nil
                    selectedPhotoItem = nil
                }
            }
            Button(L10n.cancel, role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker(image: $selectedImage)
                .ignoresSafeArea()
        }
    }
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    @Previewable @State var selectedImage: UIImage?

    ZStack {
        AuthScreenBackground()
        ProfilePhotoPicker(selectedImage: $selectedImage)
            .padding()
    }
}
