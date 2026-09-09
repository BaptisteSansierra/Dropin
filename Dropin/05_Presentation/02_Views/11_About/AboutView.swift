//
//  AboutView.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/26.
//

import SwiftUI

struct AboutView: View {

    // MARK: - States & Bindings
    @State private var viewModel: AboutViewModel
    @Binding private var showingSideMenu: Bool

    // MARK: - Init
    init(viewModel: AboutViewModel, showingSideMenu: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSideMenu = showingSideMenu
    }

    // MARK: - Body
    var body: some View {
        NavigationStack(path: $viewModel.coordinator.path) {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        brandBlock
                        pitchCard
                        librariesSection
                        legalSection
                        contactSection
                        footer
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal)
                .scrollIndicators(.hidden)
            }
            .navigationTitle("common.about")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DropinToolbar.Burger(showingSideMenu: $showingSideMenu)
            }
            .navigationDestination(for: AboutNavigationItem.self) { item in
                resolveDestination(item)
            }
        }
    }

    // MARK: - subviews
    private var brandBlock: some View {
        VStack(spacing: 8) {
            DropinLogo(variant: .logo,
                       lineWidthMuliplier: 2,
                       pinSizeMuliplier: 1.5)
                .frame(width: 56, height: 56)
            Text(verbatim: DropinApp.strings.app)
                .textStyle(.title2Semibold)
            Text("about.version_\(viewModel.appVersion)_\(viewModel.appBuild)")
                .textStyle(.caption)
        }
    }

    private var pitchCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("about.pitch")
                .textStyle(.subheadline)

            VStack(alignment: .leading, spacing: 12) {
                pitchRow(icon: "heart",
                        iconColor: .dropinPrimary,
                        title: "about.data_yours.title",
                        body: "about.data_yours.body")
                pitchRow(icon: "nosign",
                        iconColor: .destructive,
                        title: "about.no_ads.title",
                        body: "about.no_ads.body")
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.surface1)
                .stroke(.fieldBorder)
        }
    }

    private func pitchRow(icon: String,
                          iconColor: Color,
                          title: LocalizedStringKey,
                          body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconBadge(systemName: icon, color: iconColor.opacity(0.12), badgeColor: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textStyle(.subheadlineSemibold)
                Text(body)
                    .textStyle(.cellSubtitle)
            }
        }
    }

    private var librariesSection: some View {
        VStack(spacing: 0) {
            Text("about.section.libraries")
                .textStyle(.formSectionTitle)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                Button {
                    viewModel.pushFontAwesomeDetailView()
                } label: {
                    HStack {
                        libraryRow(title: "about.library.fontawesome.title",
                                  subtitle: "about.library.fontawesome.subtitle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .textStyle(.settingValue)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.vertical, 13)

                rowSeparator

                libraryRow(title: "about.library.sfsymbols.title",
                           subtitle: "about.library.sfsymbols.subtitle")
                    .padding(.horizontal)
                    .padding(.vertical, 13)
            }
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
            }
        }
    }

    private func libraryRow(title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .textStyle(.bodySemibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(subtitle)
                .textStyle(.cellSubtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var legalSection: some View {
        VStack(spacing: 0) {
            Text("about.section.legal")
                .textStyle(.formSectionTitle)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            HStack {
                Text("about.privacy_policy")
                    .textStyle(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .textStyle(.cardFooter)
            }
            .padding(.horizontal)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
            }
            .onTapGesture {
                viewModel.pushPrivacyPolicyView()
            }

            Text("about.privacy_policy.caption")
                .textStyle(.cellSubtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                .padding(.leading, 4)
        }
    }

    private var contactSection: some View {
        VStack(spacing: 0) {
            Text("about.section.contact")
                .textStyle(.formSectionTitle)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            Button {
                openContactEmail()
            } label: {
                HStack(spacing: 0) {
                    Image(systemName: "envelope")
                        .textStyle(.settingTitleAction)
                        .padding(.trailing, 10)
                    Text(verbatim: DropinApp.strings.contact)
                        .textStyle(.settingTitleAction)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.surface1)
                    .stroke(.fieldBorder)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("about.footer.made_with_care")
                .textStyle(.caption2)
            Text("about.footer.copyright_\(viewModel.copyrightYear)")
                .textStyle(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private var rowSeparator: some View {
        Rectangle()
            .fill(.fieldBorder)
            .frame(height: 1)
            .padding(.leading, 16)
    }

    @ViewBuilder
    private func iconBadge(systemName: String,
                           color: Color,
                           badgeColor: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(color)
                .frame(width: 30, height: 30)
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(badgeColor)
        }
    }

    private func openContactEmail() {
        guard let url = URL(string: "mailto:\(DropinApp.strings.contact)") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - navigation
    @ViewBuilder
    private func resolveDestination(_ item: AboutNavigationItem) -> some View {
        switch item {
            case .privacyPolicy:
                PrivacyPolicyView()
            case .fontAwesomeDetail:
                FontAwesomeDetailView()
        }
    }
}

#if DEBUG
struct MockAboutView: View {
    @State private var showingSideMenu: Bool = false
    var mock: MockContainer

    var body: some View {
        mock.appContainer.createAboutView(showingSideMenu: $showingSideMenu)
    }

    init() {
        self.mock = MockContainer()
    }
}

#Preview {
    MockAboutView()
}
#endif
