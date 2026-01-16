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

    // MARK: - private vars
    private var name: String
    private var color: Color
    private var icon: Icon?
    private var action: (() -> Void)?
    private var actionType: ActionType

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 10) {
                if let icon = icon {
                    IconView(icon: icon)
                        .sizeBody()
                }
                Text(name)
                    .textStyle(.groupSticker)
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
    
    private var removeButton: some View {
        IcoButton(systemImage: "multiply", icoSize: 10, icoColor: .destructive)
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
         icon: Icon?,
         actionType: ActionType = .none,
         action: (() -> Void)? = nil) {
        self.name = name
        self.color = color
        self.icon = icon
        self.actionType = actionType
        self.action = action
    }

    init(group: GroupUI,
         actionType: ActionType = .none,
         action: (() -> Void)? = nil) {
        self.name = group.name
        self.color = group.color
        self.icon = group.icon
        self.actionType = actionType
        self.action = action
    }
}

#Preview {
    VStack(spacing: 20) {
        GroupView(name: "Nice Group",
                  color: .brown,
                  icon: .sf("tag"))

        GroupView(name: "No Mark",
                  color: .brown,
                  icon: nil,
                  actionType: .remove,
                  action: { print("Do the work") })

        GroupView(name: "Mark",
                  color: .brown,
                  icon: .sf("carrot"),
                  actionType: .edit,
                  action: { print("Eat a carrot") })

        PlaceAnnotationView(color: .brown, icon: .sf("tag"))
    }
}
