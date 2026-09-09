//
//  PrivacyPolicyView.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/26.
//

import SwiftUI

struct PrivacyPolicyView: View {

    // Bump this whenever the copy below changes.
    private static let lastUpdated: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 30
        return Calendar.current.date(from: components) ?? Date()
    }()

    private var lastUpdatedString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Self.lastUpdated)
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("privacy.last_updated_\(lastUpdatedString)")
                        .textStyle(.caption2)

                    VStack(alignment: .leading, spacing: 14) {
                        //Text("privacy.body.intro")
                        //    .textStyle(.body)

                        paragraph(title: "privacy.body.what_we_collect.title",
                                 body: "privacy.body.what_we_collect.body")
                        paragraph(title: "privacy.body.account_data.title",
                                 body: "privacy.body.account_data.body")
                        paragraph(title: "privacy.body.analytics.title",
                                 body: "privacy.body.analytics.body")
                        paragraph(title: "privacy.body.your_rights.title",
                                 body: "privacy.body.your_rights.body")
                        paragraph(title: "privacy.body.terms.title",
                                 body: "privacy.body.terms.body")

                        Text("privacy.body.contact_\(contactEmailText)")
                            .textStyle(.cellSubtitle)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
        .navigationTitle("privacy.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contactEmailText: Text {
        Text(verbatim: DropinApp.strings.contact)
            .font(TextStyle.cellSubtitle.font.weight(.semibold))
            .foregroundStyle(Color.dropinPrimary)
    }

    private func paragraph(title: LocalizedStringKey,
                           body: LocalizedStringKey) -> some View {
        (
        Text(title)
            .font(TextStyle.bodySemibold.font)
            .foregroundStyle(TextStyle.bodySemibold.color)
        + Text(" ")
        + Text(body)
            .font(TextStyle.body.font)
            .foregroundStyle(TextStyle.body.color)
        )
        .lineSpacing(3)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
#endif
