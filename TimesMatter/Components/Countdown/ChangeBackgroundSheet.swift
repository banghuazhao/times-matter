import AVFoundation
import Dependencies
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

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
    @Dependency(\.videoBackgroundManager) var videoBackgroundManager

    @ObservationIgnored
    @Dependency(\.purchaseManager) var purchaseManager

    var selectedTab: Tab = .image
    var selectedPhoto: PhotosPickerItem?
    var selectedVideo: PhotosPickerItem?
    var showPurchaseSheet = false
    var musicPreviewPlayer: AVAudioPlayer?

    /// Paths present when the sheet opened — never deleted until Done confirms a replacement.
    private let baselineImageName: String?
    private let baselineVideoPath: String?
    /// Files created during this editing session (safe to delete on Cancel).
    private var sessionImagePaths = Set<String>()
    private var sessionVideoPaths = Set<String>()
    private var didApply = false

    var isPremium: Bool {
        purchaseManager.isPremiumUserPurchased
    }

    enum Tab: String, CaseIterable, Identifiable {
        case image
        case video
        case music
        case backgroundColor
        case textColor
        case layout

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .image: return "photo.on.rectangle"
            case .video: return "video.fill"
            case .music: return "music.note"
            case .backgroundColor: return "paintpalette"
            case .textColor: return "textformat"
            case .layout: return "rectangle.3.offgrid"
            }
        }

        var displayName: String {
            switch self {
            case .image: String(localized: "Image")
            case .video: String(localized: "Video")
            case .music: String(localized: "Music")
            case .backgroundColor: String(localized: "BG Color")
            case .textColor: String(localized: "Text")
            case .layout: String(localized: "Layout")
            }
        }
    }

    init(countdown: Countdown.Draft, onSelect: @escaping (Countdown.Draft) -> Void) {
        self.countdown = countdown
        self.onSelect = onSelect
        self.baselineImageName = countdown.backgroundImageName
        self.baselineVideoPath = countdown.backgroundVideoPath
    }

    var primaryColor: Color {
        themeManager.current.primaryColor
    }

    var previewCountdown: Countdown {
        countdown.mock
    }

    // MARK: - Actions

    func selectTab(_ tab: Tab) {
        stopMusicPreview()
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
            Task { await loadPhoto(photo) }
        }
    }

    func selectVideo(_ video: PhotosPickerItem?) {
        guard isPremium else {
            selectedVideo = nil
            showPurchaseSheet = true
            return
        }
        selectedVideo = video
        if let video {
            Task { await loadVideo(video) }
        }
    }

    func selectPredefinedImage(_ imageName: String) {
        clearSessionImageIfReplacing()
        clearSessionVideoIfReplacing()
        countdown.backgroundImageName = imageName
        countdown.backgroundVideoPath = nil
    }

    func clearVideo() {
        clearSessionVideoIfReplacing()
        countdown.backgroundVideoPath = nil
    }

    func selectMusic(_ fileName: String?) {
        // Clearing music is always allowed; choosing a track requires Premium.
        if let fileName, fileName != BackgroundMusicCatalog.none, !isPremium {
            showPurchaseSheet = true
            return
        }
        countdown.backgroundMusicName = fileName
        if let fileName, fileName != BackgroundMusicCatalog.none {
            previewMusic(fileName)
        } else {
            stopMusicPreview()
        }
    }

    func updateBackgroundColor(_ color: Color) {
        updateBackgroundColor(hex: color.hexIntWithAlpha)
    }

    func updateBackgroundColor(hex: Int) {
        // Color is mutually exclusive with image/video — picking a swatch is enough.
        clearSessionImageIfReplacing()
        clearSessionVideoIfReplacing()
        countdown.backgroundImageName = nil
        countdown.backgroundVideoPath = nil
        countdown.backgroundColor = hex
    }

    func updateTextColor(_ color: Color) {
        updateTextColor(hex: color.hexIntWithAlpha)
    }

    func updateTextColor(hex: Int) {
        countdown.textColor = hex
    }

    func updateLayout(_ layout: LayoutType) {
        countdown.layout = layout
    }

    func applyChanges() {
        stopMusicPreview()
        commitMediaDeletions()
        didApply = true
        onSelect(countdown)
    }

    /// Call when dismissing without Done so temp files from this session are removed.
    func discardChanges() {
        guard !didApply else { return }
        stopMusicPreview()
        for path in sessionImagePaths {
            try? backgroundImageManager.deleteCustomBackgroundImage(at: path)
        }
        for path in sessionVideoPaths {
            try? videoBackgroundManager.deleteCustomBackgroundVideo(at: path)
        }
        sessionImagePaths.removeAll()
        sessionVideoPaths.removeAll()
    }

    func stopMusicPreview() {
        musicPreviewPlayer?.stop()
        musicPreviewPlayer = nil
    }

    // MARK: - Private Methods

    private func loadPhoto(_ photo: PhotosPickerItem) async {
        guard let data = try? await photo.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        clearSessionImageIfReplacing()
        clearSessionVideoIfReplacing()
        countdown.backgroundVideoPath = nil

        if let imagePath = try? backgroundImageManager.saveCustomBackgroundImage(uiImage) {
            sessionImagePaths.insert(imagePath)
            countdown.backgroundImageName = imagePath
        }
    }

    private func loadVideo(_ video: PhotosPickerItem) async {
        guard let movie = try? await video.loadTransferable(type: MovieFile.self) else { return }
        // Video is mutually exclusive with image/color media.
        clearSessionImageIfReplacing()
        clearSessionVideoIfReplacing()
        countdown.backgroundImageName = nil
        do {
            let path = try videoBackgroundManager.saveCustomBackgroundVideo(from: movie.url)
            sessionVideoPaths.insert(path)
            countdown.backgroundVideoPath = path
        } catch {
            print("Failed to save video background: \(error)")
        }
    }

    private func previewMusic(_ fileName: String) {
        stopMusicPreview()
        guard let url = BackgroundMusicCatalog.url(for: fileName) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = Float(max(0, min(1, countdown.backgroundMusicVolume)))
            player.prepareToPlay()
            player.play()
            musicPreviewPlayer = player
        } catch {
            print("Music preview failed: \(error)")
        }
    }

    func updateMusicVolume(_ volume: Double) {
        countdown.backgroundMusicVolume = max(0, min(1, volume))
        musicPreviewPlayer?.volume = Float(countdown.backgroundMusicVolume)
    }

    /// Deletes only media created in this sheet session (keeps baseline files until Done).
    private func clearSessionImageIfReplacing() {
        if let path = countdown.backgroundImageName, sessionImagePaths.contains(path) {
            try? backgroundImageManager.deleteCustomBackgroundImage(at: path)
            sessionImagePaths.remove(path)
        }
    }

    private func clearSessionVideoIfReplacing() {
        if let path = countdown.backgroundVideoPath, sessionVideoPaths.contains(path) {
            try? videoBackgroundManager.deleteCustomBackgroundVideo(at: path)
            sessionVideoPaths.remove(path)
        }
    }

    private func commitMediaDeletions() {
        if let baseline = baselineImageName,
           baseline != countdown.backgroundImageName,
           backgroundImageManager.isCustomBackgroundImagePath(baseline) {
            try? backgroundImageManager.deleteCustomBackgroundImage(at: baseline)
        }
        if let baseline = baselineVideoPath,
           baseline != countdown.backgroundVideoPath,
           videoBackgroundManager.isCustomBackgroundVideoPath(baseline) {
            try? videoBackgroundManager.deleteCustomBackgroundVideo(at: baseline)
        }

        for path in sessionImagePaths where path != countdown.backgroundImageName {
            try? backgroundImageManager.deleteCustomBackgroundImage(at: path)
        }
        for path in sessionVideoPaths where path != countdown.backgroundVideoPath {
            try? videoBackgroundManager.deleteCustomBackgroundVideo(at: path)
        }
        sessionImagePaths.removeAll()
        sessionVideoPaths.removeAll()
    }
}

