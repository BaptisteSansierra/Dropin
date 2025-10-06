//
//  SideMenuContentView.swift
//  Dropin
//
//  Created by baptiste sansierra on 13/8/25.
//
#if false

import SwiftUI

struct SideMenuContentView: View {
    
    // MARK: - Dependencies
    //@Environment(\.self) var env

    // MARK: - private vars
    private var appVersion: String = ""
    private var appBuild: String = ""

    // MARK: - Body
    var body: some View {
        VStack() {
            HStack {
                ZStack(alignment: .center) {
                    Circle()
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                    DropinLogo(lineWidthMuliplier: 2, pinSizeMuliplier: 1.5)
                        .frame(width: 50, height: 50)
                }
                .padding(.top, 70)
                .padding(.leading, 25)
                .padding(.bottom, 25)
                Spacer()
            }
//            .onTapGesture {
//                print("ENV  TYPE : \(type(of: env))")
//                print("ENV : \(env)")
//            }
            SideMenuItemView(label: "common.places",
                             systemImage: "globe.europe.africa.fill",
                             context: .main)
            SideMenuItemView(label: "common.groups",
                             systemImage: "folder",
                             context: .groups)
            SideMenuItemView(label: "common.tags",
                             systemImage: "tag",
                             context: .tags)
            Spacer()
            HStack {
                Text("_NOTTR_v\(appVersion)(\(appBuild))")
                    .padding()
                    .font(.caption)
                    .fontWeight(.black)
            }
            .padding(.bottom, 30)
        }
        .background {
            LinearGradient(gradient: Gradient(colors: [.dropinPrimary.darken(factor: 0.1),
                                                       .dropinPrimary,
                                                       .dropinPrimary.lighten(factor: 0.1),
                                                       .dropinPrimary.lighten(factor: 0.2),
                                                       .dropinPrimary.lighten(factor: 0.9)]),
                           startPoint: .top,
                           endPoint: .bottom)
        }
    }

    // MARK: - init
    init() {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            appVersion = version
        }
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            appBuild = build
        }
    }
}
#endif
