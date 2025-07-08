import SwiftUI

struct CountdownRow: View {
    let countdown: Countdown

    var body: some View {
        HStack(spacing: 0) {
            // Icon
            Text(countdown.icon)
                .font(.system(size: 36))
                .frame(width: 50, height: 50)
                .background(Color.clear)
                .padding(.leading, 8)

            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(countdown.title)
                    .font(.system(size: 22, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color(hex: countdown.textColor))
                    .lineLimit(1)
                // Date
                Text(countdown.date, style: .date)
                    .font(.system(size: 14, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color(hex: countdown.textColor).opacity(0.8))
            }
            .padding(.leading, 8)
            .padding(.vertical, 8)

            Spacer()

            // Time left
            let time = countdown.compactRelativeTime
            VStack() {
                Text("\(time.number)")
                    .font(.system(size: 28, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color(hex: countdown.textColor))
                Text(time.label)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color(hex: countdown.textColor).opacity(0.8))
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: countdown.backgroundColor))
        )
        .shadow(color: countdown.backgroundColor.toColor, radius: 8, x: 0, y: 4)
    }
}

#if DEBUG
struct CountdownRow_Previews: PreviewProvider {
    static var previews: some View {
        let sample = Countdown(
            id: 1,
            title: "Test",
            icon: "😀",
            date: Date().addingTimeInterval(3600 * 8),
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFF,
            isFavorite: true,
            isArchived: false,
            repeatType: .none,
            customInterval: 1,
            compactTimeUnit: .days
        )
        VStack {
            CountdownRow(countdown: sample)
        }
        .padding()
    }
}
#endif 
