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

    var selectedTab: Tab = .textColor
    var selectedPhoto: PhotosPickerItem?

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
                                        .foregroundColor(model.selectedTab == tab ? model.primaryColor : .gray)
                                    Text(tab.rawValue)
                                        .font(AppFont.footnote)
                                        .foregroundColor(model.selectedTab == tab ? model.primaryColor : .gray)
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
                    Button {
                        Haptics.shared.vibrateIfEnabled()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.appCircular)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.shared.vibrateIfEnabled()
                        model.applyChanges()
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                    .buttonStyle(.appRect)
                }
            }
        }
    }

    private var backgroundImage: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                PhotosPicker(selection: Binding(
                    get: { model.selectedPhoto },
                    set: { model.selectPhoto($0) }
                ), matching: .images, photoLibrary: .shared()) { [model] in
                    if let backgroundImageName = model.countdown.backgroundImageName,
                       let uiImage = UIImage(contentsOfFile: backgroundImageName) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 66, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(model.primaryColor, lineWidth: 2)
                                )
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(model.primaryColor)
                                .offset(x: -4, y: 4)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 66, height: 100)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            )
                    }
                }

                ForEach(PredefinedImages.backgroundImages, id: \.self) { name in
                    ZStack(alignment: .topTrailing) {
                        Image(name, bundle: .main)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 66, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(model.countdown.backgroundImageName == name ? model.primaryColor : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                Haptics.shared.vibrateIfEnabled()
                                model.selectPredefinedImage(name)
                            }
                        if model.countdown.backgroundImageName == name {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(model.primaryColor)
                                .offset(x: -4, y: 4)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.medium)
        }
        .frame(height: 100)
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
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color)
                            .frame(width: 66, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(model.countdown.backgroundColor == color.hexIntWithAlpha ? model.primaryColor : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                Haptics.shared.vibrateIfEnabled()
                                model.updateBackgroundColor(color)
                            }

                        if model.countdown.backgroundColor == color.hexIntWithAlpha {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.3)))
                                .offset(x: -4, y: 4)
                        }
                    }
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
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color)
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(model.countdown.textColor == color.hexIntWithAlpha ? model.primaryColor : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                Haptics.shared.vibrateIfEnabled()
                                model.updateTextColor(color)
                            }

                        if model.countdown.textColor == color.hexIntWithAlpha {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.3)))
                                .offset(x: -4, y: 4)
                        }
                    }
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
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 8) {
                            Image(systemName: layout.iconName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(model.countdown.layout == layout ? model.primaryColor : .gray)
                            Text(layout.displayName)
                                .font(AppFont.footnote)
                                .foregroundColor(model.countdown.layout == layout ? model.primaryColor : .gray)
                        }
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(model.countdown.layout == layout ? model.primaryColor.opacity(0.12) : Color.gray.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(model.countdown.layout == layout ? model.primaryColor : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            model.updateLayout(layout)
                        }

                        if model.countdown.layout == layout {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(model.primaryColor)
                                .offset(x: -4, y: 4)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.medium)
        }
        .frame(height: 100)
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
