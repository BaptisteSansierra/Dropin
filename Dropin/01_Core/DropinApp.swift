//
//  DropinApp.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/7/25.
//

import SwiftUI

// Note:
// - 'Infer Sendable for Methods and Key Path Literals' set to Yes to avoid SortDescriptor warning (swift6 concurrency) cf. https://stackoverflow.com/questions/79000052/fetchdescriptor-including-sortdescriptor-returns-warning-in-xcode16


@MainActor
@Observable final class AppContext {
    var currentSideMenuContext: SideMenuContext = .main
}

@main
struct DropinApp: App {

    // MARK: - Properties
    @State private var vm = DropinAppModel()

    // MARK: - Body
    var body: some Scene {
        WindowGroup {

            #if false
            MockMapstrCategoriesView()
                .environment(AppSettings())
            #else

            rootContent
                .task {
                    await vm.launch()
                }
                .onOpenURL { url in
                    vm.open(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    vm.willEnterForeground()
                }
                .environment(vm.appSettings)
                #if DEBUG
                .preferredColorScheme(ScreenshotMode.isOn ? ScreenshotMode.colorScheme : nil)
                #endif
            #endif
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch vm.appContainer.authState {
            case .loading:
                SplashView()
            case .signedOut:
                vm.appContainer.createSignInView()
                    // A file opened during the session restore can't be imported
                    .onAppear {
                        vm.signedOutAppeared()
                    }
            case .signedIn(let signingOut):
                ZStack {
                    vm.appContainer.createRootView()
                        .task {
                            await vm.appContainer.loadProfile()
                            await vm.appContainer.startSync()
                        }
                    ZStack {
                        Color.overlayAlphaLayer
                        DropinLoader(style: .overlay, caption: "auth.clearing")
                    }
                    .ignoresSafeArea()
                    .opacity(signingOut ? 1 : 0)
                }
                // A file opened during the session restore (cold launch from Files...) is presented now
                .onAppear {
                    vm.signedInAppeared()
                }
                .onChange(of: signingOut) {
                    if signingOut { vm.signOutStarted() }
                }
        }
    }
}

// MARK: - app icon utils
extension UIApplication {
    static func setApplicationIconWithoutAlert(_ iconName: String?) {
        guard UIApplication.shared.responds(to: #selector(getter: UIApplication.supportsAlternateIcons)) && UIApplication.shared.supportsAlternateIcons else { return }
        typealias setAlternateIconNameClosure = @convention(c) (NSObject, Selector, NSString?, @escaping (NSError) -> ()) -> ()
        let selectorString = "_setAlternateIconName:completionHandler:"
        let selector = NSSelectorFromString(selectorString)
        let imp = UIApplication.shared.method(for: selector)
        let method = unsafeBitCast(imp, to: setAlternateIconNameClosure.self)
        method(UIApplication.shared, selector, iconName as NSString?, { _ in })
    }
}
