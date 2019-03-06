//
//  Extensions.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 1/31/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation

extension String {
    public func dbb_SQLEscaped() -> String {
        let sqlified = self.replacingOccurrences(of: "''", with: "''''")
        return "'\(sqlified)'"
    }
}

extension Date {
    public static func dbb_dateFromTimeInterval(_ interval: TimeInterval) -> Date {
        return Date(timeIntervalSinceReferenceDate: interval)
    }
    
    public func dbb_timeIntervalForDate() -> TimeInterval {
        return self.timeIntervalSinceReferenceDate
    }
    
    public func dbb_dateComparisonString() -> String {
        return String(self.dbb_timeIntervalForDate())
    }
}
