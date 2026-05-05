//
//  SettingsView.swift
//  Dropin
//
//  Created by baptiste sansierra on 17/4/26.
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - State & Bindings
    @State private var viewModel: SettingsViewModel
    @Binding private var showingSideMenu: Bool
    @Environment(AppSettings.self) private var appSettings

    // MARK: - init
    init(viewModel: SettingsViewModel, showingSideMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSideMenu = showingSideMenu
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            List {
                mapConfigSection
                dataSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("common.settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
            }
            .sheet(isPresented: $viewModel.showMapstrConfig, content: mapstrConfigSheetContent)
            .sheet(isPresented: $viewModel.pickFile, content: importSheetContent)
            .sheet(item: $viewModel.exportedTemporaryFile, content: exportSheetContent)
            .overlay(content: deleteDatabaseOverlay)
        }
    }
    
    // MARK: - subviews
    private var mapConfigSection: some View {
        Section {
            // Map preview
            MapSettingsPreviewView(mapEditMode: $viewModel.mapEditMode)
                .frame(height: 280)
                .listRowInsets(EdgeInsets())
            
            // Pin style row
            settingsRow(icon: "mappin",
                        iconColor: .accentColor,
                        title: "settings.pin_style",
                        value: appSettings.pinStyle.displayName,
                        isActive: viewModel.mapEditMode == .style) {
                viewModel.mapEditMode = viewModel.mapEditMode == .style ? .none : .style
            }

            // Pin size row
            settingsRow(icon: "ruler",
                        iconColor: .orange,
                        title: "settings.pin_size",
                        value: "\(Int(appSettings.pinSize)) pt",
                        isActive: viewModel.mapEditMode == .size) {
                viewModel.mapEditMode = viewModel.mapEditMode == .size ? .none : .size
            }
        } header: {
            Text("settings.section.map_config")
        }
    }

    private var dataSection: some View {
        Section {
            // Export
            Button {
                exportData()
            } label: {
                HStack(spacing: 12) {
                    iconBadge(systemName: "square.and.arrow.up", color: .blue)
                    Text("common.export")
                        .foregroundStyle(.primary)
                    Spacer()
                    if viewModel.isExporting {
                        ProgressView().scaleEffect(0.8)
                    }
                }
            }
            .disabled(viewModel.isExporting)

            // Import
            Menu {
                Button(DropinApp.strings.app, action: {
                    viewModel.importSource = .dropin
                    viewModel.pickFile = true
                    viewModel.isImporting = true
                })
                Button("Mapstr (GeoJSON)" as String, action: {
                    viewModel.showMapstrConfig = true
                })
                Button("Google (GeoJSON)" as String, action: {
                    //viewModel.isImporting = true
                })
            } label: {
                HStack(spacing: 12) {
                    iconBadge(systemName: "square.and.arrow.down", color: .green)
                    Text("common.import")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            // Reset
            Button(role: .destructive) {
                viewModel.showDeleteConfirmation = true
            } label: {
                HStack(spacing: 12) {
                    iconBadge(systemName: "trash", color: .red)
                    Text("settings.reset_db")
                }
            }

        } header: {
            Text("settings.section.data")
        }
    }

    private func settingsRow(icon: String,
                             iconColor: Color,
                             title: LocalizedStringKey,
                             value: String,
                             isActive: Bool,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconBadge(systemName: icon, color: iconColor)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(value)
                    .font(.system(size: 14))
                    .foregroundStyle(isActive ? Color.accentColor : .secondary)
                Image(systemName: isActive ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isActive ? Color.accentColor : .secondary)
            }
        }
        .listRowBackground(isActive ? Color.accentColor.opacity(0.06) : Color(.secondarySystemGroupedBackground))
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
    
    @ViewBuilder
    private func iconBadge(systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(color)
                .frame(width: 30, height: 30)
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
    }
    
    private func mapstrConfigSheetContent() -> some View {
        MapstrImportConfigView(tagName: $viewModel.mapstrMarkerTagName) {
            viewModel.importSource = .mapstr
            viewModel.pickFile = true
        }
        .presentationDetents([.medium])
    }

    private func importSheetContent() -> some View {
        ImportPicker(source: viewModel.importSource, onPick: onPickedFile)
    }

    @ViewBuilder
    private func exportSheetContent(url: IdentifiableURL) -> some View {
        ShareSheet(url: url.url) { complete in
            viewModel.isExporting = false
        }
    }
    
    @ViewBuilder
    private func deleteDatabaseOverlay() -> some View {
        if viewModel.showDeleteConfirmation {
            DeleteConfirmationAlert(isPresented: $viewModel.showDeleteConfirmation) {
                Task {
                    try await viewModel.resetDatabase()
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            .animation(.spring(response: 0.3), value: viewModel.showDeleteConfirmation)
        }
    }

    // MARK: - private methods
    private func onPickedFile(_ url: URL) {
        Task {
            do {
                switch viewModel.importSource {
                case .dropin:  try await viewModel.importDropin(url)
                case .mapstr:  try await viewModel.importMapstr(url)
                default: break
                }
            } catch {
                // TODO handle error
            }
        }
    }

    private func exportData() {
        viewModel.isExporting = true
        Task {
            do {
                //try await Task.sleep(for: .seconds(2))
                let url = try await viewModel.export()
                viewModel.exportedTemporaryFile = IdentifiableURL(url: url)
            } catch {
                // TODO: handle error
                
                viewModel.isExporting = false
                viewModel.exportedTemporaryFile = nil
            }
        }
    }
}

#Preview {
    
    @Previewable @State var mock = MockContainer()
    @Previewable @State var showingSideMenu = false

    mock.appContainer.createSettingsView(showingSideMenu: $showingSideMenu)
        .environment(AppSettings())
}
