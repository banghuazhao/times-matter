//
// Created by Banghua Zhao on 13/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import Dependencies

struct GallerySheet: View {
    let onSelect: (Countdown.Draft) -> Void
    @Environment(\.dismiss) var dismiss
    @Dependency(\.themeManager) var themeManager

    private var primaryColor: Color {
        themeManager.current.primaryColor
    }

    private var textPrimaryColor: Color {
        themeManager.current.textPrimary
    }

    private var backgroundColor: Color {
        themeManager.current.background
    }

    // Predefined gallery templates
    private var galleryTemplates: [Countdown.Draft] {
        [
            // Birthday templates
            .init(
                title: String(localized: "🎂 Birthday"),
                date: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(),
                categoryID: 2,
                backgroundColor: 0xFF6B9DCC,
                textColor: 0xFFFFFFFF,
                repeatType: .yearly,
                backgroundImageName: "predefined_birthday",
                reminder: .init(type: .everyYear, time: .oneDayEarly, soundName: "Happy Birthday.mp3")
            ),
            .init(
                title: String(localized: "🎉 Anniversary"),
                date: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
                categoryID: 1,
                backgroundColor: 0xE74C3CCC,
                textColor: 0xFFFFFFFF,
                repeatType: .yearly,
                backgroundImageName: "predefined_relationship",
                reminder: .init(type: .everyYear, time: .oneDayEarly, soundName: "Mindful Chimes.mp3")
            ),
            .init(
                title: String(localized: "🏖️ Vacation"),
                date: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                categoryID: nil,
                backgroundColor: 0x2ECC71CC,
                textColor: 0xFFFFFFFF,
                repeatType: .nonRepeating,
                backgroundImageName: "predefined_taupo"
            ),
            .init(
                title: String(localized: "🦷 Dentist Appointment"),
                date: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                categoryID: 4,
                backgroundColor: 0x1ABC9CCC,
                textColor: 0xFFFFFFFF,
                repeatType: .yearly,
                repeatTime: 2,
                backgroundImageName: "predefined_shakespeare",
                reminder: .init(type: .everyYear, time: .oneDayEarly, soundName: "Focus Breeze.mp3")
            ),
            .init(
                title: String(localized: "🚗 Car Service"),
                date: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                categoryID: 4,
                backgroundColor: 0xE67E22CC,
                textColor: 0xFFFFFFFF,
                repeatType: .yearly,
                backgroundImageName: "predefined_tree_sister",
                reminder: .init(type: .everyYear, time: .oneDayEarly, soundName: "Retro Ringer.mp3")
            ),
            .init(
                title: String(localized: "📅 Project Deadline"),
                date: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date(),
                categoryID: 3,
                backgroundColor: 0x34495ECC,
                textColor: 0xFFFFFFFF,
                repeatType: .nonRepeating,
                backgroundImageName: "predefined_mercer_bay"
            ),
            .init(
                title: String(localized: "🌟 Special Event"),
                date: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                categoryID: nil,
                backgroundColor: 0x9B59B6CC,
                textColor: 0xFFFFFFFF,
                repeatType: .nonRepeating,
                backgroundImageName: "predefined_star"
            ),
            .init(
                title: String(localized: "🌅 Sunrise"),
                date: Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 7, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents) ?? Date(),
                categoryID: nil,
                backgroundColor: 0xFF6B9DCC,
                textColor: 0xFFFFFFFF,
                isFavorite: false,
                repeatType: .daily,
                backgroundImageName: "predefined_mt_eden",
                reminder: .init(type: .everyDay, time: .fiveMinutesEarly)
            ),
            .init(
                title: String(localized: "🌅 Sunset"),
                date: Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 19, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents) ?? Date(),
                categoryID: nil,
                backgroundColor: 0xFF6B9DCC,
                textColor: 0xFFFFFFFF,
                isFavorite: false,
                repeatType: .daily,
                backgroundImageName: "predefined_mt_eden",
                reminder: .init(type: .everyDay, time: .fiveMinutesEarly)
            )
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Events Gallery")
                        .font(AppFont.title2)
                        .foregroundColor(textPrimaryColor)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)

                // Content
                ScrollView {
                    VStack {
                        ForEach(galleryTemplates, id: \.title) { template in
                            CountdownDraftRow(countdown: template)
                                .onTapGesture {
                                    onSelect(template)
                                }
                                .scaleEffect(0.9)
                        }
                    }
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.bottom, 20)
                }
            }
            .background(backgroundColor)
            .navigationBarHidden(true)
        }
    }
}
