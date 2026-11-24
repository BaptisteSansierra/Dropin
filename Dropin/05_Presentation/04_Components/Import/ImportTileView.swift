//
//  ImportTileView.swift
//  Dropin
//
//  Created by baptiste sansierra on 11/11/26.
//

import SwiftUI

struct ImportTileView: View {
    
    var source: ImportSource
    
    // MARK: Body
    var body: some View {
        switch source {
            case .dropin:
                dropinTile
            case .mapstr:
                mapstrTile
            case .google:
                googleTile
            case .unknown:
                unknownTile
        }
    }
    
    // MARK: Subviews
    private var dropinTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.surface1)
                .stroke(.hairline)
                .frame(width: 45, height: 45)
            DropinLogo(lineWidthMuliplier: 1)
                .frame(width: 35, height: 35)
        }
    }
    
    private var mapstrTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.mapstrPrimary)
                .frame(width: 45, height: 45)
            Circle()
                .fill(.surface1)
                .frame(width: 35, height: 35)
            Image(systemName: "number")
                .font(.system(size: 16))
                .fontWeight(.bold)
                .foregroundStyle(.mapstrPrimary)
        }
    }
    
    private var unknownTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.tileNeutral)
                .frame(width: 45, height: 45)
            Image(systemName: "questionmark.text.page") // ? text.page
                .font(.system(size: 20))
                .fontWeight(.regular)
                .foregroundStyle(.surface1)
        }
    }
    
    private var googleTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.surface1)
                .stroke(.hairline)
            HStack(spacing: 3) {
                ForEach(Array(Self.googleBars.enumerated()), id: \.offset) { _, color in
                    Capsule()
                        .fill(color)
                        //.frame(width: 4, height: 15)
                        .frame(height: 15)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 3)
        }
        .frame(width: 45, height: 45)
    }

    private static let googleBars: [Color] = [
        Color(rgba: "3F78C9"), // blue
        Color(rgba: "D35A48"), // red
        Color(rgba: "5FA64A"), // green
        Color(rgba: "3F78C9"), // blue
        Color(rgba: "E9B83C"), // yellow
        Color(rgba: "D35A48"), // red
    ]
}

#Preview {
    
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()
        VStack {
            HStack {
                ImportTileView(source: .dropin)
                Spacer()
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.surface1)
                    .stroke(.hairline)
            }

            HStack {
                ImportTileView(source: .mapstr)
                Spacer()
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.surface1)
                    .stroke(.hairline)
            }

            HStack {
                ImportTileView(source: .google)
                Spacer()
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.surface1)
                    .stroke(.hairline)
            }

            HStack {
                ImportTileView(source: .unknown)
                Spacer()
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.surface1)
                    .stroke(.hairline)
            }
        }
        .padding(.horizontal)
    }
}
