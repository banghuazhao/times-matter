//
// Created by Banghua Zhao on 13/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

struct GallerySheet: View {
    let onSelect: (Countdown.Draft) -> Void
    @Environment(\.dismiss) var dismiss
    @Dependency(\.themeManager) var themeManager
    @State private var selectedSeason: GalleryTemplate.Season? = nil

    private var templates: [GalleryTemplate] {
        guard let selectedSeason else { return GalleryTemplate.all }
        return GalleryTemplate.all.filter { $0.season == selectedSeason }
    }

    private var highlighted: [GalleryTemplate] {
        GalleryTemplate.currentSeasonHighlights
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text(String(localized: "Events Gallery"))
                        .font(AppFont.title2)
                        .foregroundStyle(themeManager.current.textPrimary)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(String(localized: "Close"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.small) {
                        seasonChip(title: String(localized: "All"), selected: selectedSeason == nil) {
                            selectedSeason = nil
                        }
                        ForEach(GalleryTemplate.Season.allCases) { season in
                            seasonChip(title: season.title, selected: selectedSeason == season) {
                                selectedSeason = season
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        if selectedSeason == nil, !highlighted.isEmpty {
                            Text(String(localized: "This Season"))
                                .font(AppFont.headline)
                                .padding(.horizontal, AppSpacing.medium)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.small) {
                                    ForEach(highlighted) { template in
                                        Button {
                                            Haptics.shared.vibrateIfEnabled()
                                            onSelect(template.makeDraft())
                                            dismiss()
                                        } label: {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(template.emoji + " " + template.title)
                                                    .font(AppFont.subheadlineSemibold)
                                                    .foregroundStyle(Color(hex: template.textColor))
                                                    .lineLimit(2)
                                                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                                                Text(template.season.title)
                                                    .font(AppFont.caption)
                                                    .foregroundStyle(Color(hex: template.textColor).opacity(0.9))
                                                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                                            }
                                            .padding(AppSpacing.medium)
                                            .frame(width: 160, height: 96, alignment: .topLeading)
                                            .background {
                                                GalleryTemplateCardBackground(template: template)
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(template.title)
                                    }
                                }
                                .padding(.horizontal, AppSpacing.medium)
                            }
                        }

                        Text(selectedSeason?.title ?? String(localized: "All Events"))
                            .font(AppFont.headline)
                            .padding(.horizontal, AppSpacing.medium)

                        VStack {
                            ForEach(templates) { template in
                                CountdownDraftRow(countdown: template.makeDraft())
                                    .onTapGesture {
                                        Haptics.shared.vibrateIfEnabled()
                                        onSelect(template.makeDraft())
                                        dismiss()
                                    }
                                    .scaleEffect(0.9)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityHint(String(localized: "Uses this template for your countdown"))
                            }
                        }
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(themeManager.current.background)
            .navigationBarHidden(true)
        }
    }

    private func seasonChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? themeManager.current.primaryColor : themeManager.current.card)
                .foregroundStyle(selected ? Color.white : themeManager.current.textPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private extension Color {
    init(rgba: Int) {
        let a = Double((rgba >> 24) & 0xFF) / 255.0
        let r = Double((rgba >> 16) & 0xFF) / 255.0
        let g = Double((rgba >> 8) & 0xFF) / 255.0
        let b = Double(rgba & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a == 0 ? 1 : a)
    }
}
