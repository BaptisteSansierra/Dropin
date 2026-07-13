//
//  SideMenuItemView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//

import SwiftUI

struct SideMenuItemView: View {

    // MARK: - States & Bindings
    @Binding var showingSideMenu: Bool
    @Binding var currentSideMenuContext: SideMenuContext

    // MARK: - private properties
    private var label: LocalizedStringKey
    private var systemImage: String
    private var context: SideMenuContext
        
    // MARK: - init
    init(label: LocalizedStringKey,
         systemImage: String,
         context: SideMenuContext,
         showingSideMenu: Binding<Bool>,
         currentSideMenuContext: Binding<SideMenuContext>) {
        self.label = label
        self.systemImage = systemImage
        self.context = context
        self._showingSideMenu = showingSideMenu
        self._currentSideMenuContext = currentSideMenuContext
    }

    // MARK: - Body
    var body: some View {
        VStack {
            ZStack {
                selectionOverlayView
                rowContentView
            }
            .contentShape(Rectangle())
            .onTapGesture {
                print("🔵 tap assigning → \(context)")

                currentSideMenuContext = context
                
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    print("Keep menu visible in canvas")
                } else {
                    showingSideMenu = false
                }
            }
        }
    }
    
    private var selectionOverlayView: some View {
        Rectangle()
            .foregroundStyle(Color.dropinPrimary)
            .opacity(context == currentSideMenuContext ? 0.2 : 0)
            .padding(.horizontal, 0)
    }
    
    private var rowContentView: some View {
        HStack(alignment: .center, spacing: 0) {
            Rectangle()
                .fill(.dropinPrimary)
                .frame(width: 3)
                .opacity(context == currentSideMenuContext ? 1 : 0)

            ZStack(alignment: .center) {
                Rectangle()
                    .strokeBorder(.pink, style: StrokeStyle(lineWidth: 2))
                    .frame(width: 90, height: 44)
                    .opacity(0)
                Image(systemName: systemImage)
                    .font(.bodyLight)
                    //.font(context == currentSideMenuContext ? .bodyMedium : .bodyLight)
                    .foregroundStyle(context == currentSideMenuContext ? .dropinPrimary : .textPrimary)
            }
            Text(label)
                .font(context == currentSideMenuContext ? .bodyMedium : .bodyLight)
                .foregroundStyle(.textPrimary)
            Spacer()
        }
    }
}


#if DEBUG
    
struct MockSideMenuItemView: View {

    @State var name: LocalizedStringKey
    @State var systemImage: String
    @State var sideMenuContext: SideMenuContext
    @Binding var showingSideMenu: Bool
    @Binding var currentSideMenuContext: SideMenuContext

    var body: some View {
        SideMenuItemView(label: name,
                         systemImage: systemImage,
                         context: sideMenuContext,
                         showingSideMenu: $showingSideMenu,
                         currentSideMenuContext: $currentSideMenuContext)
    }

    init(name: LocalizedStringKey,
         systemImage: String,
         sideMenuContext: SideMenuContext,
         showingSideMenu: Binding<Bool>,
         currentSideMenuContext: Binding<SideMenuContext>) {
        self.name = name
        self.systemImage = systemImage
        self.sideMenuContext = sideMenuContext
        self._showingSideMenu = showingSideMenu
        self._currentSideMenuContext = currentSideMenuContext
    }
}
    
#Preview {
    @Previewable @State var showingSideMenu: Bool = false
    @Previewable @State var currentSideMenuContext: SideMenuContext = .main

    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()
        VStack {
            MockSideMenuItemView(name: "Polenta",
                                 systemImage: "cursorarrow.rays",
                                 sideMenuContext: .main,
                                 showingSideMenu: $showingSideMenu,
                                 currentSideMenuContext: $currentSideMenuContext)
            .frame(height: 60)
            MockSideMenuItemView(name: "Pomelo",
                                 systemImage: "warninglight",
                                 sideMenuContext: .tags,
                                 showingSideMenu: $showingSideMenu,
                                 currentSideMenuContext: $currentSideMenuContext)
            .frame(height: 60)
            MockSideMenuItemView(name: "Porcherie",
                                 systemImage: "eraser",
                                 sideMenuContext: .groups,
                                 showingSideMenu: $showingSideMenu,
                                 currentSideMenuContext: $currentSideMenuContext)
            .frame(height: 60)
        }
    }
}
#endif

