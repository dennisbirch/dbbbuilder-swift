//
//  Project.swift
//  DBBBuilder-Demo
//
//  Created by Dennis Birch on 1/20/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import DBBBuilder
import os.log

class Project: DBBTableObject {
    private struct Keys {
        static let name = "name"
        static let code = "code"
        static let startDate = "startDate"
        static let endDate = "endDate"
        static let budget = "budget"
        static let meetings = "meetings"
        static let tags = "tags"
        static let subProject = "subProject"
        static let projectLead = "projectLead"
    }
    
    @objc var name = ""
    @objc var code = ""
    @objc var startDate: Date?
    @objc var endDate: Date?
    @objc var budget: Float = 0
    @objc var meetings = [Meeting]()
    @objc var tags = [String]()
    @objc var subProject: Project?
    @objc var projectLead: Person?
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        let map: [String : DBBPropertyPersistence] = [Keys.name : DBBPropertyPersistence(type: .string),
                                                      Keys.code : DBBPropertyPersistence(type: .string),
                                                      Keys.startDate : DBBPropertyPersistence(type: .date),
                                                      Keys.endDate : DBBPropertyPersistence(type: .date),
                                                      Keys.budget : DBBPropertyPersistence(type: .float),
                                                      Keys.meetings : DBBPropertyPersistence(type: .dbbObjectArray(objectType: Meeting.self)),
                                                      Keys.tags : DBBPropertyPersistence(type: .stringArray),
                                                      Keys.subProject : DBBPropertyPersistence(type: .dbbObject(objectType: Project.self)),
                                                      Keys.projectLead : DBBPropertyPersistence(type: .dbbObject(objectType: Person.self))]
        dbManager.addPersistenceMapContents(map, forTableNamed: shortName)
    }
    
    func addMeeting(_ meeting: Meeting) {
        meetings.append(meeting)
    }
    
    func removeMeeting(_ meeting: Meeting) {
        guard let index = meetings.firstIndex(of: meeting) else {
            os_log("Meeting to remove not found in meetings array")
            return
        }
        
        meetings.remove(at: index)
    }
}
