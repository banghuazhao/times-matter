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
    
    // Helper to compute time left
    var timeLeftComponents: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let now = timerService.currentTime
        let targetDate = countdown.repeatType == .nonRepeating ? countdown.date : (countdown.nextOccurrence ?? countdown.date)
        let interval = max(targetDate.timeIntervalSince(now), 0)
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return (days, hours, minutes, seconds)
    }
    
    var formattedDate: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d, yyyy h:mm a"
        return df.string(from: countdown.date)
    }
    
    var bgColor: Color {
        Color(hex: countdown.backgroundColor)
    }
    
    var textColor: Color {
        Color(hex: countdown.textColor)
    }
    
    var repeatDescription: String? {
        switch countdown.repeatType {
        case .weekly:
            let weekday = Calendar.current.component(.weekday, from: countdown.date)
            let weekdayName = Calendar.current.weekdaySymbols[weekday - 1]
            return "Countdown will repeat weekly on \(weekdayName)."
        case .daily:
            return "Countdown will repeat daily."
        case .monthly:
            return "Countdown will repeat monthly."
        case .yearly:
            return "Countdown will repeat yearly."
        case .customDays:
            return "Countdown will repeat every \(countdown.customInterval) days."
        case .customWeeks:
            return "Countdown will repeat every \(countdown.customInterval) weeks."
        case .customMonths:
            return "Countdown will repeat every \(countdown.customInterval) months."
        case .customYears:
            return "Countdown will repeat every \(countdown.customInterval) years."
        default:
            return nil
        }
    }
}

struct CountdownDetailView: View {
    @State var model: CountdownDetailModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            model.bgColor.ignoresSafeArea()
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
                    Text(model.formattedDate)
                        .font(.system(size: 18))
                        .foregroundColor(model.textColor.opacity(0.9))
                }
                // Countdown timer
                HStack(spacing: 0) {
                    timerBlock(value: model.timeLeftComponents.days, label: "days")
                    timerBlock(value: model.timeLeftComponents.hours, label: "hours")
                    timerBlock(value: model.timeLeftComponents.minutes, label: "minutes")
                    timerBlock(value: model.timeLeftComponents.seconds, label: "seconds")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.18)))
                // Repeat info
                if let repeatDesc = model.repeatDescription {
                    Text(repeatDesc)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(.top, 16)
                }
                Spacer()
            }
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
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.85))
        }
        .frame(minWidth: 56)
    }
}
