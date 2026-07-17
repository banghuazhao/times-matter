//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SQLiteData
import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void

    @Dependency(\.themeManager) private var themeManager
    @Dependency(\.defaultDatabase) private var database
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step: Step = .welcome
    @State private var selectedTemplate: GalleryTemplate?
    @State private var title: String = ""
    @State private var date: Date = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    @State private var notificationsEnabled = false
    @State private var isSaving = false

    private enum Step: Int, CaseIterable {
        case welcome, pickEvent, customize, notify, done
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, AppSpacing.large)
                    .padding(.top, AppSpacing.medium)

                Group {
                    switch step {
                    case .welcome: welcomeStep
                    case .pickEvent: pickEventStep
                    case .customize: customizeStep
                    case .notify: notifyStep
                    case .done: doneStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(AppSpacing.large)
                .animation(reduceMotion ? nil : .smooth, value: step)

                bottomBar
                    .padding(.horizontal, AppSpacing.large)
                    .padding(.bottom, AppSpacing.large)
            }
            .background(themeManager.current.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .interactiveDismissDisabled()
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let progress = CGFloat(step.rawValue + 1) / CGFloat(Step.allCases.count)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.2))
                Capsule()
                    .fill(themeManager.current.primaryColor)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 6)
        .accessibilityLabel(String(localized: "Onboarding progress"))
        .accessibilityValue(Text("\(step.rawValue + 1) of \(Step.allCases.count)"))
    }

    private var welcomeStep: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 72))
                .foregroundStyle(themeManager.current.primaryColor)
                .accessibilityHidden(true)
            Text(String(localized: "Welcome to Times Matter"))
                .font(AppFont.title)
                .multilineTextAlignment(.center)
            Text(String(localized: "Track birthdays, deadlines, and milestones—and see what’s next in seconds."))
                .font(AppFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var pickEventStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "What are you counting down to?"))
                .font(AppFont.title2)
            Text(String(localized: "Pick a starting point—you can edit everything next."))
                .font(AppFont.body)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.medium) {
                    ForEach(GalleryTemplate.onboardingPicks) { template in
                        Button {
                            Haptics.shared.vibrateIfEnabled()
                            ButtonSound.playIfEnabled()
                            selectedTemplate = template
                            title = template.title
                            date = template.suggestedDate
                        } label: {
                            VStack(spacing: AppSpacing.small) {
                                Text(template.emoji)
                                    .font(.system(size: 36))
                                Text(template.title)
                                    .font(AppFont.subheadlineSemibold)
                                    .foregroundStyle(themeManager.current.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 110)
                            .padding(AppSpacing.small)
                            .background(
                                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                                    .fill(themeManager.current.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppCornerRadius.card)
                                            .stroke(
                                                selectedTemplate?.id == template.id
                                                    ? themeManager.current.primaryColor
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedTemplate?.id == template.id ? .isSelected : [])
                    }
                }
            }
        }
    }

    private var customizeStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            Text(String(localized: "Make it yours"))
                .font(AppFont.title2)
            TextField(String(localized: "Event title"), text: $title)
                .textFieldStyle(.roundedBorder)
                .font(AppFont.body)
            DatePicker(String(localized: "Date"), selection: $date, displayedComponents: [.date, .hourAndMinute])
                .tint(themeManager.current.primaryColor)

            if let template = selectedTemplate {
                CountdownDraftRow(countdown: template.makeDraft(title: title, date: date))
                    .scaleEffect(0.92)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            Spacer()
        }
    }

    private var notifyStep: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(themeManager.current.primaryColor)
                .accessibilityHidden(true)
            Text(String(localized: "Never miss the moment"))
                .font(AppFont.title2)
                .multilineTextAlignment(.center)
            Text(String(localized: "Enable reminders so we can nudge you before your event."))
                .font(AppFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Toggle(isOn: $notificationsEnabled) {
                Text(String(localized: "Enable reminders"))
                    .font(AppFont.body)
            }
            .tint(themeManager.current.primaryColor)
            .onChange(of: notificationsEnabled) { _, enabled in
                if enabled {
                    Task {
                        let granted = await ReminderNotificationManager.shared.requestPermission()
                        notificationsEnabled = granted
                    }
                }
            }
            Spacer()
        }
    }

    private var doneStep: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text(String(localized: "You’re all set"))
                .font(AppFont.title)
            Text(String(localized: "Your first countdown is ready. Tip: long-press a card for quick actions, or add a Home Screen widget."))
                .font(AppFont.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var bottomBar: some View {
        HStack(spacing: AppSpacing.medium) {
            if step != .welcome && step != .done {
                Button(String(localized: "Back")) {
                    Haptics.shared.vibrateIfEnabled()
                    goBack()
                }
                .buttonStyle(.appRect)
            }

            Spacer()

            Button(primaryButtonTitle) {
                Haptics.shared.vibrateIfEnabled()
                ButtonSound.playIfEnabled()
                Task { await advance() }
            }
            .buttonStyle(.appRectFilled)
            .disabled(!canAdvance || isSaving)
        }
    }

    private var primaryButtonTitle: String {
        switch step {
        case .welcome: String(localized: "Get Started")
        case .pickEvent, .customize, .notify: String(localized: "Continue")
        case .done: String(localized: "Start Counting")
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .welcome, .notify, .done: true
        case .pickEvent: selectedTemplate != nil
        case .customize: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    private func advance() async {
        switch step {
        case .welcome:
            step = .pickEvent
        case .pickEvent:
            step = .customize
        case .customize:
            step = .notify
        case .notify:
            isSaving = true
            await saveCountdown()
            isSaving = false
            step = .done
        case .done:
            onFinished()
        }
    }

    private func saveCountdown() async {
        guard let template = selectedTemplate else { return }
        var draft = template.makeDraft(title: title.trimmingCharacters(in: .whitespacesAndNewlines), date: date)
        if !notificationsEnabled {
            draft.reminder = .init(type: .noReminder)
        }

        withErrorReporting {
            let saved = try database.write { db in
                try Countdown.upsert { draft }.returning { $0 }.fetchOne(db)
            }
            if let saved {
                ReminderNotificationManager.shared.removeNotification(for: saved)
                ReminderNotificationManager.shared.scheduleNotification(for: saved)
                WidgetDataExporter.export(countdowns: [saved])
            }
        }
    }
}
