//
//  DateExtensons.swift
//  DBBBuilder-Swift
//
//  Created by Dennis Birch on 1/1/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation

extension Date {
    // returns a string with the receiving date's value expressed in "short" date format (without the time)
    func db_display() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        
        return formatter.string(from: self)
    }

    // returns a string with the receiving date's value expressed in "short" date and time format
    func dbb_displayTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        return formatter.string(from: self)
    }
    
    // returns a date set to midnight
    func dbb_midnightDate() -> Date {
        let cal = Calendar.current
        var components = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        return cal.date(from: components) ?? self
    }
    
    // returns a date offset from midnight by hours and minutes passed in
    func dbb_dateByAddingHours(_ hours: Int, minutes: Int) -> Date {
        let newDate = self.dbb_midnightDate()
        let cal = Calendar.current
        var components = cal.dateComponents([.hour, .minute], from: newDate)
        components.hour = hours
        components.minute = minutes
        
        return cal.date(byAdding: components, to: newDate) ?? self
    }

}
