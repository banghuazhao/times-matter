//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI
import UIKit

enum ShareCardStyle: String, CaseIterable, Identifiable {
    case classic
    case minimal
    case story

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: String(localized: "Classic")
        case .minimal: String(localized: "Minimal")
        case .story: String(localized: "Story")
        }
    }

    var isPremium: Bool {
        switch self {
        case .classic: false
        case .minimal, .story: true
        }
    }

    var canvasSize: CGSize {
        switch self {
        case .classic: CGSize(width: 1080, height: 1350)
        case .minimal: CGSize(width: 1080, height: 1080)
        case .story: CGSize(width: 1080, height: 1920)
        }
    }
}

struct ShareCardSheet: View {
    let countdown: Countdown
    let relativeNumber: String
    let relativeLabel: String
    let backgroundColor: Color
    let textColor: Color
    let backgroundImageName: String?

    @Environment(\.dismiss) private var dismiss
    @Dependency(\.themeManager) private var themeManager
    @Dependency(\.purchaseManager) private var purchaseManager
    @Dependency(\.appRatingService) private var appRatingService

    @State private var style: ShareCardStyle = .classic
    @State private var shareImage: UIImage?
    @State private var isSharePresented = false
    @State private var showPurchase = false

    private var isPremium: Bool { purchaseManager.isPremiumUserPurchased }
    private var showWatermark: Bool { !isPremium }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.medium) {
                Picker(String(localized: "Style"), selection: $style) {
                    ForEach(ShareCardStyle.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    shareCardPreview
                        .frame(maxWidth: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 8)
                        .padding()
                        .frame(maxWidth: .infinity)
                }

                if style.isPremium && !isPremium {
                    Label(
                        String(localized: "Premium style — upgrade to export without limits"),
                        systemImage: "crown.fill"
                    )
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                }

                Button {
                    Haptics.shared.vibrateIfEnabled()
                    exportAndShare()
                } label: {
                    Label(String(localized: "Share Card"), systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.appRectFilled)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(themeManager.current.background)
            .navigationTitle(String(localized: "Share"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) { dismiss() }
                }
            }
            .sheet(isPresented: $isSharePresented) {
                if let shareImage {
                    ShareSheet(activityItems: [shareImage, shareMessage])
                }
            }
            .sheet(isPresented: $showPurchase) {
                PurchaseSheet()
            }
        }
    }

    private var shareMessage: String {
        String(
            localized: "Counting down to \(countdown.title) with Times Matter: https://apps.apple.com/app/id\(Constants.AppID.thisAppID)"
        )
    }

    private var shareCardPreview: some View {
        ShareCardView(
            countdown: countdown,
            relativeNumber: relativeNumber,
            relativeLabel: relativeLabel,
            backgroundColor: backgroundColor,
            textColor: textColor,
            backgroundImageName: backgroundImageName,
            style: style,
            showWatermark: showWatermark
        )
        .aspectRatio(style.canvasSize.width / style.canvasSize.height, contentMode: .fit)
    }

    private func exportAndShare() {
        if style.isPremium && !isPremium {
            showPurchase = true
            return
        }

        let card = ShareCardView(
            countdown: countdown,
            relativeNumber: relativeNumber,
            relativeLabel: relativeLabel,
            backgroundColor: backgroundColor,
            textColor: textColor,
            backgroundImageName: backgroundImageName,
            style: style,
            showWatermark: showWatermark
        )
        .frame(width: style.canvasSize.width, height: style.canvasSize.height)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 1
        if let image = renderer.uiImage {
            shareImage = image
            isSharePresented = true
            appRatingService.recordMeaningfulAction(.sharedCard)
        }
    }
}

struct ShareCardView: View {
    let countdown: Countdown
    let relativeNumber: String
    let relativeLabel: String
    let backgroundColor: Color
    let textColor: Color
    let backgroundImageName: String?
    let style: ShareCardStyle
    let showWatermark: Bool

    var body: some View {
        ZStack {
            background
            content
            if showWatermark {
                VStack {
                    Spacer()
                    Text("Times Matter")
                        .font(.system(size: style == .story ? 36 : 28, weight: .semibold))
                        .foregroundStyle(textColor.opacity(0.75))
                        .padding(.bottom, style == .story ? 64 : 40)
                }
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        if let backgroundImageName, !backgroundImageName.isEmpty {
            if let uiImage = UIImage(contentsOfFile: backgroundImageName) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else if UIImage(named: backgroundImageName) != nil {
                Image(backgroundImageName).resizable().scaledToFill()
            } else {
                backgroundColor
            }
        } else {
            LinearGradient(
                colors: [backgroundColor, backgroundColor.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .classic:
            VStack(spacing: 28) {
                Text(countdown.title)
                    .font(.system(size: 64, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(countdown.timeSummary)
                    .font(.system(size: 32, weight: .medium))
                VStack(spacing: 8) {
                    Text(relativeNumber)
                        .font(.system(size: 140, weight: .bold, design: .rounded))
                    Text(relativeLabel)
                        .font(.system(size: 36, weight: .semibold))
                }
                .padding(36)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 36))
            }
            .foregroundStyle(textColor)
            .padding(48)

        case .minimal:
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                Text(relativeNumber)
                    .font(.system(size: 180, weight: .bold, design: .rounded))
                Text(relativeLabel.uppercased())
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(2)
                Text(countdown.title)
                    .font(.system(size: 48, weight: .bold))
                Spacer()
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(64)

        case .story:
            VStack(spacing: 40) {
                Spacer()
                Text(String(localized: "COUNTING DOWN"))
                    .font(.system(size: 28, weight: .bold))
                    .tracking(4)
                Text(countdown.title)
                    .font(.system(size: 72, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(relativeNumber)
                    .font(.system(size: 200, weight: .bold, design: .rounded))
                Text(relativeLabel)
                    .font(.system(size: 40, weight: .medium))
                Spacer()
            }
            .foregroundStyle(textColor)
            .padding(56)
        }
    }
}
