//
// Created by Banghua Zhao
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import SQLiteData
import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

@Observable
@MainActor
final class BackupViewModel {
    @ObservationIgnored
    @FetchAll(Countdown.all) var allCountdowns

    @ObservationIgnored
    @FetchAll(Category.all) var allCategories

    @ObservationIgnored
    @Dependency(\.defaultDatabase) var database

    @ObservationIgnored
    @Dependency(\.backgroundImageManager) var backgroundImageManager

    @ObservationIgnored
    @Dependency(\.themeManager) var themeManager

    var exportURL: URL?
    var showExporter = false
    var showImporter = false
    var showReplaceConfirm = false
    var pendingImportData: Data?
    var statusMessage: String?
    var isWorking = false

    func exportBackup() {
        isWorking = true
        defer { isWorking = false }
        do {
            let backup = BackupService.makeBackup(
                countdowns: allCountdowns,
                categories: allCategories,
                backgroundImageManager: backgroundImageManager
            )
            exportURL = try BackupService.writeTemporaryFile(backup)
            showExporter = true
            statusMessage = String(
                localized: "Exported \(allCountdowns.count) countdowns and \(allCategories.count) categories."
            )
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func prepareImport(from data: Data) {
        pendingImportData = data
        showReplaceConfirm = true
    }

    func importBackup(replaceExisting: Bool) {
        guard let pendingImportData else { return }
        isWorking = true
        defer {
            isWorking = false
            self.pendingImportData = nil
        }
        do {
            let backup = try BackupService.decodeBackup(from: pendingImportData)
            let result = try BackupService.importBackup(
                backup,
                replaceExisting: replaceExisting,
                database: database,
                backgroundImageManager: backgroundImageManager
            )
            WidgetDataExporter.export(countdowns: try database.read { try Countdown.fetchAll($0) })
            WidgetCenter.shared.reloadAllTimelines()
            statusMessage = String(
                localized: "Imported \(result.countdowns) countdowns and \(result.categories) categories."
            )
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

struct BackupView: View {
    @State private var model = BackupViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(String(localized: "Backup & Restore"))
                        .font(AppFont.title2)
                    Text(String(localized: "Export a JSON backup of your countdowns and categories, or restore from a previous backup. Custom photo backgrounds are included when possible."))
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)
                }

                statsCard

                VStack(spacing: AppSpacing.medium) {
                    Button {
                        Haptics.shared.vibrateIfEnabled()
                        model.exportBackup()
                    } label: {
                        Label(String(localized: "Export Backup"), systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.appRectFilled)
                    .disabled(model.isWorking || (model.allCountdowns.isEmpty && model.allCategories.isEmpty))
                    .accessibilityHint(String(localized: "Creates a shareable backup file"))

                    Button {
                        Haptics.shared.vibrateIfEnabled()
                        model.showImporter = true
                    } label: {
                        Label(String(localized: "Import Backup"), systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.appRect)
                    .disabled(model.isWorking)
                    .accessibilityHint(String(localized: "Restores countdowns from a backup file"))
                }

                if let statusMessage = model.statusMessage {
                    Text(statusMessage)
                        .font(AppFont.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(model.themeManager.current.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
                        .accessibilityLabel(statusMessage)
                }

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label(String(localized: "Tips"), systemImage: "info.circle")
                        .font(AppFont.headline)
                    Text(String(localized: "• Merge keeps your current events and adds items from the backup."))
                    Text(String(localized: "• Replace deletes current countdowns and categories before importing."))
                    Text(String(localized: "• Keep backups somewhere safe (Files, iCloud Drive, or email)."))
                }
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(model.themeManager.current.card)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
            }
            .padding()
        }
        .background(model.themeManager.current.background)
        .navigationTitle(String(localized: "Backup"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $model.showExporter) {
            if let exportURL = model.exportURL {
                ShareSheet(activityItems: [exportURL])
            }
        }
        .fileImporter(
            isPresented: $model.showImporter,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) {
                    model.prepareImport(from: data)
                } else {
                    model.statusMessage = String(localized: "Could not read backup file.")
                }
            case .failure(let error):
                model.statusMessage = error.localizedDescription
            }
        }
        .confirmationDialog(
            String(localized: "How should we import?"),
            isPresented: $model.showReplaceConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Merge with Existing")) {
                model.importBackup(replaceExisting: false)
            }
            Button(String(localized: "Replace All Data"), role: .destructive) {
                model.importBackup(replaceExisting: true)
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                model.pendingImportData = nil
            }
        } message: {
            Text(String(localized: "Merge adds backup items alongside your current data. Replace clears everything first."))
        }
    }

    private var statsCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Ready to export"))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Text("\(model.allCountdowns.count) · \(model.allCategories.count)")
                    .font(AppFont.title2)
                Text(String(localized: "Countdowns · Categories"))
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "externaldrive.fill")
                .font(.system(size: 36))
                .foregroundStyle(model.themeManager.current.primaryColor)
                .accessibilityHidden(true)
        }
        .padding()
        .background(model.themeManager.current.card)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
    }
}

#Preview {
    NavigationStack {
        BackupView()
    }
}
