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

    @CasePathable
    enum Route {
        case edit(CountdownFormModel)
    }

    var route: Route?

    @ObservationIgnored
    @Dependency(\.timerService) var timerService

    init(countdown: Countdown, isPreview: Bool = false) {
        self.countdown = countdown
        self.isPreview = isPreview
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
            result.append((years, "years"))
        }
        if days > 0 || !result.isEmpty {
            result.append((days, "days"))
        }
        if hours > 0 || !result.isEmpty {
            result.append((hours, "hours"))
        }
        if minutes > 0 || !result.isEmpty {
            result.append((minutes, "minutes"))
        }
        result.append((seconds, "seconds"))
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
}

struct CountdownDetailView: View {
    @Bindable var model: CountdownDetailModel
    @Environment(\.dismiss) private var dismiss

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
                Spacer(minLength: 0)
                VStack(spacing: AppSpacing.large * scale) {
                    // Title and date
                    VStack(spacing: 8 * scale) {

                        Text(model.countdown.title)
                            .font(.system(size: 32 * scale, weight: .bold))
                            .foregroundColor(model.textColor)
                            .multilineTextAlignment(.center)
                        Text(model.countdown.timeSummary)
                            .font(.system(size: 18 * scale))
                            .foregroundColor(model.textColor.opacity(0.9))
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
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.medium * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            if !model.isPreview {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.appCircular)

                    Button {
                        model.onTapEdit()
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.appCircular)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $model.route.edit, id: \.self) { model in
            CountdownFormView(model: model)
        }
    }

    // Helper for timer block
    @ViewBuilder
    private func timerBlock(value: Int, label: String, scale: CGFloat) -> some View {
        VStack {
            Text("\(value)")
                .font(.system(size: 32 * scale, weight: .bold, design: .monospaced))
                .foregroundColor(model.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(value == 1 && value == 0 ? String(label.dropLast()) : label)
                .font(AppFont.caption) // If AppFont.caption is not dynamic, consider scaling it as well
                .font(.system(size: 14 * scale))
                .foregroundColor(model.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(minWidth: 56 * scale)
    }
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
