//
//  CenteredLabelStyle.swift
//  Dropin
//
//  Created by baptiste sansierra on 15/4/26.
//

import SwiftUI

struct CenteredLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 0) {
            configuration.icon
                .font(.subheadlineRegular)
                .frame(height: 15)
                .padding(.bottom, 5)
            configuration.title
                .font(.footnoteRegular)
        }
    }
}
