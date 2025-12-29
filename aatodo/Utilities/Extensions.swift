//
//  Extensions.swift
//  aatodo
//
//  Utility extensions for notifications and system helpers
//  Issue: aatodo-8oz.2
//

import Foundation

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when network becomes available after being unavailable
    static let networkDidBecomeAvailable = Notification.Name("networkDidBecomeAvailable")
}
