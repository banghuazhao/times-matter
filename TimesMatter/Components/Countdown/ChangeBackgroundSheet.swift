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

    var selectedTab: Tab = .textColor
    var selectedPhoto: PhotosPickerItem?

    enum Tab: String, CaseIterable, Identifiable {
        case image = "Background Image"
        case backgroundColor = "Background Color"
        case textColor = "Text Color"
        case icon = "Icon"
        case layout = "Layout"
        var id: String { rawValue }
        var iconName: String {
            switch self {
            case .image: return "photo.on.rectangle"
            case .backgroundColor: return "paintpalette"
            case .textColor: return "textformat"
            case .icon: return "face.smiling"
            case .layout: return "rectangle.3.offgrid"
            }
        }
    }

    // Predefined images from the Backgrounds folder
    let predefinedImages = [
        "aurora",
        "holiday",
        "mercer_bay",
        "mt_cook",
        "mt_eden",
        "shakespeare",
        "wanaka_tree",
        "star",
        "taupo",
        "tekapo",
        "tree_sister",
        "birthday",
        "relationship",
        "history",
    ]

    // Predefined background colors
    let predefinedColors: [(name: String, color: Color)] = [
        ("Blue", Color(hex: 0xFF6B9DCC)),
        ("Green", Color(hex: 0xFF2ECC71CC)),
        ("Purple", Color(hex: 0xFF9B59B6CC)),
        ("Orange", Color(hex: 0xFFE67E22CC)),
        ("Red", Color(hex: 0xFFE74C3CCC)),
        ("Pink", Color(hex: 0xFFE91E63CC)),
        ("Teal", Color(hex: 0xFF4ECDC4CC)),
        ("Yellow", Color(hex: 0xFFF1C40FCC)),
        ("Brown", Color(hex: 0xFF8B4513CC)),
        ("Gray", Color(hex: 0xFF95A5A6CC)),
        ("Dark Blue", Color(hex: 0xFF34495ECC)),
        ("Dark Green", Color(hex: 0xFF27AE60CC)),
        ("Dark Purple", Color(hex: 0xFF8E44ADCC)),
        ("Dark Red", Color(hex: 0xFFC0392BCC)),
        ("Black", Color(hex: 0xFF2C3E50CC)),
    ]

    // Predefined text colors
    let predefinedTextColors: [(name: String, color: Color)] = [
        ("White", Color(hex: 0xFFFFFFFF)),
        ("Black", Color(hex: 0x000000FF)),
        ("Light Gray", Color(hex: 0xD3D3D3FF)),
        ("Blue", Color(hex: 0x007AFFFF)),
        ("Green", Color(hex: 0x34C759FF)),
        ("Purple", Color(hex: 0xAF5CF7FF)),
        ("Orange", Color(hex: 0xFF9500FF)),
        ("Red", Color(hex: 0xFF3B30FF)),
        ("Pink", Color(hex: 0xFF2D92FF)),
        ("Teal", Color(hex: 0x5AC8FAFF)),
        ("Yellow", Color(hex: 0xFFCC00FF)),
        ("Brown", Color(hex: 0x8B4513FF)),
        ("Gold", Color(hex: 0xFFD700FF)),
        ("Silver", Color(hex: 0xC0C0C0FF)),
        ("Cyan", Color(hex: 0x00FFFFFF)),
        ("Magenta", Color(hex: 0xFF00FFFF)),
        ("Lime", Color(hex: 0x32CD32FF)),
        ("Navy", Color(hex: 0x000080FF)),
        ("Maroon", Color(hex: 0x800000FF)),
    ]
    
    // Predefined emojis
    let predefinedEmojis: [(name: String, emoji: String)] = [
        ("Clock", "⏰"),
        ("Calendar", "📅"),
        ("Heart", "❤️"),
        ("Star", "⭐"),
        ("Cake", "🎂"),
        ("Gift", "🎁"),
        ("Party", "🎉"),
        ("Fireworks", "🎆"),
        ("Balloon", "🎈"),
        ("Music", "🎵"),
        ("Car", "🚗"),
        ("Plane", "✈️"),
        ("Ship", "🚢"),
        ("Train", "🚂"),
        ("Bike", "🚲"),
        ("House", "🏠"),
        ("Office", "🏢"),
        ("School", "🎓"),
        ("Work", "💼"),
        ("Study", "📚"),
        ("Game", "🎮"),
        ("Movie", "🎬"),
        ("Book", "📖"),
        ("Phone", "📱"),
        ("Computer", "💻"),
        ("Camera", "📷"),
        ("Food", "🍕"),
        ("Drink", "☕"),
        ("Sport", "⚽"),
        ("Fitness", "💪"),
        ("Nature", "🌲"),
        ("Beach", "🏖️"),
        ("Mountain", "⛰️"),
        ("Sun", "☀️"),
        ("Moon", "🌙"),
        ("Rainbow", "🌈"),
        ("Flower", "🌸"),
        ("Tree", "🌳"),
        ("Animal", "🐶"),
        ("Bird", "🐦"),
        ("Fish", "🐠"),
        ("Bug", "🐛"),
        ("Robot", "🤖"),
        ("Alien", "👽"),
        ("Ghost", "👻"),
        ("Wizard", "🧙‍♂️"),
        ("Princess", "👸"),
        ("King", "👑"),
        ("Crown", "👑"),
        ("Diamond", "💎"),
        ("Money", "💰"),
        ("Shopping", "🛍️"),
        ("Love", "💕"),
        ("Friendship", "🤝"),
        ("Family", "👨‍👩‍👧‍👦"),
        ("Baby", "👶"),
        ("Child", "🧒"),
        ("Adult", "👨"),
        ("Elder", "👴"),
        ("Doctor", "👨‍⚕️"),
        ("Teacher", "👨‍🏫"),
        ("Artist", "🎨"),
        ("Scientist", "🔬"),
        ("Engineer", "⚙️"),
        ("Chef", "👨‍🍳"),
        ("Farmer", "👨‍🌾"),
        ("Police", "👮"),
        ("Firefighter", "👨‍🚒"),
        ("Astronaut", "👨‍🚀"),
        ("Pilot", "👨‍✈️"),
        ("Sailor", "👨‍✈️"),
        ("Soldier", "👨‍✈️"),
        ("Dancer", "💃"),
        ("Singer", "🎤"),
        ("Actor", "🎭"),
        ("Writer", "✍️"),
        ("Photographer", "📸"),
        ("Designer", "🎨"),
        ("Programmer", "💻"),
        ("Gamer", "🎮"),
        ("Athlete", "🏃"),
        ("Yoga", "🧘"),
        ("Meditation", "🧘‍♀️"),
        ("Prayer", "🙏"),
        ("Religion", "⛪"),
        ("Holiday", "🎄"),
        ("Birthday", "🎂"),
        ("Wedding", "💒"),
        ("Anniversary", "💍"),
        ("Graduation", "🎓"),
        ("Retirement", "🏖️"),
        ("Vacation", "✈️"),
        ("Travel", "🗺️"),
        ("Adventure", "🗺️"),
        ("Exploration", "🔍"),
        ("Discovery", "🔬"),
        ("Innovation", "💡"),
        ("Success", "🏆"),
        ("Achievement", "🎯"),
        ("Goal", "🎯"),
        ("Dream", "💭"),
        ("Hope", "✨"),
        ("Faith", "🙏"),
        ("Courage", "💪"),
        ("Strength", "💪"),
        ("Wisdom", "🧠"),
        ("Knowledge", "📚"),
        ("Learning", "🎓"),
        ("Growth", "🌱"),
        ("Change", "🔄"),
        ("Progress", "📈"),
        ("Future", "🔮"),
        ("Past", "📜"),
        ("Present", "🎁"),
        ("Time", "⏱️"),
        ("Eternity", "♾️"),
        ("Infinity", "♾️"),
        ("Moment", "⚡"),
        ("Second", "⏱️"),
        ("Minute", "⏰"),
        ("Hour", "🕐"),
        ("Day", "📅"),
        ("Week", "📆"),
        ("Month", "📅"),
        ("Year", "📅"),
        ("Decade", "📅"),
        ("Century", "📅"),
        ("Millennium", "📅"),
    ]

    init(countdown: Countdown.Draft, onSelect: @escaping (Countdown.Draft) -> Void) {
        self.countdown = countdown
        self.onSelect = onSelect
    }

    var isCustomImageSelected: Bool {
        if let bgName = countdown.backgroundImageName, !predefinedImages.contains(bgName), !bgName.isEmpty {
            return true
        }
        return false
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

    func removeCustomImage() {
        countdown.backgroundImageName = nil
    }

    func updateBackgroundColor(_ color: Color) {
        countdown.backgroundColor = color.hexIntWithAlpha
    }

    func updateTextColor(_ color: Color) {
        countdown.textColor = color.hexIntWithAlpha
    }
    
    func updateIcon(_ emoji: String) {
        countdown.icon = emoji
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
              let uiImage = UIImage(data: data) else { return }

        // Delete old custom image file if it exists
        removeOldImageIfNeed()

        // Resize image if needed (max 1080px)
        let resizedImage = uiImage.resizedToFit(maxDimension: 1080)
        // Save to temp directory and set backgroundImageName to a unique path
        let filename = "custom_bg_\(UUID().uuidString).jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        if let jpegData = resizedImage.jpegData(compressionQuality: 0.95) {
            try? jpegData.write(to: url)
            countdown.backgroundImageName = url.path
        }
    }

    private func removeOldImageIfNeed() {
        if let oldImagePath = countdown.backgroundImageName,
           oldImagePath.hasPrefix(FileManager.default.temporaryDirectory.path),
           oldImagePath.contains("custom_bg_") {
            try? FileManager.default.removeItem(atPath: oldImagePath)
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
                case .icon:
                    icon
                case .layout:
                    EmptyView()
                }

                // Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.smallMedium) {
                        ForEach(ChangeBackgroundSheetModel.Tab.allCases) { tab in
                            Button(action: {
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
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.appCircular)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
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

                ForEach(model.predefinedImages, id: \.self) { name in
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
                model.useColorOnly()
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

                ForEach(model.predefinedColors, id: \.name) { colorOption in
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorOption.color)
                            .frame(width: 66, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(model.countdown.backgroundColor == colorOption.color.hexIntWithAlpha ? model.primaryColor : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                model.updateBackgroundColor(colorOption.color)
                            }

                        if model.countdown.backgroundColor == colorOption.color.hexIntWithAlpha {
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

                ForEach(model.predefinedTextColors, id: \.name) { colorOption in
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorOption.color)
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(model.countdown.textColor == colorOption.color.hexIntWithAlpha ? model.primaryColor : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                model.updateTextColor(colorOption.color)
                            }

                        if model.countdown.textColor == colorOption.color.hexIntWithAlpha {
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
    private var icon: some View {
        VStack(spacing: AppSpacing.medium) {
            // Custom emoji picker
            VStack(spacing: 12) {
                Text("Custom Emoji")
                    .font(AppFont.headline)
                    .foregroundColor(model.themeManager.current.textPrimary)
                
                TextField("Enter emoji", text: Binding(
                    get: { model.countdown.icon },
                    set: { model.updateIcon($0) }
                ))
                .font(.system(size: 40))
                .multilineTextAlignment(.center)
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(model.primaryColor.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Predefined emojis in two rows
            VStack(spacing: AppSpacing.small) {
                Text("Predefined Emojis")
                    .font(AppFont.headline)
                    .foregroundColor(model.themeManager.current.textPrimary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [
                        GridItem(.flexible(minimum: 50, maximum: 100)),
                        GridItem(.flexible(minimum: 50, maximum: 100)),
                    ], spacing: AppSpacing.small) {
                        ForEach(model.predefinedEmojis, id: \.name) { emojiOption in
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(model.countdown.icon == emojiOption.emoji ? model.primaryColor : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        model.updateIcon(emojiOption.emoji)
                                    }
                                
                                Text(emojiOption.emoji)
                                    .font(.system(size: 24))
                                
                                if model.countdown.icon == emojiOption.emoji {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(model.primaryColor)
                                        .background(Circle().fill(Color.white))
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