/// Temporary transferable for PhotosPicker video items.
struct MovieFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("import-\(UUID().uuidString).\(received.file.pathExtension)")
            try? FileManager.default.removeItem(at: temp)
            try FileManager.default.copyItem(at: received.file, to: temp)
            return MovieFile(url: temp)
        }
    }
}

struct ChangeBackgroundSheet: View {
    @State var model: ChangeBackgroundSheetModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

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
                case .video:
                    videoBackground
                case .music:
                    musicBackground
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
            .navigationTitle(String(localized: "Customize"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbarBackground(model.themeManager.current.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(model.themeManager.current.primaryColor)
            .foregroundStyle(model.themeManager.current.textPrimary)
            .toolbar {
                ToolbarCloseItem {
                    Haptics.shared.vibrateIfEnabled()
                    model.discardChanges()
                    dismiss()
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
            .onDisappear {
                model.discardChanges()
            }
        }
    }

    private var videoBackground: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if !model.isPremium {
                Label(String(localized: "Video backgrounds require Premium"), systemImage: "crown.fill")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppSpacing.medium)
            }

            Text(String(localized: "Uses the first few seconds of your video and loops them on the countdown screen."))
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.medium)

            HStack(spacing: AppSpacing.medium) {
                if model.isPremium {
                    PhotosPicker(
                        selection: Binding(
                            get: { model.selectedVideo },
                            set: { model.selectVideo($0) }
                        ),
                        matching: .videos
                    ) {
                        Label(
                            model.countdown.backgroundVideoPath == nil
                                ? String(localized: "Choose Video")
                                : String(localized: "Change Video"),
                            systemImage: "video.badge.plus"
                        )
                        .font(AppFont.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(model.primaryColor.opacity(0.12))
                        .foregroundStyle(model.primaryColor)
                        .clipShape(Capsule())
                    }
                } else {
                    Button {
                        model.showPurchaseSheet = true
                    } label: {
                        Label(String(localized: "Choose Video"), systemImage: "lock.fill")
                            .font(AppFont.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if model.countdown.backgroundVideoPath != nil {
                    Button(String(localized: "Remove")) {
                        Haptics.shared.vibrateIfEnabled()
                        model.clearVideo()
                    }
                    .font(AppFont.subheadline)
                    .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .frame(height: 100, alignment: .top)
        }
        .sheet(isPresented: $model.showPurchaseSheet) {
            PurchaseSheet()
        }
    }

    private var musicBackground: some View {
        let hasMusic = model.countdown.backgroundMusicName != nil
            && model.countdown.backgroundMusicName != BackgroundMusicCatalog.none

        return ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                if !model.isPremium {
                    Label(String(localized: "Background music requires Premium"), systemImage: "crown.fill")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }

                Text(String(localized: "Image, video, and solid color backgrounds are separate—choosing one replaces the others. Music can play with any of them."))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                if hasMusic {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        HStack {
                            Text(String(localized: "Volume"))
                                .font(AppFont.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int((model.countdown.backgroundMusicVolume * 100).rounded()))%")
                                .font(AppFont.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(
                            value: Binding(
                                get: { model.countdown.backgroundMusicVolume },
                                set: { model.updateMusicVolume($0) }
                            ),
                            in: 0...1
                        )
                        .tint(model.primaryColor)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, AppSpacing.xSmall)
                }

                Button {
                    Haptics.shared.vibrateIfEnabled()
                    model.selectMusic(nil)
                } label: {
                    musicRow(
                        title: String(localized: "None"),
                        subtitle: String(localized: "No background music"),
                        selected: !hasMusic
                    )
                }
                .buttonStyle(.plain)

                ForEach(BackgroundMusicCatalog.categories, id: \.self) { category in
                    Text(category)
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, AppSpacing.small)
                        .padding(.horizontal, 4)

                    ForEach(BackgroundMusicCatalog.tracks.filter { $0.category == category }) { track in
                        Button {
                            Haptics.shared.vibrateIfEnabled()
                            model.selectMusic(track.fileName)
                        } label: {
                            musicRow(
                                title: track.displayName,
                                subtitle: track.fileName,
                                selected: model.countdown.backgroundMusicName == track.fileName
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.bottom, AppSpacing.medium)
        }
        .frame(height: 180)
    }

    private func musicRow(title: String, subtitle: String, selected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.subheadlineSemibold)
                    .foregroundStyle(model.themeManager.current.textPrimary)
                Text(subtitle)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(model.primaryColor)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selected ? model.primaryColor.opacity(0.12) : model.themeManager.current.card)
        )
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

                ForEach(PredefinedColors.backgroundColorHexes, id: \.self) { hex in
                    let isColorOnly = model.countdown.backgroundImageName == nil
                        && model.countdown.backgroundVideoPath == nil
                    let isSelected = isColorOnly && model.countdown.backgroundColor == hex
                    Button {
                        Haptics.shared.vibrateIfEnabled()
                        model.updateBackgroundColor(hex: hex)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: hex))
                                .frame(width: 66, height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? model.primaryColor : Color.clear, lineWidth: 2)
                                )

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.3)))
                                    .offset(x: -4, y: 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Background color"))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
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

                ForEach(PredefinedColors.textColorHexes, id: \.self) { hex in
                    let isSelected = model.countdown.textColor == hex
                    Button {
                        Haptics.shared.vibrateIfEnabled()
                        model.updateTextColor(hex: hex)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: hex))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? model.primaryColor : Color.clear, lineWidth: 2)
                                )

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.3)))
                                    .offset(x: -4, y: 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
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
