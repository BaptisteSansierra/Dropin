#if false

import SwiftUI
import MapKit

struct MapConfigPreviewView: View {
    //@ObservedObject var viewModel: SettingsViewModel
    
    @State private var mapRegion = MKCoordinateRegion.abbeyRoad
    @Environment(AppSettings.self) private var appSettings
    
    @Binding private var mapEditMode: MapEditSettingsMode
    
    init(mapEditMode: Binding<MapEditSettingsMode>) {
        self._mapEditMode = mapEditMode
    }
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            map
            overlayControls
            
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray5), lineWidth: 0.5)
        )
    }

    // MARK: - Map

    private var map: some View {
        Map(coordinateRegion: .constant(mapRegion), annotationItems: [previewAnnotation]) { _ in
            MapAnnotation(coordinate: mapRegion.center) {
                PinView(
                    style: appSettings.pinStyle,
                    size: appSettings.pinSize
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: appSettings.pinSize)
                .animation(.easeInOut(duration: 0.2), value: appSettings.pinStyle)
            }
        }
        .disabled(true)  // preview only
    }

    private var previewAnnotation: IdentifiableCoordinate {
        IdentifiableCoordinate(coordinate: mapRegion.center)
    }

    // MARK: - Overlay controls

    @ViewBuilder
    private var overlayControls: some View {
        VStack(spacing: 0) {
            switch mapEditMode {
                case .size:
                    sizeSlider
                case .style:
                    styleButtons
                case .none:
                    EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 12)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .padding(12)
    }

    // MARK: Size slider

    private var sizeSlider: some View {
        HStack(spacing: 12) {
            @Bindable var appSettings = appSettings
            Image(systemName: "mappin")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Slider(
                value: $appSettings.pinSize,
                in: AppSettings.pinSizeRange,
                step: 1
            )
            Image(systemName: "mappin")
                .font(.system(size: 19))
                .foregroundStyle(.secondary)
            Text("\(Int(appSettings.pinSize))")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
    }

    // MARK: Style buttons

    private var styleButtons: some View {
        HStack(spacing: 10) {
            ForEach(PinStyle.allCases, id: \.id) { style in
                
                Button {
                    appSettings.pinStyle = style
                } label: {
                    HStack(spacing: 8) {
                        PinView(style: style, size: 20)
                        Text("\(style)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        appSettings.pinStyle == style
                            ? Color.accentColor.opacity(0.12)
                            : Color(.systemBackground).opacity(0.6)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                appSettings.pinStyle == style
                                    ? Color.accentColor
                                    : Color(.systemGray4),
                                lineWidth: appSettings.pinStyle == style ? 1.5 : 0.5
                            )
                    )
                }
                .foregroundStyle(
                    appSettings.pinStyle == style ? Color.accentColor : .primary
                )
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: appSettings.pinStyle)
            }
        }
    }
}

// MARK: - Helpers

private struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    @Previewable @State var mapEditMode = MapEditSettingsMode.none

    MapConfigPreviewView(mapEditMode: $mapEditMode)
        .environment(AppSettings())
}

#endif
