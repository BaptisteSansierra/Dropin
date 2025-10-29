//
//  CatOpenDataModel.swift
//  Dropin
//
//  Created by baptiste sansierra on 27/10/25.
//

#if DEBUG

import Foundation
import CoreLocation

final class OpenData: Codable, Sendable {
    let num: Int
    let items: [OpenDataItem]

    init(num: Int, items: [OpenDataItem]) {
        self.num = num
        self.items = items
    }
}

final class OpenDataItem: Codable, Sendable {
    let _id: String
    let titol: String
    let tipusEntitat: String
    let subambit: String
    let ambit: String
    let localitzacio: OpenDataItemLocalitzacio
    
    var coords: CLLocationCoordinate2D {
        guard let first = localitzacio.localitzacio_geolocalitzacio.first else { return CLLocationCoordinate2D.zero }
        guard first.count == 2 else { return CLLocationCoordinate2D.zero }
        return CLLocationCoordinate2D(latitude: first[1], longitude: first[0])
    }
    
    var address: String {
        var value = ""
        if localitzacio.localitzacio_adreca.count > 0 {
            value = localitzacio.localitzacio_adreca
        }
        if localitzacio.localitzacio_municipis.count > 0 &&
            localitzacio.localitzacio_municipis[0].count > 0 {
            value = "\(value)\n\(localitzacio.localitzacio_municipis[0])"
        }
        if localitzacio.localitzacio_codi_postal.count > 0 {
            value = "\(value)\n\(localitzacio.localitzacio_codi_postal)"
        }
        return value
    }

    init(_id: String, titol: String, tipusEntitat: String, subambit: String, ambit: String, localitzacio: OpenDataItemLocalitzacio) {
        self._id = _id
        self.titol = titol
        self.tipusEntitat = tipusEntitat
        self.subambit = subambit
        self.ambit = ambit
        self.localitzacio = localitzacio
    }
}

final class OpenDataItemLocalitzacio: Codable, Sendable {
    let localitzacio_geolocalitzacio: [[Double]]
    let localitzacio_adreca: String
    let localitzacio_municipis: [String]
    let localitzacio_codi_postal: String

    init(localitzacio_geolocalitzacio: [[Double]], localitzacio_adreca: String, localitzacio_municipis: [String], localitzacio_codi_postal: String) {
        self.localitzacio_geolocalitzacio = localitzacio_geolocalitzacio
        self.localitzacio_adreca = localitzacio_adreca
        self.localitzacio_municipis = localitzacio_municipis
        self.localitzacio_codi_postal = localitzacio_codi_postal
    }
}


#endif
