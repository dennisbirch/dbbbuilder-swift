//
//  Meeting.swift
//  DBBBuilder-Demo
//
//  Created by Dennis Birch on 1/20/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation
import DBBBuilder
import os.log

class Meeting: DBBTableObject {
    private struct Keys {
        static let project = "project"
        static let participants = "participants"
        static let purpose = "purpose"
        static let startTime = "startTime"
        static let finishTime = "finishTime"
        static let scheduledHours = "scheduledHours"
    }
    
    @objc weak var project: Project?
    @objc var participants: [Person]?
    @objc var purpose = ""
    @objc var startTime: Date?
    @objc var finishTime: Date?
    @objc var scheduledHours: Float = 0
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        let map: [String : DBBPropertyPersistence] = [Keys.project : DBBPropertyPersistence(type: .dbbObject(objectType: Project.self)),
                                                      Keys.participants : DBBPropertyPersistence(type: .dbbObjectArray(objectType: Person.self)),
                                                      Keys.purpose : DBBPropertyPersistence(type: .string),
                                                      Keys.startTime : DBBPropertyPersistence(type: .date),
                                                      Keys.finishTime : DBBPropertyPersistence(type: .date),
                                                      Keys.scheduledHours : DBBPropertyPersistence(type: .float)]
        dbManager.addPersistenceMapContents(map, forTableNamed: shortName)
    }
    
    static func allMeetings(manager: DBBManager) -> [Meeting] {
        guard let meetings = Meeting.allInstances(manager: manager) as? [Meeting] else {
            return [Meeting]()
        }
        
        return meetings
    }
    
    func removeParticipant(_ person: Person, manager: DBBManager) {
        guard var participants = participants else {
            os_log("Participants array for meeting is nil")
            return
        }
        
        if let index = participants.firstIndex(of: person) {
            participants.remove(at: index)
            self.participants = participants
        }
    }
    
    func addParticipant(_ person: Person) {
        guard var participants = participants else {
            self.participants = [person]
            return
        }
        
        participants.append(person)
        self.participants = participants
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherMeeting = object as? Meeting else {
            return false
        }
        
        return otherMeeting.purpose == purpose && otherMeeting.startTime == startTime && otherMeeting.finishTime == finishTime
    }
}
