//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI
import SwiftUINavigation

@Observable
@MainActor
class CountdownDetailModel {
    var countdown: Countdown
    let isPreview: Bool
    let onDelete: (() -> Void)?

    @CasePathable
    enum Route {
        case edit(CountdownFormModel)
        case showDeleteAlert
    }

    var route: Route?

    @ObservationIgnored
    @Dependency(\.timerService) var timerService
    
    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database
    
    let isIphone = UIDevice.current.userInterfaceIdiom == .phone

    init(countdown: Countdown, isPreview: Bool = false, onDelete: (() -> Void)? = nil) {
        self.countdown = countdown
        self.isPreview = isPreview
        self.onDelete = onDelete
    }

    // New: Helper to compute time left with years
    var timeLeftComponentsFull: [(value: Int, label: String)] {
        let now = timerService.currentTime
        let targetDate = if countdown.repeatType == .nonRepeating {
            countdown.date
        } else {
            countdown.nextOccurrence ?? countdown.date
        }
        var interval = abs(targetDate.timeIntervalSince(now))
        let secondsInYear = 31536000.0 // 365 days
        let secondsInDay = 86400.0
        let secondsInHour = 3600.0
        let secondsInMinute = 60.0

        let years = Int(interval / secondsInYear)
        interval -= Double(years) * secondsInYear
        let days = Int(interval / secondsInDay)
        interval -= Double(days) * secondsInDay
        let hours = Int(interval / secondsInHour)
        interval -= Double(hours) * secondsInHour
        let minutes = Int(interval / secondsInMinute)
        interval -= Double(minutes) * secondsInMinute
        let seconds = Int(interval)

        var result: [(Int, String)] = []
        if years > 0 {
            result.append((years, String(localized: "years")))
        }
        if days > 0 || !result.isEmpty {
            result.append((days, String(localized: "days")))
        }
        if hours > 0 || !result.isEmpty {
            result.append((hours, String(localized: "hours")))
        }
        if minutes > 0 || !result.isEmpty {
            result.append((minutes, String(localized: "minutes")))
        }
        result.append((seconds, String(localized: "seconds")))
        return result
    }

    var bgColor: Color {
        Color(hex: countdown.backgroundColor)
    }

    var textColor: Color {
        Color(hex: countdown.textColor)
    }

    func onTapEdit() {
        route = .edit(
            CountdownFormModel(
                countdown: Countdown.Draft(countdown),
                onSave: { [weak self] newCountdown in
                    guard let self else { return }
                    countdown = newCountdown
                    route = nil
                }
            )
        )
    }
    
    func onTapDelete() {
        route = .showDeleteAlert
    }
    
    func onDeleteCountdown() {
        withErrorReporting {
            try database.write { db in
                try Countdown
                    .delete(countdown)
                    .execute(db)
            }
            
            ReminderNotificationManager.shared.removeNotification(for: countdown)
            
            onDelete?()
        }
    }
}

struct CountdownDetailView: View {
    @Bindable var model: CountdownDetailModel
    @Environment(\.dismiss) private var dismiss
    
    // Share state
    @State private var isShareSheetPresented = false
    @State private var shareImage: UIImage? = nil
    
