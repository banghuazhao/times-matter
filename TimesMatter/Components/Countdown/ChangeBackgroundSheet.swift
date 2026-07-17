import Dependencies
import PhotosUI
import SwiftUI

@Observable
@MainActor
class ChangeBackgroundSheetModel {
    var countdown: Countdown.Draft
    let onSelect: (Countdown.Draft) -> Void

    @ObservationIgnored
    @Dependency(\.themeManager) var themeManager

    @ObservationIgnored
    @Dependency(\.backgroundImageManager) var backgroundImageManager

    @ObservationIgnored
    @Dependency(\.purchaseManager) var purchaseManager

    var selectedTab: Tab = .image
    var selectedPhoto: PhotosPickerItem?
    var showPurchaseSheet = false

    var isPremium: Bool {
        purchaseManager.isPremiumUserPurchased
    }

    enum Tab: String, CaseIterable, Identifiable {
        case image = "Background Image"
        case backgroundColor = "Background Color"
        case textColor = "Text Color"
        case layout = "Layout"
        var id: String { rawValue }
        var iconName: String {
            switch self {
            case .image: return "photo.on.rectangle"
            case .backgroundColor: return "paintpalette"
            case .textColor: return "textformat"
            case .layout: return "rectangle.3.offgrid"
            }
        }

        var displayName: String {
            switch self {
            case .image:
                String(localized: "Background Image")
            case .backgroundColor:
                String(localized: "Background Color")
            case .textColor:
                String(localized: "Text Color")
            case .layout:
                String(localized: "Layout")
            }}
    }

    init(countdown: Countdown.Draft, onSelect: @escaping (Countdown.Draft) -> Void) {
        self.countdown = countdown
        self.onSelect = onSelect
    }

    var primaryColor: Color {
        themeManager.current.primaryColor
    }

    var previewCountdown: Countdown {
        countdown.mock
    }

    // MARK: - Actions

    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }

    func selectPhoto(_ photo: PhotosPickerItem?) {
        guard isPremium else {
            selectedPhoto = nil
            showPurchaseSheet = true
            return
        }
        selectedPhoto = photo
        if let photo {
            Task {
                await loadPhoto(photo)
            }
        }
    }

    func selectPredefinedImage(_ imageName: String) {
        removeOldImageIfNeed()
        countdown.backgroundImageName = imageName
    }

    func updateBackgroundColor(_ color: Color) {
        countdown.backgroundColor = color.hexIntWithAlpha
    }

    func updateTextColor(_ color: Color) {
        countdown.textColor = color.hexIntWithAlpha
    }

    func updateLayout(_ layout: LayoutType) {
        countdown.layout = layout
    }

    func useColorOnly() {
        countdown.backgroundImageName = nil
    }

    func applyChanges() {
        onSelect(countdown)
    }

    // MARK: - Private Methods

    private func loadPhoto(_ photo: PhotosPickerItem) async {
        guard let data = try? await photo.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            return
        }

        // Delete old custom image file if it exists
        removeOldImageIfNeed()

        if let imagePath = try? backgroundImageManager.saveCustomBackgroundImage(uiImage) {
            countdown.backgroundImageName = imagePath
        }
    }

    private func removeOldImageIfNeed() {
        if let oldImagePath = countdown.backgroundImageName {
            do {
                try backgroundImageManager.deleteCustomBackgroundImage(at: oldImagePath)
            } catch {
                // Don't show error for cleanup failures, just log them
                print("Failed to delete old custom background image: \(error.localizedDescription)")
            }
        }
    }
}

