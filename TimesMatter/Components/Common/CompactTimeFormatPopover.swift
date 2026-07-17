//
// Created by Banghua Zhao on 11/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SwiftUI

struct CompactTimeFormatPopover: View {
    @Dependency(\.themeManager) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            // Header with icon
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(themeManager.current.primaryColor)
                
                Text("Compact Time Format")
                    .font(AppFont.headline)
                    .foregroundStyle(themeManager.current.textPrimary)
            }
            
            // Description
            Text("Automatically adjusts time display based on remaining duration for better readability.")
                .font(AppFont.subheadline)
                .foregroundStyle(themeManager.current.textSecondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Rules section
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                // Rule 1
                HStack(alignment: .top, spacing: AppSpacing.small) {
                    Image(systemName: "clock")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.current.primaryColor)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Less than 1 day")
                            .font(AppFont.subheadlineSemibold)
                            .foregroundStyle(themeManager.current.textPrimary)
                        
                        Text("Shows hours, minutes, or seconds")
                            .font(AppFont.caption)
                            .foregroundStyle(themeManager.current.textSecondary)
                    }
                    Spacer()
                }
                .padding(AppSpacing.small)
                .background(themeManager.current.secondaryGray.opacity(0.05))
                .clipShape(.rect(cornerRadius: AppCornerRadius.info))
                
                // Rule 2
                HStack(alignment: .top, spacing: AppSpacing.small) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.current.primaryColor)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("1 day or more")
                            .font(AppFont.subheadlineSemibold)
                            .foregroundStyle(themeManager.current.textPrimary)
                        
                        Text("Shows the selected time format")
                            .font(AppFont.caption)
                            .foregroundStyle(themeManager.current.textSecondary)
                    }
                    Spacer()
                }
                .padding(AppSpacing.small)
                .background(themeManager.current.secondaryGray.opacity(0.05))
                .clipShape(.rect(cornerRadius: AppCornerRadius.info))
            }
        }
        .padding(AppSpacing.large)
        .background(themeManager.current.card)
        .presentationCompactAdaptation(.popover)
    }
}

#Preview {
    CompactTimeFormatPopover()
        .padding()
        .background(Color(.systemGroupedBackground))
}
