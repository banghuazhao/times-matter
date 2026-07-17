//
//  PurchaseSheet.swift
//  TimesMatter
//
//  Created by Lulin Yang on 2025/7/12.
//

import Dependencies
import SwiftUI

struct PurchaseSheet: View {
    @Dependency(\.purchaseManager) var purchaseManager
    @Dependency(\.themeManager) var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showSuccessModal = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    themeManager.current.primaryColor.opacity(0.18),
                    themeManager.current.background
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Button {
                            Haptics.shared.vibrateIfEnabled()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.appCircular)
                        .accessibilityLabel(String(localized: "Close"))
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.leading, 12)

                    ZStack {
                        Circle()
                            .fill(themeManager.current.primaryColor.opacity(0.2))
                            .frame(width: 96, height: 96)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.yellow)
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(String(localized: "Times Matter Premium"))
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)
                        Text(String(localized: "Unlock the full toolkit for beautiful countdowns—built for people who never want to miss what matters."))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(PremiumFeature.allCases) { feature in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: feature.systemImage)
                                    .font(.title3)
                                    .foregroundStyle(themeManager.current.primaryColor)
                                    .frame(width: 28)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.title)
                                        .font(.headline)
                                    Text(feature.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding()
                    .background(themeManager.current.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
                    .padding(.horizontal)

                    Text(String(localized: "Free includes \(PremiumLimits.freeCountdownLimit) countdowns. Premium is a one-time unlock."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if let product = purchaseManager.premiumProduct {
                        if purchaseManager.isPremiumUserPurchased {
                            Label(String(localized: "You’re a Premium member"), systemImage: "checkmark.seal.fill")
                                .font(.headline)
                                .foregroundStyle(themeManager.current.primaryColor)
                        } else {
                            Button {
                                Haptics.shared.vibrateIfEnabled()
                                Task { await purchase() }
                            } label: {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text(String(localized: "\(product.displayPrice) — Unlock Premium"))
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(themeManager.current.primaryColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal)
                            .disabled(isPurchasing)
                            .accessibilityHint(String(localized: "One-time purchase"))
                        }
                    } else {
                        ProgressView()
                        Text(String(localized: "Loading product…"))
                            .foregroundStyle(.secondary)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 16) {
                        Button(String(localized: "Restore Purchases")) {
                            Haptics.shared.vibrateIfEnabled()
                            Task {
                                isPurchasing = true
                                await purchaseManager.restorePurchases()
                                isPurchasing = false
                            }
                        }
                        Button(String(localized: "Contact Support")) {
                            if let url = URL(string: "https://apps-bay.github.io/Apps-Bay-Website/contact/") {
                                UIApplication.shared.open(url)
                            }
                        }
                        Button(String(localized: "Privacy Policy")) {
                            if let url = URL(string: "https://apps-bay.github.io/Apps-Bay-Website/privacy/") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .foregroundStyle(themeManager.current.primaryColor)
                    .font(.body)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showSuccessModal) {
            PremiumSuccessView()
        }
        .task {
            await purchaseManager.loadPremiumProduct()
        }
        .onAppear {
            isPurchasing = false
        }
    }

    private func purchase() async {
        isPurchasing = true
        errorMessage = nil
        let result = await purchaseManager.purchasePremium()
        switch result {
        case .success:
            showSuccessModal = true
        case .failure(let error):
            if case .userCancelled = error {
                break
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isPurchasing = false
    }
}

struct ConfettiDot: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let size: CGFloat
}

struct PremiumSuccessView: View {
    var onContinue: (() -> Void)? = nil
    @State private var animate = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let confetti: [ConfettiDot] = (0..<20).map { _ in
        ConfettiDot(
            x: CGFloat.random(in: 40...340),
            y: CGFloat.random(in: 40...600),
            color: [Color.pink.opacity(0.7), Color.mint, Color.indigo, Color.teal, Color.orange.opacity(0.7)].randomElement()!,
            size: CGFloat.random(in: 8...14)
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.pink.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if !reduceMotion {
                ForEach(confetti) { dot in
                    Circle()
                        .fill(dot.color)
                        .frame(width: dot.size, height: dot.size)
                        .position(x: dot.x, y: animate ? dot.y : dot.y - 80)
                        .opacity(0.6)
                        .animation(.easeOut(duration: 1.2), value: animate)
                }
            }

            VStack(spacing: 26) {
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundStyle(.indigo)
                    .accessibilityHidden(true)

                Text(String(localized: "You’re All Set!"))
                    .font(.system(size: 26, weight: .semibold))

                Text(String(localized: "Premium is unlocked. Enjoy unlimited countdowns, custom sounds, photo backgrounds, and premium share cards."))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach([
                        String(localized: "Unlimited countdowns"),
                        String(localized: "Ad-free experience"),
                        String(localized: "Custom sounds & photos"),
                        String(localized: "Premium share cards"),
                    ], id: \.self) { line in
                        Label(line, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.primary)
                    }
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    if let onContinue {
                        onContinue()
                    } else {
                        dismiss()
                    }
                } label: {
                    Text(String(localized: "Continue"))
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 44)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.teal, Color.indigo]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 18))
                }
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color.white.opacity(0.95))
            )
            .shadow(radius: 20)
            .padding(.horizontal, 24)
            .onAppear { animate = true }
        }
    }
}

#Preview {
    PurchaseSheet()
}
