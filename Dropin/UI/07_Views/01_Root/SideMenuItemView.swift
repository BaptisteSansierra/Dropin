//
//  SideMenuItemView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI

struct SideMenuItemView: View {

    // MARK: - Dependencies
    @Environment(NavigationContext.self) var navigationContext

    // MARK: - private vars
    private var label: String
    private var systemImage: String
    private var context: NavigationContext.SideMenuContext
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .center) {
                    Rectangle()
                        //.strokeBorder(.red, style: StrokeStyle(lineWidth: 2))
                        .frame(width: 100, height: 50)
                        .opacity(0)
                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                Text(label)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            .frame(height: 75)
            .onTapGesture {
                navigationContext.currentSideMenuContext = context
                navigationContext.showingSideMenu = false
            }
        }
    }
    
    // MARK: - init
    init(label: String, systemImage: String, context: NavigationContext.SideMenuContext) {
        self.label = label
        self.systemImage = systemImage
        self.context = context
    }
}
