import SwiftUI

struct CountdownRow: View {
    let countdown: Countdown
    let currentTime: Date
    
    var body: some View {
        HStack(spacing: 0) {
            // Icon
            Text(countdown.icon)
                .font(.system(size: 36))
                .frame(width: 50, height: 50)
                .background(Color.clear)
                .padding(.leading, AppSpacing.small)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(countdown.title)
                    .font(AppFont.title2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color(hex: countdown.textColor))
                    .lineLimit(1)
                // Date
                Text(countdown.date, style: .date)
                    .font(AppFont.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color(hex: countdown.textColor).opacity(0.8))
            }
            .padding(.leading, AppSpacing.small)
            .padding(.vertical, AppSpacing.smallMedium)
            
            Spacer()
            
            VStack {
                let time = countdown.calculateRelativeTime(currentTime: currentTime)
                Text("\(time.number)")
                    .font(AppFont.title2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(countdown.textColor.toColor)
                
                Text(time.label)
                    .font(AppFont.subheadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(countdown.textColor.toColor.opacity(0.8))
            }
            .frame(width: 80)
            .frame(minHeight: 50)
            .padding(.vertical, AppSpacing.smallMedium)
            .padding(.horizontal, AppSpacing.smallMedium)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .fill(Color.black.opacity(0.3))
            )
        }
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.card)
                .fill(Color(hex: countdown.backgroundColor))
        )
        .shadow(color: countdown.backgroundColor.toColor.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#if DEBUG
struct CountdownRow_Previews: PreviewProvider {
    static var previews: some View {
        let sample = Countdown(
            id: 1,
            title: "Test",
            icon: "😀",
            date: Date(),
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFF,
            isFavorite: true,
            isArchived: false,
            repeatType: .none,
            customInterval: 1,
            compactTimeUnit: .days
        )
        VStack {
            CountdownRow(countdown: sample, currentTime: Date())
        }
        .padding()
    }
}
#endif 
