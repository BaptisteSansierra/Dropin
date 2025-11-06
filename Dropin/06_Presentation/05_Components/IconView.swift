//
//  IconView.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/11/25.
//

import SwiftUI

struct IconView: View {
    let icon: Icon
    
    var body: some View {
        Group {
            switch icon.source {
                case .sf:
                    Image(systemName: icon.name)
                    
                case .fa:
                    Image(icon.name)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                case .invalid:
                    Image(systemName: "questionmark.circle")
            }
        }
    }

    @ViewBuilder
    func sizeLargeTitle() -> some View {
        switch icon.source {
            case .sf:
                font(.largeTitle)
            default:
                frame(width: 34, height: 34)
        }
    }
    
    @ViewBuilder
    func sizeTitle() -> some View {
        switch icon.source {
            case .sf:
                font(.title)
            default:
                frame(width: 30, height: 30)
        }
    }
    
    @ViewBuilder
    func sizeBody() -> some View {
        switch icon.source {
            case .sf:
                font(.body)
            default:
                frame(width: 18, height: 18)
        }
    }
    
    @ViewBuilder
    func sizeCaption() -> some View {
        switch icon.source {
            case .sf:
                font(.caption)
            default:
                frame(width: 14, height: 14)
        }
    }

    @ViewBuilder
    func sizeCaption2() -> some View {
        switch icon.source {
            case .sf:
                font(.caption2)
            default:
                frame(width: 12, height: 12)
        }
    }

    @ViewBuilder
    func sizeXS() -> some View {
        switch icon.source {
            case .sf:
                font(.system(size: 8))
            default:
                frame(width: 8, height: 8)
        }
    }
}

#Preview {
    
    let ic1 = Icon(source: .fa, name: "bowl-rice")
    //let ic2 = Icon(source: .fa, name: "bowl-rice-wire")
    let ic3 = Icon(source: .sf, name: "birthday.cake")

    VStack {
        IconView(icon: ic1)
            .frame(width: 34, height: 34)
        IconView(icon: ic3)
            .font(.largeTitle)
        Divider()
        IconView(icon: ic1)
            .frame(width: 30, height: 30)
        IconView(icon: ic3)
            .font(.title)
        Divider()
        IconView(icon: ic1)
            .frame(width: 18, height: 18)
        IconView(icon: ic3)
            .font(.body)
        Divider()
        Text("callout")
        IconView(icon: ic1)
            .frame(width: 16, height: 16)
        IconView(icon: ic3)
            .font(.callout)
        Divider()
        IconView(icon: ic1)
            .frame(width: 14, height: 14)
        IconView(icon: ic3)
            .font(.caption)
        Divider()
        IconView(icon: ic1)
            .frame(width: 12, height: 12)
        IconView(icon: ic3)
            .font(.caption2)
        Divider()
        Text("XS")
        IconView(icon: ic1)
            .sizeXS()
        IconView(icon: ic3)
            .sizeXS()
    }
    
}
