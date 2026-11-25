//
//  KeyboardObserver.swift
//  Dropin
//
//  Created by baptiste sansierra on 9/4/26.
//

import UIKit
import Combine

@MainActor
@Observable final class KeyboardObserver {
    
    private(set) var height: CGFloat = 0
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .sink(receiveValue: { [weak self] notif in
                guard let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    assertionFailure("Undefined rect")
                    return
                }
                DispatchQueue.main.async {
                    let screenHeight = UIScreen.main.bounds.height
                    self?.height = max(0, screenHeight - frame.origin.y)
                }
            })
    }
}
