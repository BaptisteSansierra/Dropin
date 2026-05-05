#if false


import SwiftUI
import UniformTypeIdentifiers



struct SettingsView2: View {

    @State private var mapEditMode = MapEditSettingsMode.none
    @Environment(AppSettings.self) private var appSettings

    
    var body: some View {
        List {
            mapConfigSection
            dataSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Map configuration section

    private var mapConfigSection: some View {
        Section {
            // Map preview
            MapSettingsPreviewView(mapEditMode: $mapEditMode)
                .frame(height: 280)
                .listRowInsets(EdgeInsets())
            
            // Pin style row
            settingsRow(icon: "mappin",
                        iconColor: .accentColor,
                        title: "Pin style",
                        value: appSettings.pinStyle.displayName,
                        isActive: mapEditMode == .style) {
                mapEditMode = mapEditMode == .style ? .none : .style
            }

            // Pin size row
            settingsRow(icon: "ruler",
                        iconColor: .orange,
                        title: "Pin size",
                        value: "\(Int(appSettings.pinSize)) pt",
                        isActive: mapEditMode == .size) {
                mapEditMode = mapEditMode == .size ? .none : .size
            }
        } header: {
            Text("Map configuration")
        }
    }

    // MARK: - Data section

    private var dataSection: some View {
        Section {
            // Export
            Button {
                //viewModel.exportData()
            } label: {
                HStack(spacing: 12) {
                    iconBadge(systemName: "square.and.arrow.up", color: .blue)
                    Text("Export")
                        .foregroundStyle(.primary)
                    Spacer()
                    if false /*viewModel.isExporting*/ {
                        ProgressView().scaleEffect(0.8)
                    }
                }
            }
            .disabled(false /*viewModel.isExporting*/)

            // Import
            Menu {
                Button("Dropin file") {
                    //viewModel.isImporting = true
                }
                Button("Mapstr file (GeoJSON)") {
                    //viewModel.isImporting = true
                }
                Button("Google (GeoJSON)") {
                    //viewModel.isImporting = true
                }
            } label: {
                HStack(spacing: 12) {
                    iconBadge(systemName: "square.and.arrow.down", color: .green)
                    Text("Import")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            // Reset
            Button(role: .destructive) {
                //viewModel.requestReset()
            } label: {
                HStack(spacing: 12) {
                    iconBadge(systemName: "trash", color: .red)
                    Text("Reset database")
                }
            }

        } header: {
            Text("Data")
        }
    }

    // MARK: - Reusable components

    private func settingsRow(icon: String,
                             iconColor: Color,
                             title: String,
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
}

#Preview {
    SettingsView2()
        .environment(AppSettings())
}

// MARK: - Custom UTType

extension UTType {
    static let dropinFormat = UTType(exportedAs: "com.dropin.dropin")
    static let geojson = UTType(exportedAs: "public.geojson")
}

// MARK: - FileDocument wrapper (stub for export)

/*
struct DropinDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.dropinFormat] }

    private let url: URL?

    init(url: URL?) { self.url = url }
    init(configuration: ReadConfiguration) throws { self.url = nil }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url, let data = try? Data(contentsOf: url) else {
            return FileWrapper(regularFileWithContents: Data())
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
 */




#if false

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewCLModel

    var body: some View {
        List {
            mapConfigSection
            dataSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert(item: $viewModel.activeAlert, content: alertContent)
        .fileExporter(
            isPresented: Binding(
                get: { viewModel.exportURL != nil },
                set: { if !$0 { viewModel.exportURL = nil } }
            ),
            document: DropinDocument(url: viewModel.exportURL),
            contentType: .dropinFormat,
            defaultFilename: "dropin_export"
        ) { _ in }
        .fileImporter(
            isPresented: $viewModel.isImporting,
            allowedContentTypes: [.dropinFormat, .json, .geojson],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }

    // MARK: - Map configuration section

    private var mapConfigSection: some View {
        Section {
            // Map preview — always visible
            MapConfigPreviewView(viewModel: viewModel)
                .frame(height: 280)
                .listRowInsets(EdgeInsets())

            // Pin style row
            settingsRow(
                icon: "mappin",
                iconColor: .accentColor,
                title: "Pin style",
                value: viewModel.settings.pinStyle.displayName,
                isActive: viewModel.mapEditMode == .style
            ) {
                viewModel.toggleStyleEdit()
            }

            // Pin size row
            settingsRow(
                icon: "ruler",
                iconColor: .orange,
                title: "Pin size",
                value: "\(Int(viewModel.settings.pinSize)) pt",
                isActive: viewModel.mapEditMode == .size
            ) {
                viewModel.toggleSizeEdit()
            }

        } header: {
            Text("Map configuration")
        }
    }

    // MARK: - Data section

    private var dataSection: some View {
        Section {
            // Export
            Button {
                viewModel.exportData()
            } label: {
                HStack(spacing: 12) {
                    iconBadge(systemName: "square.and.arrow.up", color: .blue)
                    Text("Export")
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
                Button("Dropin file") {
                    viewModel.isImporting = true
                }
                Button("Mapstr file (GeoJSON)") {
                    viewModel.isImporting = true
                }
                Button("Google (GeoJSON)") {
                    viewModel.isImporting = true
                }
            } label: {
                HStack(spacing: 12) {
                    iconBadge(systemName: "square.and.arrow.down", color: .green)
                    Text("Import")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            // Reset
            Button(role: .destructive) {
                viewModel.requestReset()
            } label: {
                HStack(spacing: 12) {
                    iconBadge(systemName: "trash", color: .red)
                    Text("Reset database")
                }
            }

        } header: {
            Text("Data")
        }
    }

    // MARK: - Reusable components

    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        value: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
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

    // MARK: - Alerts

    private func alertContent(for alert: SettingsAlert) -> Alert {
        switch alert {
        case .confirmReset:
            return Alert(
                title: Text("Reset database"),
                message: Text("All your places will be permanently deleted. This action cannot be undone."),
                primaryButton: .destructive(Text("Reset"), action: viewModel.confirmReset),
                secondaryButton: .cancel()
            )
        case .error(let message):
            return Alert(
                title: Text("Something went wrong"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        case .importPicker:
            return Alert(title: Text("Import"))
        }
    }

    // MARK: - Import handling

    private func handleImport(result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        // Detect format by extension; default to dropin
        switch url.pathExtension.lowercased() {
        case "geojson", "json":
            // Distinguish mapstr vs google by filename convention or let user choose in a future step
            viewModel.importData(source: .mapstr(url))
        default:
            viewModel.importData(source: .dropinFile(url))
        }
    }
}

// MARK: - Custom UTType

extension UTType {
    static let dropinFormat = UTType(exportedAs: "com.dropin.dropin")
    static let geojson = UTType(exportedAs: "public.geojson")
}

// MARK: - FileDocument wrapper (stub for export)

struct DropinDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.dropinFormat] }

    private let url: URL?

    init(url: URL?) { self.url = url }
    init(configuration: ReadConfiguration) throws { self.url = nil }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url, let data = try? Data(contentsOf: url) else {
            return FileWrapper(regularFileWithContents: Data())
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

#endif

#endif
