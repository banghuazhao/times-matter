//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

@Observable
@MainActor
class CountdownDetailModel {
    let countdown: Countdown
    @ObservationIgnored
    @Dependency(\.timerService) var timerService
    
    init(countdown: Countdown) {
        self.countdown = countdown
    }
    
    // New: Helper to compute time left with years
    var timeLeftComponentsFull: [(value: Int, label: String)] {
        let now = timerService.currentTime
        let targetDate = if countdown.repeatType == .nonRepeating {
            countdown.date
        }  else {
            (countdown.nextOccurrence ?? countdown.date)
        }
        var interval = max(targetDate.timeIntervalSince(now), 0)
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
}

struct CountdownDetailView: View {
    @State var model: CountdownDetailModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            model.bgColor.ignoresSafeArea()
            VStack {
                Spacer(minLength: 0)
                VStack(spacing: 32) {
                    // Title and date
                    VStack(spacing: 8) {
                        Text(model.countdown.icon)
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text(model.countdown.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(model.textColor)
                            .multilineTextAlignment(.center)
                        Text(model.countdown.timeSummary)
                            .font(.system(size: 18))
                            .foregroundColor(model.textColor.opacity(0.9))
                    }
                    // Countdown timer
                    HStack(spacing: 5) {
                        ForEach(Array(model.timeLeftComponentsFull.enumerated()), id: \ .offset) { idx, comp in
                            timerBlock(value: comp.value, label: comp.label)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, AppSpacing.medium)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.18)))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { /* Share action */ }) {
                    Image(systemName: "square.and.arrow.up")
                }
                Button(action: { /* Edit action */ }) {
                    Text("Edit")
                }
                Button(action: { /* More action */ }) {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .tint(model.textColor)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTint(UIColor(model.textColor))
    }
    
    // Helper for timer block
    @ViewBuilder
    private func timerBlock(value: Int, label: String) -> some View {
        VStack {
            Text("\(value)")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(model.textColor)
            Text(value == 1 && value == 0 ? String(label.dropLast()) : label)
                .font(AppFont.caption)
                .foregroundColor(model.textColor)
        }
        .frame(minWidth: 56)
    }
}

#Preview {
    let dateComponents = DateComponents(year: 1, day: 0, hour: 1, minute: 4, second: 5)
    let futureDate = Calendar.current.date(byAdding: dateComponents, to: Date())!
    
    CountdownDetailView(
        model: CountdownDetailModel(
            countdown: Countdown(
                id: 1,
                title: "Test",
                icon: "😀",
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
