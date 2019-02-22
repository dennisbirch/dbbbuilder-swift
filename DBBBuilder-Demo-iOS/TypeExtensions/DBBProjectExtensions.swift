//
//  ProjectExtensions.swift
//  DBBBuilder-Swift
//
//  Created by Dennis Birch on 3/1/16.
//  Copyright © 2016 Dennis Birch. All rights reserved.
//

import Foundation

extension Project {
	
    func meetingDisplayString() -> String {
        var meetingPurposes = [String]()
        
        if meetings.count == 0 {
            return ""
        }
        
        for mtg in meetings as [Meeting] {
            let purpose = mtg.purpose
            meetingPurposes.append(purpose)
        }
        
        return meetingPurposes.joined(separator: ", ")
    }
}
