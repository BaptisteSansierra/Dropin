//
//  MapSettingsSheetView.swift
//  Dropin
//
//  Created by baptiste sansierra on 2/10/26.
//

import SwiftUI

struct MapSettingsSheetView: View {

    // MARK: - States & Bindings
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.surface1.ignoresSafeArea()
            VStack(spacing: 0) {
                headerView
                    .padding(.top)
                mapStyleView
                    .padding(.top, 20)
                mapPOIView
                    .padding(.top, 20)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        HStack {
            Text("map.settings.title")
                .textStyle(.title2Semibold)
            Spacer()
            Image(systemName: "multiply")
                .textStyle(.body)
                .padding()
                .background {
                    Circle()
                        .fill(.backgroundPrimary)
                }
                .onTapGesture {
                    dismiss()
                }
        }
    }

    private var mapStyleView: some View {
        VStack(alignment: .leading, spacing: 0) {
            @Bindable var appSettings = appSettings
            Text("map.settings.style")
                .textStyle(.footnoteSemibold, color: .textTertiary)
                .textCase(.uppercase)
                .padding(.bottom, 10)
            DropinSegmented(selection: $appSettings.mapSettings.mapType,
                            options: [(MapSettings.MapType.standard,
                                       LocalizedStringKey(MapSettings.MapType.standard.displayName)),
                                      (MapSettings.MapType.hybrid,
                                       LocalizedStringKey(MapSettings.MapType.hybrid.displayName)),
            ])
        }
        .padding(.horizontal, 4)
    }
    
    private var mapPOIView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("map.settings.poi")
                .textStyle(.footnoteSemibold, color: .textTertiary)
                .textCase(.uppercase)
                .padding(.bottom, 10)

            FlowLayout(alignment: .leading, spacingV: 10, spacingH: 0) {
                ForEach(POIBundle.allCases) { b in

                    let selected = appSettings.mapSettings.poiConfig.contains(b)
                    let borderColor: Color = selected ? .dropinPrimary : .fieldBorder
                    let bgColor: Color = selected ? .dropinPrimary.opacity(0.15) : .backgroundPrimary
                    let txtColor: Color = selected ? .dropinPrimary : .textSecondary
                    let borderW: CGFloat = selected ? 2 : 1
                    
                    HStack(spacing: 0) {
                        Image(systemName: b.symbol)
                            .textStyle(.subheadline, color: txtColor)
                            .padding(.leading, 15)
                            .padding(.trailing, 10)
                        Text(b.displayName)
                            .textStyle(.subheadline, color: txtColor)
                        .padding(.trailing, 15)
                    }
                    .frame(height: 40)
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(bgColor)
                            .stroke(borderColor, lineWidth: borderW)
                    }
                    .padding(.trailing, 10)
                    .onTapGesture {
                        if selected {
                            appSettings.mapSettings.poiConfig.remove(b)
                        } else {
                            appSettings.mapSettings.poiConfig.insert(b)
                        }
                    }
                }
            }
            
            Text("Shown on the map to help you find your way. Your places always stay visible.")
                .textStyle(.subheadline, color: .textTertiary)
                .padding(.top)

        }
        .padding(.horizontal, 4)
    }}


#Preview {
    MapSettingsSheetView()
        .environment(AppSettings())
}
