//
//  SideMenuItemView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI

struct SideMenuItemView: View {

    // MARK: - States & Bindings
    @Binding var currentSideMenuContext: SideMenuContext
    
    // MARK: - Dependencies
    @Environment(NavigationContext.self) var navigationContext

    // MARK: - private properties
    private var label: LocalizedStringKey
    private var systemImage: String
    private var context: SideMenuContext
//    private var textColor: Color {
//        return context == currentSideMenuContext ? .white : .black
//    }
    private let textColor: Color = .black
        
    // MARK: - Body
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    //.cornerRadius(40)
                    .foregroundStyle(Color.gray.opacity(0.2))
                    .opacity(context == currentSideMenuContext ? 1 : 0)
                    .padding(.horizontal, 0)
                
                HStack(alignment: .center, spacing: 0) {
                    ZStack(alignment: .center) {
                        Rectangle()
                            .strokeBorder(.red, style: StrokeStyle(lineWidth: 2))
                            .frame(width: 100, height: 50)
                            .opacity(0)
                        Image(systemName: systemImage)
                            .font(.headline)
                            .foregroundStyle(textColor)
                    }
                    Text(label)
                        .font(.headline)
                        .foregroundStyle(textColor)
                    Spacer()
                }
            }
            .onTapGesture {
                currentSideMenuContext = context
                navigationContext.showingSideMenu = false
            }
        }
    }
    
    // MARK: - init
    init(label: LocalizedStringKey,
         systemImage: String,
         context: SideMenuContext,
         currentSideMenuContext: Binding<SideMenuContext>) {
        self.label = label
        self.systemImage = systemImage
        self.context = context
        self._currentSideMenuContext = currentSideMenuContext
    }
}


#if DEBUG
    
struct MockSideMenuItemView: View {

    @State var name: LocalizedStringKey
    @State var systemImage: String
    @State var sideMenuContext: SideMenuContext
    @Binding var currentSideMenuContext: SideMenuContext

    var body: some View {
        SideMenuItemView(label: name,
                         systemImage: systemImage,
                         context: sideMenuContext,
                         currentSideMenuContext: $currentSideMenuContext)
    }

    init(name: LocalizedStringKey,
         systemImage: String,
         sideMenuContext: SideMenuContext,
         currentSideMenuContext: Binding<SideMenuContext>) {
        self.name = name
        self.systemImage = systemImage
        self.sideMenuContext = sideMenuContext
        self._currentSideMenuContext = currentSideMenuContext
    }
}
    
#Preview {
    @Previewable @State var currentSideMenuContext: SideMenuContext = .main

    VStack {
        MockSideMenuItemView(name: "Polenta",
                             systemImage: "cursorarrow.rays",
                             sideMenuContext: .main,
                             currentSideMenuContext: $currentSideMenuContext)
        .frame(height: 60)
        MockSideMenuItemView(name: "Pomelo",
                             systemImage: "warninglight",
                             sideMenuContext: .tags,
                             currentSideMenuContext: $currentSideMenuContext)
        .frame(height: 60)
        MockSideMenuItemView(name: "Porcherie",
                             systemImage: "eraser",
                             sideMenuContext: .groups,
                             currentSideMenuContext: $currentSideMenuContext)
        .frame(height: 60)
    }
    .environment(NavigationContext())
}
#endif

