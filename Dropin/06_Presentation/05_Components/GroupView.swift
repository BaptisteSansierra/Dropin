//
//  GroupView.swift
//  Dropin
//
//  Created by baptiste sansierra on 4/8/25.
//

import SwiftUI

/// SDGroup UI representation: bordered rounded rect text
struct GroupView: View {

    enum ActionType {
        case remove
        case edit
        case none
    }

    fileprivate enum GDispMod {
        case legacy
        case final
    }

    // MARK: - private vars
    private var name: String
    private var color: Color
    private var systemImage: String?
    private var action: (() -> Void)?
    private var actionType: ActionType
    private var mode: GDispMod = .final

    // MARK: - Body
    var body: some View {
        
        switch mode {
            case .legacy:
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .center) {
                        Text(name)
                            .font(.headline)
                            .padding(9)
                            .cornerRadius(5)
                            .overlay {
                                RoundedRectangle(cornerSize: CGSize(width: 6, height: 6))
                                    .stroke(color, lineWidth: 2)
                            }
                            .padding()
                    }
                    actionButton
                }
                .padding(.horizontal, 10)

            case .final:
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .center, spacing: 10) {
                        
                        if let systemImage = systemImage {
                            Image(systemName: systemImage)
                        }
                        Text(name)
                            .font(.headline)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .overlay {
                        ZStack {
                            GeometryReader { geom in
                                RoundedRectangle(cornerSize: 8)
                                    .stroke(color,
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                    .frame(width: geom.size.width,
                                           height: geom.size.height)
                                RoundedRectangle(cornerSize: 8)
                                    .stroke(color.opacity(0.5),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                    .offset(x: 1, y: 1)
                                    .frame(width: geom.size.width - 2,
                                           height: geom.size.height - 2)
                                RoundedRectangle(cornerSize: 8)
                                    .stroke(color.opacity(0.2),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                    .offset(x: 2, y: 2)
                                    .frame(width: geom.size.width - 4,
                                           height: geom.size.height - 4)
                            }
                        }
                    }
                    actionButton
                        .offset(x: 14, y: -14)
                }
                .padding(.horizontal, 10)
        }
    }
    
    private var removeButton: some View {
        IcoButton(systemImage: "multiply", icoSize: 10, icoColor: .red)
            .onTapGesture {
                action?()
            }
    }

    private var editButton: some View {
        IcoButton(systemImage: "ellipsis", icoSize: 10, icoColor: .dropinPrimary)
            .onTapGesture {
                action?()
            }
    }

    private var actionButton: some View {
        Group {
            switch actionType {
                case .remove:
                    removeButton
                case .edit :
                    editButton
                default:
                    EmptyView()
            }
        }
    }

    // MARK: - init
    init(name: String,
         color: Color,
         systemImage: String?,
         actionType: ActionType = .none,
         action: (() -> Void)? = nil) {
        self.name = name
        self.color = color
        self.systemImage = systemImage
        self.actionType = actionType
        self.action = action
    }

    fileprivate init(name: String,
                     color: Color,
                     systemImage: String?,
                     actionType: ActionType = .none,
                     action: (() -> Void)? = nil,
                     mode: GDispMod ) {
        self.name = name
        self.color = color
        self.systemImage = systemImage
        self.actionType = actionType
        self.action = action
        self.mode = mode
    }

    init(group: GroupUI,
         actionType: ActionType = .none,
         action: (() -> Void)? = nil) {
        self.name = group.name
        self.color = group.color
        self.systemImage = group.sfSymbol
        self.actionType = actionType
        self.action = action
    }
}

#Preview {
    VStack(spacing: 20) {
        GroupView(name: "Legacy",
                  color: .brown,
                  systemImage: "tag",
                  mode: .legacy)

        GroupView(name: "Nice Group",
                  color: .brown,
                  systemImage: "tag")

        GroupView(name: "No Mark",
                  color: .brown,
                  systemImage: nil,
                  actionType: .remove,
                  action: { print("Do the work") })

        GroupView(name: "Mark",
                  color: .brown,
                  systemImage: "carrot",
                  actionType: .edit,
                  action: { print("Eat a carrot") })

        PlaceAnnotationView(color: .brown, systemImage: "tag")
    }
}
