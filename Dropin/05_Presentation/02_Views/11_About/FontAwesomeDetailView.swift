//
//  FontAwesomeDetailView.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/26.
//

import SwiftUI

struct FontAwesomeDetailView: View {

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("about.library.fontawesome.title")
                            .textStyle(.bodySemibold)
                        Text("fontawesome.detail.subtitle")
                            .textStyle(.cellSubtitle)
                        Text("fontawesome.detail.link")
                            .textStyle(.settingTitleAction)
                            .padding(.top, 8)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.surface1)
                            .stroke(.fieldBorder)
                    }

                    Text("fontawesome.detail.footnote")
                        .textStyle(.cellSubtitle)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
        .navigationTitle("fontawesome.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        FontAwesomeDetailView()
    }
}
#endif
