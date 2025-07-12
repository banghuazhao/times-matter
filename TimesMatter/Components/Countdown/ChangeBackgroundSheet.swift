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
    
    var selectedTab: Tab = .image
    var selectedPhoto: PhotosPickerItem? = nil
    
    enum Tab: String, CaseIterable, Identifiable {
        case image = "Image"
        case backgroundColor = "Background Color"
        case textColor = "Text Color"
        var id: String { rawValue }
    }

    // Predefined images from the Backgrounds folder
    let predefinedImages = [
        "image_event",
        "image_holiday",
        "image_more2",
        "image_more3",
        "image_more4",
        "image_more5",
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
    
    func useColorOnly() {
        countdown.backgroundImageName = nil
    }
    
    func applyChanges() {
        onSelect(countdown)
    }
    
    // MARK: - Private Methods
    private func loadPhoto(_ photo: PhotosPickerItem) async {
        if let data = try? await photo.loadTransferable(type: Data.self), 
           let uiImage = UIImage(data: data) {
            // Save to temp directory and set backgroundImageName to a unique path
            let filename = "custom_bg_\(UUID().uuidString).jpg"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            if let jpegData = uiImage.jpegData(compressionQuality: 0.95) {
                try? jpegData.write(to: url)
                countdown.backgroundImageName = url.path
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
                CountdownDetailView(
                    model: CountdownDetailModel(countdown: model.previewCountdown)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                
                switch model.selectedTab {
                case .image:
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            PhotosPicker(selection: Binding(
                                get: { model.selectedPhoto },
                                set: { model.selectPhoto($0) }
                            ), matching: .images, photoLibrary: .shared()) {
                                if let backgroundImageName = model.countdown.backgroundImageName,
                                   let uiImage = UIImage(contentsOfFile: backgroundImageName) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 75, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.accentColor, lineWidth: 2)
                                            )
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .offset(x: -4, y: 4)
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 75, height: 100)
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
                                        .frame(width: 75, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(model.countdown.backgroundImageName == name ? Color.accentColor : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            model.selectPredefinedImage(name)
                                        }
                                    if model.countdown.backgroundImageName == name {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                            .offset(x: -4, y: 4)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.medium)
                    }
                    .frame(height: 100)
                case .backgroundColor:
                    VStack(spacing: 24) {
                        ColorPicker("Pick Background Color", selection: Binding(
                            get: { model.countdown.backgroundColor.toColor },
                            set: { model.updateBackgroundColor($0) }
                        ))
                        .labelsHidden()
                        .frame(height: 60)
                        .padding(.horizontal, 40)
                        Button("Use Color (No Image)") {
                            model.useColorOnly()
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                case .textColor:
                    VStack(spacing: 24) {
                        ColorPicker("Pick Text Color", selection: Binding(
                            get: { model.countdown.textColor.toColor },
                            set: { model.updateTextColor($0) }
                        ))
                        .labelsHidden()
                        .frame(height: 60)
                        .padding(.horizontal, 40)
                    }
                }

                // Tabs
                Picker("Tab", selection: Binding(
                    get: { model.selectedTab },
                    set: { model.selectTab($0) }
                )) {
                    ForEach(ChangeBackgroundSheetModel.Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
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
