//
//  ImportPrepareView.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/11/26.
//

import SwiftUI

/// Prepares the import of a file opened from outside the app (file type + import options)
struct ImportPrepareView: View {

    @State var viewModel: ImportPrepareViewModel

    init(viewModel: ImportPrepareViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        headerView
                            .padding(.bottom, 20)
                        
                        // Ask user to confirm source in case the file format is not proprietary
                        if viewModel.ext != .dropin {
                            confirmSourceView
                                .padding(.bottom, 20)
                        }
                        
                        if viewModel.selectedSource == .unknown {
                            Text("import_prepare.unsupported_source.\(Text(viewModel.ext.displayName).bold())")
                                .textStyle(.body)
                                .padding(.bottom, 15)

                            TextButton(text: "import_prepare.let_us_know") {
                                guard let url = URL(string: "mailto:\(DropinApp.strings.contact)") else { return }
                                UIApplication.shared.open(url)
                            }
                        } else {
                            ImportOptionsView(tagImport: $viewModel.tagImport,
                                              tagName: $viewModel.tagName,
                                              errorMessage: viewModel.tagErrorMessage) {
                                Task {
                                    await viewModel.importTagSanityCheck()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    Spacer()
                    Rectangle()
                        .fill(.hairline)
                        .frame(height: 1)
                        .padding(.bottom, 15)
                    MainButton(text: "common.continue") {
                        viewModel.next()
                    }
                    .disabled(viewModel.selectedSource == .unknown)
                    .padding(.horizontal)
                }
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
            .onChange(of: viewModel.selectedSource) { _, newValue in
                viewModel.didUpdateSelectedSource(newValue)
            }
            .task {
                viewModel.selectDefaultSource()
                await viewModel.fillAvailableTagName()
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
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        HStack(spacing: 0) {
            ImportTileView(source: viewModel.selectedSource)
                .padding(.trailing, 10)
            VStack(spacing: 0) {
                Text(verbatim: viewModel.url.lastPathComponent)
                    .textStyle(.cellTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)
                Text(viewModel.ext.displayName)
                    .textStyle(.cellSubtitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private var confirmSourceView: some View {
        VStack(spacing: 0) {
            Text("import_prepare.confirm_source.title")
                .textStyle(.formSectionTitle)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            VStack(spacing: 10) {
                ForEach(Array(viewModel.ext.matchingSource.enumerated()), id: \.element) { idx, source in
                    if idx != 0 {
                        Rectangle()
                            .fill(.hairline)
                            .frame(height: 1)
                    }
                    ImportChoiceRowView(source: source,
                                        title: source.displayName,
                                        subtitle: nil,
                                        selected: viewModel.selectedSource == source)
                    .onTapGesture {
                        viewModel.selectedSource = source
                    }
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
    }
}

#if DEBUG

struct MOCKImportPrepareView: View {
    @State var mock = MockContainer()
    @State var coord: ImportFlowCoordinator

    var body: some View {
        mock.appContainer.createImportPrepareView(coordinator: coord, onContinue: { _, _, _, _ in
        }, onCancel: {}, resolveDestination: { _ in return AnyView(EmptyView()) })
            .environment(AppSettings())
    }
    
    init() {
        #if true
        let url = URL(string: "/path/to/mapstr.geojson")!
        #else
        let url = URL(string: "/path/to/file.dropin")!
        #endif
        coord = ImportFlowCoordinator(mode: .openFile(IdentifiableURL(url: url)))
    }
}

#Preview {
    MOCKImportPrepareView()
}

#endif
