//
//  UCarousel.swift
//  LeVestaire
//
//  Created by Corentin Robert on 09/06/2026.
//

import SwiftUI

struct UCarousel: View {
    let items: [CarouselItem]

    var body: some View {
        GeometryReader { geometry in
            let fullSize = geometry.size

            TabView {
                ForEach(items) { item in
                    carouselCard(for: item, size: fullSize)
                }
            }
            .tabViewStyle(.page)
        }
        .ignoresSafeArea()
    }

    private func carouselCard(for item: CarouselItem, size: CGSize) -> some View {
        ZStack(alignment: .bottomLeading) {
            item.backgroundColor.ignoresSafeArea()

            carouselImage(source: item.imageSource, fallbackColor: item.backgroundColor, size: size)
                .blur(radius: 8)
                .opacity(0.75)
                .glassEffect(.regular, in: .rect())
                .ignoresSafeArea()
            
            LinearGradient( colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom ) .frame(width: size.width, height: size.height)

            VStack(alignment: .leading, spacing: 15) {
                Text(item.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                        .padding(.bottom, 10)
                }

                if let buttonTitle = item.buttonTitle, !buttonTitle.isEmpty {
                    UButton(
                        text: buttonTitle,
                        textColor: .black,
                        backgroundColor: .white,
                        cornerRadius: 25,
                        isFullWidth: true,
                        onPress: item.onButtonPress
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 64)
            .frame(width: size.width, height: size.height, alignment: .bottomLeading)
            .zIndex(1)
        }
    }

    @ViewBuilder
    private func carouselImage(source: String, fallbackColor: Color, size: CGSize) -> some View {
        if let url = URL(string: source), url.scheme == "http" || url.scheme == "https" {
            CachedRemoteImage(url: url) { image in
                image
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } placeholder: {
                ProgressView()
                    .ignoresSafeArea()
            }
        } else {
            Image(source)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
        }
    }
}

#Preview {
    UCarousel(
        items: [
            CarouselItem(
                title: "Produit 1",
                imageSource: "https://images.printkk.com/product/football-jersey-wjmqj-718.png",
                subtitle: "New Product",
                buttonTitle: "Voir",
                backgroundColor: .red
            ),
            CarouselItem(
                title: "Produit 2",
                imageSource: "https://p7.hiclipart.com/preview/803/836/32/football-nike-ordem-team-ballon-foot.jpg",
                subtitle: "Nouvelle collection",
                buttonTitle: "Decouvrir",
                backgroundColor: .red
            )
        ]
    )
}
