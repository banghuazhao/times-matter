import SwiftUI
import Dependencies
import SharingGRDB

struct CountdownRow: View {
    let countdown: Countdown
    
    @Dependency(\.timerService) var timerService
    @FetchAll(Category.all, animation: .default) var allCategories
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(countdown.title)
                    .font(AppFont.title3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color(hex: countdown.textColor))
                    .lineLimit(1)
                // Secondary description: always show timeSummary
                Text(countdown.timeSummary)
                    .font(AppFont.caption)
                    .foregroundColor(Color(hex: countdown.textColor))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.leading, AppSpacing.medium)
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
            Group {
                if let bgName = countdown.backgroundImageName, !bgName.isEmpty {
                    // Check if it's a custom image (file path)
                    if let uiImage = UIImage(contentsOfFile: bgName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // Try to load as predefined image from bundle
                        if let _ = UIImage(named: bgName, in: .main, with: nil) {
                            Image(bgName, bundle: .main)
                                .resizable()
                                .scaledToFill()
                        } else {
                            // Fallback to background color if image not found
                            Color(hex: countdown.backgroundColor)
                        }
                    }
                } else {
                    Color(hex: countdown.backgroundColor)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .shadow(color: countdown.backgroundColor.toColor.opacity(0.08), radius: 8, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }
}

#if DEBUG
struct CountdownRow_Previews: PreviewProvider {
    static var previews: some View {
        let sample = Countdown(
            id: 1,
            title: "😀 Test",
            date: Date(),
            backgroundColor: 0xFF6B9DCC,
            textColor: 0xFFFFFFFF,
            isFavorite: true,
            isArchived: false,
            repeatType: .nonRepeating,
            repeatTime: 1,
            compactTimeUnit: .days
        )
        VStack {
            CountdownRow(countdown: sample)
        }
        .padding()
    }
}
#endif 
