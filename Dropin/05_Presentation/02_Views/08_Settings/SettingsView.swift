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

    private var rowHeight: CGFloat = 55
    
    // MARK: - init
    init(viewModel: SettingsViewModel, showingSideMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSideMenu = showingSideMenu
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
//                List {
//                    mapConfigSection
//                    dataSection
//                }
//                .listStyle(.insetGrouped)
                
                ScrollView {
                    mapConfigSection
                        .padding(.top, 15)
                        .padding(.bottom, 15)
                    dataSection
                }
                .padding(.horizontal)
                
                if viewModel.importing {
                    Color.overlayAlphaLayer
                        .ignoresSafeArea()
                    DropinLoader(caption: viewModel.importingCaption)
                    // TODO: the label should update to reflect Places number once it's known
                }
            }
            .disabled(viewModel.importing)
            .navigationTitle("common.settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
            }
            .sheet(isPresented: $viewModel.showMapstrConfig, content: mapstrConfigSheetContent)
            .sheet(isPresented: $viewModel.pickFile, content: importSheetContent)
            .sheet(item: $viewModel.exportedTemporaryFile, content: exportSheetContent)
            .overlay(content: deleteDatabaseOverlay)
            .alert(importAlertTitle,
                   isPresented: importAlertBinding,
                   presenting: viewModel.importResult) { _ in
                Button("common.ok", role: .cancel) {
                    viewModel.importResult = nil
                }
            } message: { result in
                switch result {
                    case .success(let count):
                        Text("settings.import.success_body_\(count)")
                    case .failure(let message):
                        Text(verbatim: message)
                }
            }
        }
    }
    
    // MARK: - subviews
    private var mapConfigSection: some View {
        VStack(spacing: 0) {
            Text("settings.section.map_config")
                .textStyle(.formSectionTitle)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                @Bindable var appSettings = appSettings

                // Map preview
                MapSettingsPreviewView(mapEditMode: $viewModel.mapEditMode)
                    .frame(height: 280)
                    .listRowInsets(EdgeInsets())
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16
                    ))
                                
                // Pin style row
                settingsRow(icon: "mappin",
                            iconColor: Color(rgba: "588B8B"),
                            title: "settings.pin_style",
                            value: appSettings.mapSettings.pinStyle.displayName,
                            isActive: viewModel.mapEditMode == .style) {
                    viewModel.mapEditMode = viewModel.mapEditMode == .style ? .none : .style
                }
                .frame(height: rowHeight)
                .padding(.horizontal)
                
                rowSeparator


                // Pin size row
                settingsRow(icon: "ruler",
                            iconColor: Color(rgba: "B08A4E"),
                            title: "settings.pin_size",
                            value: "\(Int(appSettings.mapSettings.pinSize)) pt",
                            isActive: viewModel.mapEditMode == .size) {
                    viewModel.mapEditMode = viewModel.mapEditMode == .size ? .none : .size
                }
                .frame(height: rowHeight)
                .padding(.horizontal)
                
                rowSeparator

                // Clustering
                HStack(spacing: 12) {
                    iconBadge(systemName: "rectangle.3.group",
                              color: Color(rgba: "5B8B9E"))
                    Text("settings.clustering")
                        .textStyle(.settingTitle)
                    Spacer()
                    Toggle("", isOn: $appSettings.mapSettings.clustering)
                }
                .frame(height: rowHeight)
                .padding(.horizontal)
            }
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
            }
        }
    }

    private var rowSeparator: some View {
        Rectangle()
            .fill(.fieldBorder)
            .frame(height: 1)
            .padding(.leading, 57)
    }

    private var dataSection: some View {
        
        VStack(spacing: 0) {
            Text("settings.section.data")
                .textStyle(.formSectionTitle)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            
            VStack(spacing: 0) {
                
                // Export
                Button {
                    exportData()
                } label: {
                    HStack(spacing: 12) {
                        iconBadge(systemName: "square.and.arrow.up",
                                  color: .dropinPrimary.opacity(0.1),
                                  badgeColor: .dropinPrimary)
                        Text("common.export")
                            .textStyle(.settingTitleAction)
                        Spacer()
                        if viewModel.isExporting {
                            ProgressView().scaleEffect(0.8)
                        }
                    }
                }
                .disabled(viewModel.isExporting)
                .frame(height: rowHeight)
                .padding(.horizontal)

                rowSeparator
                
                // Import
                Menu {
                    Button(DropinApp.strings.app, action: {
                        viewModel.importSource = .dropin
                        viewModel.pickFile = true
                        viewModel.isImporting = true
                    })
                    Button(String(localized: "settings.import.mapstr"), action: {
                        viewModel.showMapstrConfig = true
                    })
                    Button(String(localized: "settings.import.google"), action: {
                        //viewModel.isImporting = true
                    })
                } label: {
                    HStack(spacing: 12) {
                        iconBadge(systemName: "square.and.arrow.down",
                                  color: .dropinPrimary.opacity(0.1),
                                  badgeColor: .dropinPrimary)
                        Text("common.import")
                            .textStyle(.settingTitleAction)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(TextStyle.settingTitle.color)
                    }
                    .frame(height: rowHeight)
                    .padding(.horizontal)
                }

                rowSeparator
                
                // Reset
                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        iconBadge(systemName: "trash",
                                  color: .destructive.opacity(0.1),
                                  badgeColor: .destructive)
                        Text("settings.reset_db")
                            .textStyle(.settingTitleAction, color: .destructive)
                        Spacer()
                    }
                    .frame(height: rowHeight)
                    .padding(.horizontal)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
            }

        }
        
        /*
        
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
                Button(String(localized: "settings.import.mapstr"), action: {
                    viewModel.showMapstrConfig = true
                })
                Button(String(localized: "settings.import.google"), action: {
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
         */
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
                    .textStyle(.settingTitle)
                    .foregroundStyle(.primary)
                Spacer()
                let valueColor: Color = isActive ? .info : .textTertiary
                Text(value)
                    .textStyle(.settingValue, color: valueColor)
                Image(systemName: isActive ? "chevron.up" : "chevron.down")
                    .textStyle(.settingValue, color: valueColor)
            }
        }
        .listRowBackground(isActive ? Color.accentColor.opacity(0.06) : Color(.secondarySystemGroupedBackground))
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
    
    @ViewBuilder
    private func iconBadge(systemName: String,
                           color: Color,
                           badgeColor: Color = .white) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(color)
                .frame(width: 30, height: 30)
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(badgeColor)
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

    // MARK: - alert helpers
    private var importAlertTitle: LocalizedStringKey {
        switch viewModel.importResult {
            case .success: return "settings.import.success_title"
            case .failure: return "settings.import.error_title"
            case .none:    return ""
        }
    }

    private var importAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.importResult != nil },
            set: { if !$0 { viewModel.importResult = nil } }
        )
    }

    // MARK: - private methods
    private func onPickedFile(_ url: URL) {
        Task {
            switch viewModel.importSource {
                case .dropin: await viewModel.importDropin(url)
                case .mapstr: await viewModel.importMapstr(url)
                default: break
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

#if DEBUG

struct MOCKSettingsView: View {

    @State var mock = MockContainer()
    @State var showingSideMenu = false
    @State private var appSettings: AppSettings
    
    var body: some View {
        mock.appContainer.createSettingsView(showingSideMenu: $showingSideMenu)
            .environment(appSettings)
    }
    
    init() {
        appSettings = AppSettings()
    }
}

#Preview {
    MOCKSettingsView()
}

#endif
