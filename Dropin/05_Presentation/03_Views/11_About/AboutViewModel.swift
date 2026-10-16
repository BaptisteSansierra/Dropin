//
//  AboutViewModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/26.
//

import SwiftUI

@MainActor
@Observable class AboutViewModel {

    var coordinator: AboutCoordinator

    init(coordinator: AboutCoordinator) {
        self.coordinator = coordinator
    }

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }

    var copyrightYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    func pushPrivacyPolicyView() {
        coordinator.pushPrivacyPolicyView()
    }

    func pushFontAwesomeDetailView() {
        coordinator.pushFontAwesomeDetailView()
    }
}
