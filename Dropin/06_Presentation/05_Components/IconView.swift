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
        switch icon {
            case .sf(let name):
                Image(systemName: name)
            case .fa(let name):
                Image(name)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
        }
    }
    
    @ViewBuilder
    func size(_ size: CGFloat) -> some View {
        switch icon {
            case .sf:
                font(Font.system(size: size))
            default:
                frame(width: size, height: size)
        }
    }

    @ViewBuilder
    func sizeLargeTitle() -> some View {
        switch icon {
            case .sf:
                font(.largeTitle)
            default:
                frame(width: 34, height: 34)
        }
    }
    
    @ViewBuilder
    func sizeTitle() -> some View {
        switch icon {
            case .sf:
                font(.title)
            default:
                frame(width: 30, height: 30)
        }
    }
    
    @ViewBuilder
    func sizeBody() -> some View {
        switch icon {
            case .sf:
                font(.body)
            default:
                frame(width: 18, height: 18)
        }
    }
    
    @ViewBuilder
    func sizeCaption() -> some View {
        switch icon {
            case .sf:
                font(.caption)
            default:
                frame(width: 14, height: 14)
        }
    }

    @ViewBuilder
    func sizeCaption2() -> some View {
        switch icon {
            case .sf:
                font(.caption2)
            default:
                frame(width: 12, height: 12)
        }
    }

    @ViewBuilder
    func sizeXS() -> some View {
        switch icon {
            case .sf:
                font(.system(size: 8))
            default:
                frame(width: 8, height: 8)
        }
    }
}

#Preview {
    
    let ic1: Icon = .fa("bowl-rice")
    //let ic2 = .fa("bowl-rice-wire")
    let ic3: Icon = .sf("birthday.cake")

    VStack {
        IconView(icon: ic1)
            .size(50)
        IconView(icon: ic3)
            .size(50)
        Divider()
        
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
