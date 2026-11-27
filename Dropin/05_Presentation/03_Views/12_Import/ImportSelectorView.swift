//
//  ImportSelectorView.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/11/26.
//

import SwiftUI

/// Presented when user tap `Import` button in Settings view
/// It will show the file picker
struct ImportSelectorView: View {

    // MARK: - States & Bindings
    @State private var viewModel: ImportSelectorViewModel

    // MARK: - init
    init(viewModel: ImportSelectorViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                contentView
                .padding(.top)
            }
            .navigationTitle("common.import")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ImportNavigationItem.self) { navigationItem in
                viewModel.resolveDestination(navigationItem)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel", action: viewModel.cancel)
                }
            }
            .alert("error.import.tag_import.title",
                   isPresented: $viewModel.presentTagSanityError,
                   actions: {
                       Button("common.close", role: .cancel) { }
                       if let suggestedName = viewModel.tagNameProposal {
                           Button("error.import.tag_import.replace.\(suggestedName)") {
                               viewModel.tagName = suggestedName
                           }
                       }
                   },
                   message: {
                       if let tagErrorMessage = viewModel.tagErrorMessage {
                           Text(tagErrorMessage)
                       }
                   }
            )
            .onChange(of: viewModel.selectedSource) { _, newValue in
                switch newValue {
                    case .dropin: viewModel.tagImport = false
                    case .mapstr: viewModel.tagImport = true
                    case .google: viewModel.tagImport = true
                    case .unknown:
                        assertionFailure()
                        viewModel.tagImport = true
                }
                Task {
                    await viewModel.fillAvailableTagName()
                }
            }
            .task {
                await viewModel.fillAvailableTagName()
            }
        }
    }
    
    // MARK: - Subviews
    private var contentView: some View {
        VStack(spacing: 0) {
            ScrollView {
                Text("import_selector.title")
                    .textStyle(.formSectionTitle)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                sourcesView
                infoView
                    .padding(.bottom, 20)
                
                ImportOptionsView(tagImport: $viewModel.tagImport,
                                  tagName: $viewModel.tagName,
                                  errorMessage: viewModel.tagErrorMessage) {
                    Task {
                        await viewModel.importTagSanityCheck()
                    }
                }
            }
            .padding(.horizontal)
            Spacer()
            Rectangle()
                .fill(.hairline)
                .frame(height: 1)
                .padding(.bottom, 15)
            MainButton(text: "import_selector.action") {
                viewModel.next()
            }
            .padding(.horizontal)
            .accessibilityIdentifier(AccessibilityID.ImportSelector.continueButton)
            .sheet(isPresented: $viewModel.pickFile, content: viewModel.importSheetContent)
        }
    }
    
    private var sourcesView: some View {
        VStack(spacing: 0) {
            ImportChoiceRowView(source: .dropin,
                                title: importSourceTitle(.dropin),
                                subtitle: importSourceSubtitle(.dropin),
                                selected: viewModel.selectedSource == .dropin)
            .onTapGesture {
                viewModel.selectedSource = .dropin
            }
            .padding(.bottom, 10)
            Rectangle()
                .fill(.hairline)
                .frame(height: 1)
                .padding(.horizontal, -15)
                .padding(.leading, 60)
                .padding(.bottom, 10)

            ImportChoiceRowView(source: .mapstr,
                                title: importSourceTitle(.mapstr),
                                subtitle: importSourceSubtitle(.mapstr),
                                selected: viewModel.selectedSource == .mapstr)
            .onTapGesture {
                viewModel.selectedSource = .mapstr
            }
            .padding(.bottom, 10)
            Rectangle()
                .fill(.hairline)
                .frame(height: 1)
                .padding(.horizontal, -15)
                .padding(.leading, 60)
                .padding(.bottom, 10)

            ImportChoiceRowView(source: .google,
                                title: importSourceTitle(.google),
                                subtitle: importSourceSubtitle(.google),
                                selected: viewModel.selectedSource == .google)
            .onTapGesture {
                viewModel.selectedSource = .google
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.surface1)
                .stroke(.hairline)
        }
    }
        
    @ViewBuilder
    private var infoView: some View {
        switch viewModel.selectedSource {
            case .dropin:
                dropinInfoView
            case .mapstr:
                mapstrInfoView
            case .google:
                googleInfoView
            case .unknown:
                EmptyView()
        }
    }
    
    private var dropinInfoView: some View {
        Text("import_selector.dropin.desc")
            .textStyle(.cardFooter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
    }

    private var mapstrInfoView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Image(systemName: "questionmark.circle")
                    .textStyle(.subheadline, color: .dropinPrimary)
                    .padding(.trailing, 10)
                Text("import_selector.mapstr.how_to")
                    .textStyle(.subheadline, color: .dropinPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 10)
                Image(systemName: "arrow.up.right")
                    .textStyle(.subheadline, color: .dropinPrimary)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.surface1)
                    .stroke(.hairline)
            }
            .padding(.top)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.open(DropinApp.urls.importMapstrDesc)
            }
            .padding(.bottom, 5)
            Text("import_selector.mapstr.desc2")
                .textStyle(.cardFooter)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var googleInfoView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Image(systemName: "info.circle")
                    .textStyle(.subheadline, color: .textPrimary)
                    .padding(.trailing, 10)
                Text("import_selector.google.info")
                    .textStyle(.cardFooter, color: .textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .padding(.top, 15)
            .padding(.bottom, 10)

            HStack(spacing: 0) {
                Image(systemName: "questionmark.circle")
                    .textStyle(.subheadline, color: .dropinPrimary)
                    .padding(.trailing, 10)
                Text("import_selector.google.how_to")
                    .textStyle(.subheadline, color: .dropinPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 10)
                Image(systemName: "arrow.up.right")
                    .textStyle(.subheadline, color: .dropinPrimary)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.surface1)
                    .stroke(.hairline)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.open(DropinApp.urls.importGoogleDesc)
            }
            .padding(.bottom, 5)
        }
    }
    
    private var optionsView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Image(systemName: "tag")
                        .textStyle(.subheadline)
                        .padding(.trailing, 10)
                    Text("import_selector.option.tag")
                        .textStyle(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .padding(.trailing, 10)
                    Toggle(String(), isOn: $viewModel.tagImport)
                        .labelsHidden()
                        .frame(minWidth: 0)
                }
                .frame(height: 50)
                if viewModel.tagImport {
                    Rectangle()
                        .fill(.hairline)
                        .frame(height: 1)
                    HStack(spacing: 0) {
                        Text("common.tag")
                            .textStyle(.subheadline, color: .textSecondary)
                        Spacer()
                        TextField(String(), text: $viewModel.tagName)
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1)
                            .textStyle(.subheadline)
                            .autocorrectionDisabled()
                            .onSubmit {
                                viewModel.tagName = viewModel.tagName.trimmedName
                            }
                    }
                    .frame(height: 50)
                }
            }
            .padding(.horizontal, 15)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.surface1)
                    .stroke(.hairline)
            }
            Text("import_selector.option.tag.desc")
                .textStyle(.cardFooter)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.top, 5)
        }
    }

    // MARK: - private methods
    private func importSourceTitle(_ src: ImportSource) -> LocalizedStringKey {
        switch src {
            case .dropin:
                return "import_selector.dropin.title"
            case .mapstr:
                return "import_selector.mapstr.title"
            case .google:
                return "import_selector.google.title"
            case .unknown:
                assertionFailure()
                return ""
        }
    }

    private func importSourceSubtitle(_ src: ImportSource) -> LocalizedStringKey {
        switch src {
            case .dropin:
                return "import_selector.dropin.subtitle"
            case .mapstr:
                return "import_selector.mapstr.subtitle"
            case .google:
                return "import_selector.google.subtitle"
            case .unknown:
                assertionFailure()
                return ""
        }
    }
}


#if DEBUG

struct MockImportSelectorView: View {

    @State var mock = MockContainer()
    @State var coord: ImportFlowCoordinator

    var body: some View {
        mock.appContainer.createImportSelectorView(coordinator: coord,
                                                   onContinue: { _, _, _, _ in },
                                                   onCancel: { },
                                                   resolveDestination: { _ in return AnyView(EmptyView()) })
            .environment(AppSettings())
    }
    
    init() {
        coord = ImportFlowCoordinator(mode: .browse)
    }
}

#Preview {
    MockImportSelectorView()
}

#endif
