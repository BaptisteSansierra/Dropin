//
//  UserPlan.swift
//  Dropin
//

import Foundation

/// Mirrors the Postgres `user_plan` enum
/// (see 20250508000001_update_user_plan.sql).
enum UserPlan: String, Codable, Sendable, CaseIterable {
    case admin
    case invited
    case earlyStage = "early_stage"
    case free
    case paid
}
