//
//  SideMenuView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/8/25.
//

import SwiftUI

struct SideMenuView: View {
    
    // MARK: - Dependencies
    @Environment(NavigationContext.self) var navigationContext

    // MARK: - private vars
    private var edgeTransition: AnyTransition = .move(edge: .leading)
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            if navigationContext.showingSideMenu {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        navigationContext.showingSideMenu.toggle()
                    }
                
                HStack {
                    ZStack{
                        Rectangle()
                            .fill(.white)
                            .frame(width: 270)
                            .shadow(color: .black, radius: 5, x: 0, y: 3)

                        SideMenuContentView()
                            .frame(width: 270)
                            .background(.white)
                    }
                    .background(.clear)
                    Spacer()
                }
                .background(.clear)
                .transition(edgeTransition)
            }
        }
        .gesture(leftSwipeGesture)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
        .animation(.easeInOut, value: navigationContext.showingSideMenu)
    }
    
    // MARK: - Subviews
    private var leftSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global).onEnded { value in
            let horizontalAmount = value.translation.width
            let verticalAmount = value.translation.height
            guard abs(horizontalAmount) > abs(verticalAmount) && horizontalAmount < 0 else { return }
            navigationContext.showingSideMenu = false
        }
    }
}
