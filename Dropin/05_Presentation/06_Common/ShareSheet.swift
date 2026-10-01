//
//  ShareSheet.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/4/26.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {

    let url: URL
    var message: String = ""
    var subject: String = ""
    var onComplete: ((Bool) -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let source = ShareItemSource(url: url, message: message, subject: subject)
        let vc = UIActivityViewController(activityItems: [source], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, completed, _, _ in
            onComplete?(completed)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {

    }
}

/// Combines the message + link into a single shared item, and supplies a
/// subject line — only actually used by activity types that have one (Mail).
private final class ShareItemSource: NSObject, UIActivityItemSource {
    private let url: URL
    private let message: String
    private let subject: String

    init(url: URL, message: String, subject: String) {
        self.url = url
        self.message = message
        self.subject = subject
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        url
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard !message.isEmpty else { return url }
        return "\(message)\n\(url.absoluteString)"
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        subject
    }
}
