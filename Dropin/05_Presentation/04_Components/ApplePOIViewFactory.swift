//
//  ApplePOIViewFactory.swift
//  Dropin
//
//  Created by baptiste sansierra on 7/10/26.
//

import SwiftUI

@MainActor
struct ApplePOIViewFactory {
    
    private static var imageStyle = TextStyle.body
    private static var imageColor = Color.textSecondary
    private static var textStyle = TextStyle.subheadline
    private static var textColor = Color.textSecondary
    private static var textLinkColor = Color.dropinSecondary

    static func applePOINativeBtView(onTap: @escaping () -> Void ) -> some View {
        HStack() {
            TextButton(text: "common.apple_maps_details",
                       textStyle: TextStyle.footnoteMedium,
                       preSystemImage: "map",
                       preSystemImageFont: .footnoteMedium,
                       postSystemImage: "chevron.right",
                       postSystemImageFont: .footnoteMedium,
                       foreground: .dropinPrimary,
                       action: onTap)
            Spacer()
        }
    }
    
    static func fullCardView(address: String?,
                             phoneNumber: String?,
                             url: URL?) -> some View {
        VStack(spacing: 0) {
            addressView(address)
            // Phone number
            if let phoneNumber = phoneNumber {
                separator()
                phoneNumberView(phoneNumber)
            }
            // Website
            if let url = url {
                separator()
                websiteView(url)
            }
            Rectangle()
                .fill(.clear)
                .frame(height: 5)
        }
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .stroke(.fieldBorder)
        }
    }
    
    static func missingIdView(address: String?) -> some View {
        VStack(spacing: 0) {
            addressView(address)
            separator()
            HStack(spacing: 0) {
                Image(systemName: "exclamationmark.triangle")
                    .frame(width: 50)
                    .textStyle(imageStyle, color: .warning)
                VStack(spacing: 0) {
                    Text("apple_poi_sheet.no_identifier.title")
                        .textStyle(.footnoteMedium)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 5)
                        .padding(.trailing)
                    Text("apple_poi_sheet.no_identifier.body")
                        .textStyle(.footnote, color: .textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing)
                }
                .padding(.bottom)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .stroke(.fieldBorder)
        }
    }
    
    @ViewBuilder
    static func dataCardContentView(phoneNumber: String?,
                                    url: URL?) -> some View {
        VStack(spacing: 0) {
            // Phone number
            if let phoneNumber = phoneNumber {
                phoneNumberView(phoneNumber)
                    .padding(.top, 15)
                if let url = url {
                    separator()
                }
            }
            // Website
            if let url = url {
                if phoneNumber == nil {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 15)
                }
                websiteView(url)
            }
        }
        .padding(.bottom, 5)
    }


    static func addressView(_ address: String?) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Image(systemName: "mappin.circle")
                .frame(width: 50)
                .textStyle(imageStyle, color: imageColor)
            //.padding(.top, 5)
            Text(address ?? "")
                .textStyle(textStyle, color: textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 15)
        .padding(.bottom, 10)
        .contextMenu {
            Button(action: { UIPasteboard.general.string = address } ){
                Text("common.copy")
            }
        }
    }

    static func separator() -> some View {
        Rectangle()
            .fill(.fieldBorder)
            .frame(height: 1)
            .padding(.leading, 50)
            .padding(.bottom, 10)
    }

    static func phoneNumberView(_ phoneNumber: String) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Image(systemName: "phone")
                .frame(width: 50)
                .textStyle(imageStyle, color: imageColor)
                //.padding(.top, 5)
            Text(verbatim: phoneNumber)
                .textStyle(textStyle, color: textLinkColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 10)
        .onTapGesture(perform: { call(phoneNumber) })
        .contextMenu {
            Button(action: { UIPasteboard.general.string = phoneNumber } ){
                Text("common.copy")
            }
        }
    }
    
    static func websiteView(_ url: URL) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Image(systemName: "globe")
                .frame(width: 50)
                .textStyle(imageStyle, color: imageColor)
                //.padding(.top, 5)
            Text(url.displayHost ?? url.absoluteString)
                .lineLimit(3)
                .textStyle(textStyle, color: textLinkColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 10)
        .onTapGesture(perform: { web(url) })
        .contextMenu {
            Button(action: { UIPasteboard.general.string = url.absoluteString } ){
                Text("common.copy")
            }
        }
    }
    
    private static func web(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    private static func call(_ phoneNumber: String) {
        UIApplication.shared.open(URL(string: "tel://\(phoneNumber)")!)

        //let ci = ContactItem(value: phoneNumber, label: .init(kind: .phone))
        //do {
        //    try URLOpener.openURL(contactItem: ci)
        //} catch let error as URLOpenerError {
        //    URLOpener.alertContent(error)
        //}
    }

}

