//
//  ULanding.swift
//  LeVestaire
//
//  Created by Corentin Robert on 09/06/2026.
//

import SwiftUI

struct ULanding: View {
    let items: [CarouselItem]
    let onFinished: (() -> Void)?

    @State private var currentIndex = 0

    init(
        items: [CarouselItem],
        buttonTitle: String? = nil,
        onFinished: (() -> Void)? = nil
    ) {
        self.items = items
        self.onFinished = onFinished
    }

    private var isLastPage: Bool {
        currentIndex == items.count - 1
    }

    private var currentButtonTitle: String {
        isLastPage ? L10n.discover : L10n.next
    }

    var body: some View {
        GeometryReader { geometry in
            let fullSize = geometry.size

            ZStack(alignment: .bottom) {

                TabView(selection: $currentIndex) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        Group {
                            if item.isWelcomeSlide {
                                welcomeSlideCard(for: item, size: fullSize)
                            } else {
                                carouselCard(for: item, size: fullSize)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: 20) {

                    UButton(
                        text: currentButtonTitle,
                        textColor: .black,
                        backgroundColor: .white,
                        cornerRadius: 25,
                        isFullWidth: true,
                        onPress: onButtonPress
                    )

                    pageIndicator
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .ignoresSafeArea()
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<items.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index == currentIndex
                            ? AppPalette.Primary.onMain
                            : AppPalette.Primary.onMain.opacity(0.45)
                    )
                    .frame(width: index == currentIndex ? 20 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }

    private func welcomeSlideCard(for item: CarouselItem, size: CGSize) -> some View {
        ZStack {
            AuthScreenBackground()

            VStack(spacing: 20) {
                Image(systemName: item.iconSystemName ?? "sportscourt.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(AppPalette.Primary.main)
                    .frame(width: 88, height: 88)
                    .glassEffect(.regular, in: .circle)

                Text(item.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppPalette.Primary.dark)
                    .multilineTextAlignment(.center)

                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.title3)
                        .foregroundStyle(AppPalette.Neutral.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 160)
            .frame(width: size.width, height: size.height)
        }
    }

    private func carouselCard(for item: CarouselItem, size: CGSize) -> some View {
        ZStack(alignment: .bottomLeading) {
            item.backgroundColor.ignoresSafeArea()

            carouselImage(source: item.imageSource, fallbackColor: item.backgroundColor, size: size)
                .blur(radius: 8)
                .opacity(0.90)
                .glassEffect(.regular, in: .rect())
                .ignoresSafeArea()
            
            LinearGradient( colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom ) .frame(width: size.width, height: size.height)

            VStack(alignment: .leading) {
                
                Text(item.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.headline)
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
            .padding(.bottom, 140)
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

    private func onButtonPress() {
        if isLastPage {
            onFinished?()
        } else {
            withAnimation {
                currentIndex += 1
            }
        }
    }
}

#Preview {
    ULanding(
        items: [
            .welcome(
                appName: "Le Vestiaire",
                tagline: "Gérez vos équipes et matchs en toute simplicité"
            ),
            CarouselItem(
                title: "Produit 1",
                imageSource: "https://images.printkk.com/product/football-jersey-wjmqj-718.png",
                subtitle: "New Product",
                backgroundColor: .red
            ),
            CarouselItem(
                title: "Produit 2",
                imageSource: "https://p7.hiclipart.com/preview/803/836/32/football-nike-ordem-team-ballon-foot.jpg",
                subtitle: "Nouvelle collection",
                backgroundColor: .red
            )
        ],
        buttonTitle: "Commencer"
    )
}
