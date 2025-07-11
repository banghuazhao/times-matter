import SwiftUI
import Dependencies
import SharingGRDB

struct CountdownRow: View {
    let countdown: Countdown
    
    @Dependency(\.timerService) var timerService
    @FetchAll(Category.all, animation: .default) var allCategories
    
    var body: some View {
        HStack(spacing: 0) {
            // Icon
            Text(countdown.icon)
                .font(.system(size: 32))
                .padding(.leading, AppSpacing.smallMedium)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(countdown.title)
                    .font(AppFont.title3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color(hex: countdown.textColor))
                    .lineLimit(1)
                // Date
                HStack {
                    Text(countdown.date, style: .date)
                        .font(AppFont.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(Color(hex: countdown.textColor).opacity(0.8))
                    
                    if countdown.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(AppFont.caption)
                            .foregroundColor(.red)
                    }
                    
                    if let categoryID = countdown.categoryID,
                       let category = allCategories.first(where: { $0.id == categoryID }) {
                        Text(category.icon)
                            .font(AppFont.caption)
                    }
                    
                }
            }
            .padding(.leading, AppSpacing.small)
            .padding(.vertical, AppSpacing.smallMedium)
            
            Spacer()
            
            VStack {
                let time = countdown.calculateRelativeTime(currentTime: timerService.currentTime)
                Text(time.number)
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
            .frame(minHeight: 46)
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
            repeatType: .nonRepeating,
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
