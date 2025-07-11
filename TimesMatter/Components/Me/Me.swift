//
// Created by Banghua Zhao on 08/07/2025
// Copyright Apps Bay Limited. All rights reserved.
//
  

import SwiftUI
import Dependencies
import SharingGRDB
import MoreApps

struct MeView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("userName") private var userName: String = String(localized: "Your Name")
    @AppStorage("userAvatar") private var userAvatar: String = "😀"
    @State private var showPurchaseSheet = false
    @State private var showEmojiPicker = false
    @Dependency(\.themeManager) var themeManager
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    // Me Section
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        HStack(spacing: AppSpacing.medium) {
                            Button(action: { showEmojiPicker = true }) {
                                Text(userAvatar)
                                    .font(.system(size: 40))
                                    .frame(width: 50, height: 50)
                                    .background(themeManager.current.card)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .sheet(isPresented: $showEmojiPicker) {
                                EmojiPickerView(selectedEmoji: $userAvatar, title: "Choose your avatar")
                                .presentationDetents([.medium])
                                .presentationDragIndicator(.visible)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Your Name", text: $userName)
                                    .font(AppFont.headline)
                                    .fontWeight(.bold)
                                    .padding(AppSpacing.small)
                                    .background(themeManager.current.background)
                                    .cornerRadius(AppCornerRadius.button)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        // Stats Section hardcoded for now
                        HStack(spacing: AppSpacing.small) {
                            VStack(spacing: 8) {
                                HStack {
                                    VStack {
                                        Text("3/5")
                                            .font(.headline)
                                        Text("Categories")
                                            .font(.caption)
                                    }
                                    Divider()
                                    VStack {
                                        Text("12")
                                            .font(.headline)
                                        Text("Countdowns")
                                            .font(.caption)
                                    }
                                    Divider()
                                    VStack {
                                        Text("7")
                                            .font(.headline)
                                        Text("Reminders")
                                            .font(.caption)
                                    }
                                    
                                }
                                .padding(.top, 8)
                                // Placeholder for purchase button
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        // Show purchase sheet placeholder
                                    }) {
                                        Text("Upgrade to Premium")
                                            .font(.body)
                                            .foregroundColor(.blue)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(10)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(.top, AppSpacing.small)
                    }
                    .appCardStyle(theme: themeManager.current)
                    .padding(.horizontal)
                    
                    //more feature section
                    moreFeatureView
                    // Others section
                    othersView(openURL: openURL)
                    Spacer().frame(height: 10)

                    // App info section (moved below othersView)
                    VStack(spacing: 4) {
                        Text("Times Matter  |  Smart Reminders")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        Button {
                            if let url = URL(string: "https://apps.apple.com/app/id6748243795") {
                                openURL(url)
                            }
                        } label: {
                            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")  Check for Updates")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .underline()
                        }
                    }
                .padding(.top, 10)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Me")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func statView(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private func othersView(openURL: OpenURLAction) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Others")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 24) {
                NavigationLink(destination: MoreAppsView()) {
                    moreItem(icon: "storefront", title: "More Apps")
                }
                if let url = URL(string: "https://itunes.apple.com/app/id6748243795?action=write-review") {
                    Button {
                        openURL(url)
                    } label: {
                        moreItem(icon: "star.fill", title: "Rate Us")
                    }
                }
                Button {
                    let email = SupportEmail()
                    email.send(openURL: openURL)
                } label: {
                    moreItem(icon: "envelope.fill", title: "Feedback")
                }
                if let appURL = URL(string: "https://itunes.apple.com/app/id6748243795") {
                    ShareLink(item: appURL) {
                        moreItem(icon: "square.and.arrow.up", title: "Share App")
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func moreItem(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var moreFeatureView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(String(localized: "More Features"))
                .appSectionHeader(theme: themeManager.current)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppSpacing.large) {
                NavigationLink(destination: SettingView()) {
                    featureItem(icon: "gear", title: String(localized: "Settings"))
                }
                NavigationLink(destination: Text("Coming Soon")) {
                    featureItem(icon: "bell", title: String(localized: "Reminders"))
                }
                NavigationLink(destination: ThemeColorView()) {
                    featureItem(icon: "paintbrush.fill", title: String(localized: "Theme Color"))
                }
            }
        }
        .padding(.horizontal)
    }

    private func featureItem(icon: String, title: String) -> some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeManager.current.primaryColor)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(themeManager.current.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.small)
        .background(themeManager.current.card)
        .cornerRadius(AppCornerRadius.card)
        .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: AppShadow.card.x, y: AppShadow.card.y)
    }
}


#Preview {
    MeView()
}

struct SupportEmail {
    let toAddress = "appsbayarea@gmail.com"
    let subject: String = String(localized: "\("Times Matter") - \("Feedback")")
    var body: String { """
      Application Name: \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown")
      iOS Version: \(UIDevice.current.systemVersion)
      Device Model: \(UIDevice.current.model)
      App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "no app version")
      App Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "no app build version")

      \(String(localized: "Please describe your issue below"))
      ------------------------------------

    """ }

    func send(openURL: OpenURLAction) {
        let replacedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let replacedBody = body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "mailto:\(toAddress)?subject=\(replacedSubject)&body=\(replacedBody)"
        guard let url = URL(string: urlString) else { return }
        openURL(url) { accepted in
            if !accepted { // e.g. Simulator
                print("Device doesn't support email.\n \(body)")
            }
        }
    }
}
