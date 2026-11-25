//
//  UIApplication+Extension.swift
//  Dropin
//
//  Created by baptiste sansierra on 25/3/26.
//

import UIKit

extension UIApplication {
    
    static func dismissKeyboard() {
        UIApplication.shared
            .sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    static func rootBottomSafeArea() -> CGFloat {
        shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0
    }

    static func rootTopSafeArea() -> CGFloat {
        shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.top ?? 0
    }
}
