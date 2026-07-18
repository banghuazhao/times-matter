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
    @State private var isShareCardPresented = false
    @State private var musicPlayer = EventMusicPlayer()
    
    var body: some View {
        let scale = model.isPreview ? 0.6 : 1.0
        let weights = model.countdown.layout.spacerWeights
        ZStack {
            backgroundLayer

            VStack {
                // Multiple spacers create weighted positions (e.g. 1:2 = upper middle).
                ForEach(0..<Int(weights.top), id: \.self) { _ in
                    Spacer(minLength: 0)
                }

                VStack(spacing: AppSpacing.large * scale) {
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
                        ForEach(Array(model.timeLeftComponentsFull.enumerated()), id: \.offset) { _, comp in
                            timerBlock(value: comp.value, label: comp.label, scale: scale)
                        }
                    }
                    .padding(.vertical, 12 * scale)
                    .padding(.horizontal, AppSpacing.medium * scale)
                    .modifier(CountdownGlassChrome(cornerRadius: 16 * scale))
                }
                .padding(.vertical, AppSpacing.medium * scale)

                ForEach(0..<Int(weights.bottom), id: \.self) { _ in
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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if let music = model.countdown.backgroundMusicName,
                       !music.isEmpty,
                       music != BackgroundMusicCatalog.none {
                        Button(
                            musicPlayer.isPlaying ? "Pause music" : "Play music",
                            systemImage: musicPlayer.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill"
                        ) {
                            Haptics.shared.vibrateIfEnabled()
                            musicPlayer.toggle()
                        }
                        .labelStyle(.iconOnly)
                        .accessibilityLabel(
                            musicPlayer.isPlaying
                                ? String(localized: "Pause background music")
                                : String(localized: "Play background music")
                        )
                    }

                    Button("Delete", systemImage: "trash") {
                        Haptics.shared.vibrateIfEnabled()
                        model.onTapDelete()
                    }
                    .labelStyle(.iconOnly)

                    Button("Share", systemImage: "square.and.arrow.up") {
                        Haptics.shared.vibrateIfEnabled()
                        isShareCardPresented = true
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityLabel(String(localized: "Share countdown card"))

                    Button("Edit", systemImage: "pencil") {
                        Haptics.shared.vibrateIfEnabled()
                        model.onTapEdit()
                    }
                    .labelStyle(.iconOnly)
                    .accessibilityLabel(String(localized: "Edit countdown"))
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
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
        .sheet(isPresented: $isShareCardPresented) {
            let relative = model.countdown.calculateRelativeTime(currentTime: model.timerService.currentTime)
            ShareCardSheet(
                countdown: model.countdown,
                relativeNumber: relative.number,
                relativeLabel: relative.label,
                backgroundColor: model.bgColor,
                textColor: model.textColor,
                backgroundImageName: model.countdown.backgroundImageName
            )
        }
        .onAppear {
            if !model.isPreview {
                musicPlayer.play(fileName: model.countdown.backgroundMusicName)
            }
        }
        .onDisappear {
            musicPlayer.stop()
        }
        .onChange(of: model.countdown.backgroundMusicName) { _, newValue in
            if !model.isPreview {
                musicPlayer.play(fileName: newValue)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            model.bgColor.ignoresSafeArea()

            if let videoPath = model.countdown.backgroundVideoPath,
               !videoPath.isEmpty,
               FileManager.default.fileExists(atPath: videoPath) {
                LoopingVideoPlayerView(path: videoPath, loopSeconds: 6)
                    .ignoresSafeArea()
            } else if let bgName = model.countdown.backgroundImageName, !bgName.isEmpty {
                if let uiImage = UIImage(contentsOfFile: bgName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else if UIImage(named: bgName, in: .main, with: nil) != nil {
                    Image(bgName, bundle: .main)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
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

}

private struct CountdownGlassChrome: ViewModifier {
    var cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            content
                .background(shape.fill(Color.black.opacity(0.12)))
                .glassEffect(.regular, in: shape)
        } else {
            content.background(shape.fill(Color.black.opacity(0.18)))
        }
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