    var body: some View {
        let scale = model.isPreview ? 0.6 : 1.0
        ZStack {
            if let bgName = model.countdown.backgroundImageName, !bgName.isEmpty {
                if let uiImage = UIImage(contentsOfFile: bgName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else {
                    if let _ = UIImage(named: bgName, in: .main, with: nil) {
                        Image(bgName, bundle: .main)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    } else {
                        model.bgColor.ignoresSafeArea()
                    }
                }
            } else {
                model.bgColor.ignoresSafeArea()
            }
            VStack {
                if model.countdown.layout != .top {
                    Spacer(minLength: 0)
                }
                VStack(spacing: AppSpacing.large * scale) {
                    // Title and date
                    VStack(spacing: 8 * scale) {

                        Text(model.countdown.title)
                            .font(.system(size: 28 * scale, weight: .bold))
                            .foregroundStyle(model.textColor)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                        Text(model.countdown.timeSummary)
                            .font(.system(size: 17 * scale))
                            .foregroundStyle(model.textColor)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                    }

                    HStack(spacing: 5 * scale) {
                        ForEach(Array(model.timeLeftComponentsFull.enumerated()), id: \ .offset) { _, comp in
                            timerBlock(value: comp.value, label: comp.label, scale: scale)
                        }
                    }
                    .padding(.vertical, 12 * scale)
                    .padding(.horizontal, AppSpacing.medium * scale)
                    .background(RoundedRectangle(cornerRadius: 16 * scale).fill(Color.black.opacity(0.18)))
                }
                .padding(.vertical, AppSpacing.medium * scale)
                if model.countdown.layout != .bottom {
                    Spacer(minLength: 0)
                }
            }
            .padding(.vertical, model.isIphone ? 0 : AppSpacing.large)
            .padding(.vertical, AppSpacing.large * scale)
            .padding(.horizontal, AppSpacing.medium * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            if !model.isPreview {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Delete", systemImage: "trash") {
                        Haptics.shared.vibrateIfEnabled()
                        model.onTapDelete()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.appWhiteCircular)

                    Button("Share", systemImage: "square.and.arrow.up") {
                        Haptics.shared.vibrateIfEnabled()
                        shareCountdownDetail()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.appWhiteCircular)

                    Button("Edit", systemImage: "pencil") {
                        Haptics.shared.vibrateIfEnabled()
                        model.onTapEdit()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.appWhiteCircular)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTint(.white)
        .sheet(item: $model.route.edit, id: \.self) { model in
            CountdownFormView(model: model)
        }
        .alert(
            "Delete ‘\(model.countdown.truncatedTitle)’?",
            isPresented: Binding($model.route.showDeleteAlert),
            actions: {
                Button("Delete", role: .destructive) {
                    Haptics.shared.vibrateIfEnabled()
                    model.onDeleteCountdown()
                }
                Button("Cancel", role: .cancel) {}
            }, message: {
                Text(String(localized: "This will permanently delete ‘\(model.countdown.truncatedTitle)’. This action cannot be undone. Are you sure you want to proceed?"))
            }
        )
        .sheet(isPresented: $isShareSheetPresented) {
            if let shareImage {
                ShareSheet(activityItems: [shareImage])
            }
        }
    }

    // Helper for timer block
    @ViewBuilder
    private func timerBlock(value: Int, label: String, scale: CGFloat) -> some View {
        VStack {
            Text("\(value)")
                .font(.system(size: 32 * scale, weight: .bold, design: .monospaced))
                .foregroundStyle(model.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
            Text(value == 1 && value == 0 ? String(label.dropLast()) : label)
                .font(.system(size: 13 * scale))
                .foregroundStyle(model.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(minWidth: 56 * scale)
    }

    // MARK: - Share helpers
    private func shareCountdownDetail() {
        // Render the ZStack as image (without navigation bar/toolbars)
        let renderer = ImageRenderer(content: shareContentView)
        renderer.scale = displayScale
        if let image = renderer.uiImage {
            self.shareImage = image
            self.isShareSheetPresented = true
        }
    }

    private var displayScale: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen
            .scale ?? 3
    }

    private var shareCanvasSize: CGSize {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        if let bounds = scene?.screen.bounds {
            return bounds.size
        }
        return CGSize(width: 390, height: 844)
    }

    // The content to share (the main ZStack)
    @ViewBuilder
    private var shareContentView: some View {
        ZStack {
            if let bgName = model.countdown.backgroundImageName, !bgName.isEmpty {
                if let uiImage = UIImage(contentsOfFile: bgName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else {
                    if let _ = UIImage(named: bgName, in: .main, with: nil) {
                        Image(bgName, bundle: .main)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    } else {
                        model.bgColor.ignoresSafeArea()
                    }
                }
            } else {
                model.bgColor.ignoresSafeArea()
            }
            VStack {
                if model.countdown.layout != .top {
                    Spacer(minLength: 0)
                }
                VStack(spacing: AppSpacing.large) {
                    VStack(spacing: AppSpacing.small) {
                        Text(model.countdown.title)
                            .font(AppFont.title)
                            .foregroundStyle(model.textColor)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        Text(model.countdown.timeSummary)
                            .font(AppFont.body)
                            .foregroundStyle(model.textColor)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    HStack(spacing: 5) {
                        ForEach(Array(model.timeLeftComponentsFull.enumerated()), id: \.offset) { _, comp in
                            timerBlock(value: comp.value, label: comp.label, scale: 1.0)
                        }
                    }
                    .padding(.vertical, AppSpacing.smallMedium)
                    .padding(.horizontal, AppSpacing.medium)
                    .background(RoundedRectangle(cornerRadius: AppCornerRadius.card).fill(Color.black.opacity(0.18)))
                }
                .padding(.vertical, AppSpacing.medium)
                if model.countdown.layout != .bottom {
                    Spacer(minLength: 0)
                }
            }
            .padding(.vertical, model.isIphone ? 0 : AppSpacing.large)
            .padding(.vertical, AppSpacing.large)
            .padding(.horizontal, AppSpacing.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: shareCanvasSize.width, height: shareCanvasSize.height)
    }
}

// MARK: - ShareSheet Representable
import UIKit
import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let dateComponents = DateComponents(year: 1, day: 0, hour: 1, minute: 4, second: 5)
    let futureDate = Calendar.current.date(byAdding: dateComponents, to: Date())!

    CountdownDetailView(
        model: CountdownDetailModel(
            countdown: Countdown(
                id: 1,
                title: "😀 Test",
                date: futureDate,
                backgroundColor: 0xFF6B9DCC,
                textColor: 0xFFFFFFFF,
                isFavorite: true,
                isArchived: false,
                repeatType: .nonRepeating,
                repeatTime: 1,
                compactTimeUnit: .days
            )
        )
    )
}