struct ChangeBackgroundSheet: View {
    @State var model: ChangeBackgroundSheetModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.large) {
                // Preview Countdown Detail View
                GeometryReader { geometry in
                    let height = geometry.size.height
                    let width = geometry.size.height * 0.55
                    HStack {
                        Spacer()
                        CountdownDetailView(
                            model: CountdownDetailModel(countdown: model.previewCountdown, isPreview: true)
                        )
                        .frame(width: width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
                        .contentShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
                        .padding(.horizontal, 20)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                switch model.selectedTab {
                case .image:
                    backgroundImage
                case .backgroundColor:
                    backgroundColor
                case .textColor:
                    textColor
                case .layout:
                    layout
                }

                // Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.smallMedium) {
                        ForEach(ChangeBackgroundSheetModel.Tab.allCases) { tab in
                            Button(action: {
                                Haptics.shared.vibrateIfEnabled()
                                model.selectTab(tab)
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: tab.iconName)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(model.selectedTab == tab ? model.primaryColor : .gray)
                                    Text(tab.displayName)
                                        .font(AppFont.footnote)
                                        .foregroundStyle(model.selectedTab == tab ? model.primaryColor : .gray)
                                        .lineLimit(2)
                                }
                                .frame(width: 70)
                                .padding(.vertical, 8)
                                .padding(.horizontal, AppSpacing.small)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(model.selectedTab == tab ? model.primaryColor.opacity(0.12) : Color.clear)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(model.themeManager.current.background)
            .navigationTitle("Customize Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") {
                        Haptics.shared.vibrateIfEnabled()
                        dismiss()
                    }
                    .labelStyle(.iconOnly)
                    .appToolbarStyle(iconOnly: true)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Haptics.shared.vibrateIfEnabled()
                        model.applyChanges()
                        dismiss()
                    }
                    .appToolbarStyle(prominent: true)
                }
            }
        }
    }

    private var backgroundImage: some View {
        let selectedImageName = model.countdown.backgroundImageName
        let accent = model.primaryColor
        let customThumb = selectedImageName.flatMap { UIImage(contentsOfFile: $0) }

        return VStack(alignment: .leading, spacing: AppSpacing.small) {
            if !model.isPremium {
                Label(String(localized: "Photo backgrounds require Premium"), systemImage: "crown.fill")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppSpacing.medium)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.small) {
                    if model.isPremium {
                        PhotosPicker(selection: Binding(
                            get: { model.selectedPhoto },
                            set: { model.selectPhoto($0) }
                        ), matching: .images) {
                            BackgroundThumb(
                                uiImage: customThumb,
                                assetName: nil,
                                isSelected: customThumb != nil,
                                accent: accent,
                                showsPhotoPlaceholder: customThumb == nil
                            )
                        }
                        .accessibilityLabel(String(localized: "Choose photo from library"))
                    } else {
                        Button {
                            model.showPurchaseSheet = true
                        } label: {
                            BackgroundThumb(
                                uiImage: nil,
                                assetName: nil,
                                isSelected: false,
                                accent: accent,
                                showsPhotoPlaceholder: true
                            )
                            .overlay {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Photo backgrounds, Premium"))
                    }

                    ForEach(PredefinedImages.backgroundImages, id: \.self) { name in
                        Button {
                            Haptics.shared.vibrateIfEnabled()
                            model.selectPredefinedImage(name)
                        } label: {
                            BackgroundThumb(
                                uiImage: nil,
                                assetName: name,
                                isSelected: selectedImageName == name,
                                accent: accent,
                                showsPhotoPlaceholder: false
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Background \(name)"))
                    }
                }
                .padding(.horizontal, AppSpacing.medium)
            }
            .frame(height: 100)
        }
        .sheet(isPresented: $model.showPurchaseSheet) {
            PurchaseSheet()
        }
    }

    @ViewBuilder
    private var backgroundColor: some View {
        // Use Color (No Image) button
        if model.countdown.backgroundImageName != nil {
            Button {
                Haptics.shared.vibrateIfEnabled()
                withAnimation {
                    model.useColorOnly()
                }
            } label: {
                Text("Use Color (No Image)")
            }
            .buttonStyle(.appRect)
        }

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                VStack(spacing: 12) {
                    ColorPicker("Pick Background Color", selection: Binding(
                        get: { model.countdown.backgroundColor.toColor },
                        set: { model.updateBackgroundColor($0) }
                    ))
                    .labelsHidden()
                }
                .frame(width: 60, height: 100)

                ForEach(PredefinedColors.backgroundColors, id: \.hexIntWithAlpha) { color in
                    Button {
                        Haptics.shared.vibrateIfEnabled()
                        model.updateBackgroundColor(color)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color)
                                .frame(width: 66, height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(model.countdown.backgroundColor == color.hexIntWithAlpha ? model.primaryColor : Color.clear, lineWidth: 2)
                                )

                            if model.countdown.backgroundColor == color.hexIntWithAlpha {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.3)))
                                    .offset(x: -4, y: 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
        }
        .frame(height: 100)
    }

    @ViewBuilder
    private var textColor: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [
                GridItem(.flexible(minimum: 50, maximum: 100)),
                GridItem(.flexible(minimum: 50, maximum: 100)),
            ], spacing: AppSpacing.small) {
                ColorPicker("Pick Text Color", selection: Binding(
                    get: { model.countdown.textColor.toColor },
                    set: { model.updateTextColor($0) }
                ))
                .labelsHidden()

                ForEach(PredefinedColors.textColors, id: \.hexIntWithAlpha) { color in
                    Button {
                        Haptics.shared.vibrateIfEnabled()
                        model.updateTextColor(color)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(model.countdown.textColor == color.hexIntWithAlpha ? model.primaryColor : Color.clear, lineWidth: 2)
                                )

                            if model.countdown.textColor == color.hexIntWithAlpha {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.3)))
                                    .offset(x: -4, y: 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
        }
        .frame(height: 100)
    }

    @ViewBuilder
    private var layout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(LayoutType.allCases, id: \.self) { layout in
                    Button {
                        Haptics.shared.vibrateIfEnabled()
                        model.updateLayout(layout)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: AppSpacing.small) {
                                Image(systemName: layout.iconName)
                                    .font(AppFont.title3)
                                    .symbolRenderingMode(AppSymbol.renderingMode)
                                    .foregroundStyle(model.countdown.layout == layout ? model.primaryColor : .secondary)
                                Text(layout.displayName)
                                    .font(AppFont.footnote)
                                    .foregroundStyle(model.countdown.layout == layout ? model.primaryColor : .secondary)
                            }
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(model.countdown.layout == layout ? model.primaryColor.opacity(0.12) : Color.secondary.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(model.countdown.layout == layout ? model.primaryColor : Color.clear, lineWidth: 2)
                            )

                            if model.countdown.layout == layout {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(model.primaryColor)
                                    .offset(x: -4, y: 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
        }
        .frame(height: 100)
    }
}

private struct BackgroundThumb: View {
    let uiImage: UIImage?
    let assetName: String?
    let isSelected: Bool
    let accent: Color
    let showsPhotoPlaceholder: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let assetName {
                    Image(assetName, bundle: .main)
                        .resizable()
                        .scaledToFill()
                } else if showsPhotoPlaceholder {
                    Color.secondary.opacity(0.2)
                        .overlay {
                            Image(systemName: "photo")
                                .font(AppFont.title3)
                                .foregroundStyle(.secondary)
                        }
                } else {
                    Color.secondary.opacity(0.15)
                }
            }
            .frame(width: 66, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? accent : Color.clear, lineWidth: 2)
            )

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(accent)
                    .offset(x: -4, y: 4)
            }
        }
    }
}

#Preview {
    ChangeBackgroundSheet(
        model: ChangeBackgroundSheetModel(
            countdown: CountdownStore.testSecond
        ) { countdown in
            print("Selected countdown: \(countdown)")
        }
    )
}
