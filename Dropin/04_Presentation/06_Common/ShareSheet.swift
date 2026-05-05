//
//  ShareSheet.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/4/26.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {

    let url: URL
    var onComplete: ((Bool) -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, completed, _, _ in
            onComplete?(completed)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
