//
//  Place.swift
//  Dropin
//
//  Created by baptiste sansierra on 1/10/25.
//

import Foundation
import CoreLocation
import ContactFieldKit

struct PlaceEntity: Hashable {
    let id: String
    var name: String
    var coordinates: CLLocationCoordinate2D //= CLLocationCoordinate2D.zero
    var address: String
    var tags: [TagEntity]
    var group: GroupEntity?
    var icon: Icon?
    var creationDate: Date
    // Metadata
    var rating: Float?
    var phone: [ContactItem]
    var email: [ContactItem]
    var url: [ContactItem]
    var notes: String?
    var images: [Data]
    // following propertie are not part of the DB model
    /// When  databaseDeleted is true, domain objects should be ignored
    var databaseDeleted: Bool

    init(id: String,
         name: String,
         coordinates: CLLocationCoordinate2D,
         address: String,
         tags: [TagEntity],
         group: GroupEntity? = nil,
         icon: Icon? = nil,
         rating: Float? = nil,
         phone: [ContactItem] = [],
         email: [ContactItem] = [],
         url: [ContactItem] = [],
         notes: String? = nil,
         images: [Data] = [],
         creationDate: Date,
         databaseDeleted: Bool = false) {
        self.id = id
        self.name = name
        self.coordinates = coordinates
        self.address = address
        self.icon = icon
        self.tags = tags
        self.group = group
        self.icon = icon
        self.rating = rating
        self.phone = phone
        self.email = email
        self.url = url
        self.notes = notes
        self.images = images
        self.creationDate = creationDate
        self.databaseDeleted = databaseDeleted
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/*

/// EntityLabeledValue is used to store labeled phone/url/email like in Apple Contact as follow :
///     mobile: +1345678
///     home: +1987543
struct EntityLabeledValue: Identifiable, Codable, Hashable {
    
    enum TypeWithLabel: Codable, Hashable {
        case phone(PhoneLabel)
        case url(URLLabel)
        case email(EmailLabel)
        
        enum PhoneLabel: Codable, Hashable {
            case phone, mobile, home, work, school, other
            case custom(String)
        }
        
        enum URLLabel: Codable, Hashable {
            case url, homepage, home, work, school, other
            case custom(String)
        }
        
        enum EmailLabel: Codable, Hashable {
            case email, personal, work, home, school, other
            case custom(String)
        }
        
        enum CodingKeys: String, CodingKey {
            case kind
            case label
        }

        enum Kind: String, Codable {
            case phone, url, email
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)

            switch self {
                case .phone(let label):
                    try c.encode(Kind.phone, forKey: .kind)
                    try c.encode(label, forKey: .label)
                case .url(let label):
                    try c.encode(Kind.url, forKey: .kind)
                    try c.encode(label, forKey: .label)
                case .email(let label):
                    try c.encode(Kind.email, forKey: .kind)
                    try c.encode(label, forKey: .label)
            }
        }
        
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try c.decode(Kind.self, forKey: .kind)

            switch kind {
                case .phone:
                    self = .phone(try c.decode(PhoneLabel.self, forKey: .label))
                case .url:
                    self = .url(try c.decode(URLLabel.self, forKey: .label))
                case .email:
                    self = .email(try c.decode(EmailLabel.self, forKey: .label))
            }
        }
        
        var rawValue: String {
            let data = try! JSONEncoder().encode(self)
            return String(decoding: data, as: UTF8.self)
        }

        init?(rawValue: String) {
            guard let data = rawValue.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(TypeWithLabel.self, from: data)
            else { return nil }

            self = decoded
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case value
    }

    // MARK: properties
    var labelKey: String {
        switch type {
            case .phone(let label):
                switch label {
                    case .phone:
                        return "common.phone"
                    case .mobile:
                        return "common.mobile"
                    case .home:
                        return "common.home"
                    case .work:
                        return "common.work"
                    case .school:
                        return "common.school"
                    case .other:
                        return "common.other"
                    case .custom(let value):
                        return value
                }
            case .email(let label):
                switch label {
                    case .email:
                        return "common.email"
                    case .personal:
                        return "common.personal"
                    case .work:
                        return "common.work"
                    case .home:
                        return "common.home"
                    case .school:
                        return "common.school"
                    case .other:
                        return "common.other"
                    case .custom(let value):
                        return value
                }
            case .url(let label):
                switch label {
                    case .url:
                        return "common.url"
                    case .homepage:
                        return "common.homepage"
                    case .home:
                        return "common.home"
                    case .work:
                        return "common.work"
                    case .school:
                        return "common.school"
                    case .other:
                        return "common.other"
                    case .custom(let value):
                        return value
                }
        }
    }
    var rawValue: String {
        let data = try! JSONEncoder().encode(self)
        return String(decoding: data, as: UTF8.self)
    }
    let id: String
    var type: TypeWithLabel
    var value: String
    
    // MARK: inits
    init(phone: String, label: TypeWithLabel.PhoneLabel) {
        self.id = UUID().uuidString
        self.type = .phone(label)
        self.value = phone
    }
    init(url: String, label: TypeWithLabel.URLLabel) {
        self.id = UUID().uuidString
        self.type = .url(label)
        self.value = url
    }
    init(email: String, label: TypeWithLabel.EmailLabel) {
        self.id = UUID().uuidString
        self.type = .email(label)
        self.value = email
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.value = try c.decode(String.self, forKey: .value)
        self.type = try c.decode(TypeWithLabel.self, forKey: .type)
    }
    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(EntityLabeledValue.self, from: data) else {
            return nil
        }
        self = decoded
    }
    init(kind: TypeWithLabel.Kind) {
        self.id = UUID().uuidString
        switch kind {
            case .phone:
                self.type = .phone(.phone)
            case .email:
                self.type = .email(.email)
            case .url:
                self.type = .url(.url)
        }
        self.value = ""
    }

    // MARK: methods
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(value, forKey: .value)
    }
}

*/

