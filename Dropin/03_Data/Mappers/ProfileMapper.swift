//
//  ProfileMapper.swift
//  Dropin
//

import Foundation

public enum ProfileMapper {

    static func toDomain(_ sd: SDProfile) -> ProfileEntity {
        ProfileEntity(id: sd.identifier,
                      email: sd.email,
                      displayName: sd.displayName,
                      plan: UserPlan(rawValue: sd.plan) ?? .free,
                      createdAt: sd.createdAt,
                      updatedAt: sd.updatedAt)
    }

    static func toData(_ p: ProfileEntity) -> SDProfile {
        SDProfile(identifier: p.id,
                  email: p.email,
                  displayName: p.displayName,
                  plan: p.plan.rawValue,
                  createdAt: p.createdAt,
                  updatedAt: p.updatedAt)
    }
}