#Preview {
    TabView {
        VStack(spacing: 0) {
            ScrollView {
                ApplePOIViewFactory.applePOINativeBtView(onTap: {})
                    .padding(.bottom, 25)
                
                ApplePOIViewFactory.fullCardView(address: "Carrer del torrent d'en vidalet 15\nBarcelona\nEspaña",
                                                 phoneNumber: "+34567789987",
                                                 url: URL(string: "http://www.dropin.lat/tokne1/token2/token3?param1=23&param2=12")!)
                .padding(.bottom, 25)
                
                Text(verbatim: "No phone").padding(.bottom, 10)
                ApplePOIViewFactory.fullCardView(address: "Barcelona\nEspaña",
                                                 phoneNumber: nil,
                                                 url: URL(string: "www.dropin.lat/tokne1/token2/token3?param1=23&param2=12")!)
                .padding(.bottom, 25)
                
                Text(verbatim: "No web").padding(.bottom, 10)
                ApplePOIViewFactory.fullCardView(address: "Barcelona\nEspaña",
                                                 phoneNumber: nil,
                                                 url: URL(string:"http://dropin.lat/404")!)
                .padding(.bottom, 25)
                
                Text(verbatim: "No data").padding(.bottom, 10)
                ApplePOIViewFactory.fullCardView(address: "Barcelona\nEspaña",
                                                 phoneNumber: nil,
                                                 url: nil)
                .padding(.bottom, 25)
                
                Text(verbatim: "No identifier provided").padding(.bottom, 10)
                ApplePOIViewFactory.missingIdView(address: "Barcelona\nEspaña")
                    .padding(.bottom, 25)
            }
        }
        .tabItem {
            Label(String("Full card"), systemImage: "line.3.horizontal.decrease.circle")
        }
        
        VStack(spacing: 0) {
            Text(verbatim: "Only content").padding(.bottom, 10)
            ApplePOIViewFactory.dataCardContentView(phoneNumber: "+34567789987",
                                                    url: URL(string: "dropin.lat")!)
            .background {
                Rectangle()
                    .fill(.clear)
                    .stroke(.fieldBorder)
            }
            .padding(.bottom, 25)
            
            Text(verbatim: "Only URL").padding(.bottom, 10)
            ApplePOIViewFactory.dataCardContentView(phoneNumber: nil,
                                                    url: URL(string: "dropin.lat")!)
            .background {
                Rectangle()
                    .fill(.clear)
                    .stroke(.fieldBorder)
            }
            .padding(.bottom, 25)
            
            Text(verbatim: "Only phone").padding(.bottom, 10)
            ApplePOIViewFactory.dataCardContentView(phoneNumber: "+34567789987",
                                                    url: nil)
            .background {
                Rectangle()
                    .fill(.clear)
                    .stroke(.fieldBorder)
            }
            .padding(.bottom, 25)
        }
        .tabItem {
            Label(String("Only data"), systemImage: "line.2.horizontal.decrease.circle")
        }
        
    }
    .padding(.horizontal)
}
