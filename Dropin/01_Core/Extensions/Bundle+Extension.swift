//
//  Bundle+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 19/11/26.
//

import Foundation

extension Bundle {
    
    // Do not return device's language but a language app supports
    static var appLanguage: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }
}

