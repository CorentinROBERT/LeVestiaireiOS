//
//  CachedRemoteImage.swift
//  LeVestaire
//
//  Created by Corentin Robert on 12/06/2026.
//

import SwiftUI
import Foundation

struct CachedRemoteImage<Content: View, Placeholder: View>: View {
    let url: URL
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let loadedImage {
                content(Image(uiImage: loadedImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        if loadedImage != nil { return }

        do {
            loadedImage = try await ImageCacheService.shared.image(for: url)
        } catch {
            loadedImage = nil
        }
    }
}

#Preview{
    let URL = URL(string:"https://picsum.photos/400")
    CachedRemoteImage(url: URL!) { image in
        image
            .scaledToFit()
            .frame(width: 400, height: 400)
            .clipped()
    } placeholder: {
        ProgressView()
            .ignoresSafeArea()
    }
}
