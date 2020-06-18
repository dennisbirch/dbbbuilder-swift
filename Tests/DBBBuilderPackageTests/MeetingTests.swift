//
//  MeetingTests.swift
//  DBBBuilder-DemoTests
//
//  Created by Dennis Birch on 1/20/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import XCTest
@testable import DBBBuilder

class MeetingTests: XCTestCase {
    var dbManager: DBBManager?
    
    override func setUp() {
        super.setUp()
        
        dbManager = CommonTestTask.defaultTestManager(tables: [Meeting.self, Person.self, Project.self])
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }

    func testMeeting() {
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let attendees = twoPeople()
        XCTAssertEqual(attendees.count, 2)
        
        guard let p1 = attendees.first else {
            XCTFail()
            return
        }
        
        var saved = p1.saveToDB()
        XCTAssertTrue(saved)
        
        guard let p2 = attendees.last else {
            XCTFail()
            return
        }
        
        saved = p2.saveToDB()
        XCTAssertTrue(saved)

        let mtg = Meeting(dbManager: manager)
        mtg.purpose = "Choose new hiree"
        mtg.startTime = Date()
        mtg.scheduledHours = 0.75
        
        mtg.participants = attendees
        
        saved = mtg.saveToDB()
        XCTAssertTrue(saved)
        
        let meetingCount = manager.countForTable(mtg.shortName)
        XCTAssertEqual(meetingCount, 1)
        
        let mtgID = mtg.idNum
        
        var options = DBBQueryOptions()
        options.conditions = ["id = \(mtgID)"]
        let result = Meeting.instancesWithOptions(options, manager: manager, sparsePopulation: false)
        
        guard let newMtgRef = result?.first as? Meeting else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(mtg.purpose, newMtgRef.purpose)
        XCTAssertEqual(mtg.scheduledHours, newMtgRef.scheduledHours)
        XCTAssertEqual(mtg.participants?.count, newMtgRef.participants?.count)
        guard let m1p1 = mtg.participants?.first, let m2p1 = newMtgRef.participants?.first else {
            XCTFail()
            return
        }
        XCTAssertEqual(m1p1.firstName, m2p1.firstName)
        XCTAssertEqual(m1p1.lastName, m2p1.lastName)
        XCTAssertEqual(m1p1.department, m2p1.department)
        
        // test retrieving objects with DBBTableObject properties that match requirements
        let meeting2 = Meeting(dbManager: manager)
        meeting2.purpose = "Test finding a meeting by participants"
        let newPerson = Person(dbManager: manager)
        var success = newPerson.saveToDB()
        XCTAssertTrue(success)
        let newPersonID = newPerson.idNum
        meeting2.participants = [newPerson]
        success = meeting2.saveToDB()
        let mtg2ID = meeting2.idNum
        XCTAssertTrue(success)
        
        let meeting3 = Meeting(dbManager: manager)
        meeting3.participants = [newPerson]
        success = meeting3.saveToDB()
        XCTAssertTrue(success)
        
        let mtg3ID = meeting3.idNum
        
        let newPersonConditions = ["participants IN (\(newPersonID))"]
        let newPersonOptions = DBBQueryOptions.options(withConditions: newPersonConditions)
        guard let meetingsWithNewPerson = Meeting.instancesWithOptions(newPersonOptions, manager: manager) as? [Meeting] else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(meetingsWithNewPerson.count, 2)
        
        guard let firstMeetingWithNewPerson = meetingsWithNewPerson.first else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(firstMeetingWithNewPerson.idNum, mtg2ID)
        
        guard let lastMeetingWithNewPerson = meetingsWithNewPerson.last else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(lastMeetingWithNewPerson.idNum, mtg3ID)
        
        let projectIDProj = Project(dbManager: manager)
        projectIDProj.name = "Project to test finding a meeting by Project ID"
        success = projectIDProj.saveToDB()
        XCTAssertTrue(success)
        
        let projectID = projectIDProj.idNum
        
        meeting2.project = projectIDProj
        success = meeting2.saveToDB()
        XCTAssertTrue(success)
        
        let updatedMeetingID = meeting2.idNum
        XCTAssertEqual(updatedMeetingID, mtg2ID)
        
        let projectConditions = ["project = \(projectID)"]
        let projectOptions = DBBQueryOptions.options(withConditions: projectConditions)
        guard let meetingsFoundByProject = Meeting.instancesWithOptions(projectOptions, manager: manager) as? [Meeting] else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(meetingsFoundByProject.count, 1)
        
        guard let firstMeetingFound = meetingsFoundByProject.first else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(mtg2ID, firstMeetingFound.idNum)
        
        let compoundConditions = ["participants IN (\(newPersonID))",
            "project = \(projectID)",
            "AND"]
        let compooundOptions = DBBQueryOptions.options(withConditions: compoundConditions)
        guard let meetingsFoundWithCompoundConditions = Meeting.instancesWithOptions(compooundOptions, manager: manager) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(meetingsFoundWithCompoundConditions.count, 1)
        
        guard let meetingFoundWithProjectAndParticipants = meetingsFoundWithCompoundConditions.first as? Meeting else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(meetingFoundWithProjectAndParticipants.idNum, mtg2ID)
        
        success = Meeting.deleteMultipleInstances(meetingsWithNewPerson, manager: manager)
        XCTAssertTrue(success)
        
        let lastPersonID = p2.idNum
        success = Person.deleteInstance(p2, manager: manager)
        XCTAssertTrue(success)
        
        let deletedPerson = Person.instanceWithIDNumber(lastPersonID, manager: manager)
        XCTAssertNil(deletedPerson)
        
        success = Meeting.deleteInstance(mtg, manager: manager)
        XCTAssertTrue(success)
        
        let newMtgCount = manager.countForTable(mtg.shortName)
        XCTAssertEqual(newMtgCount, 0)
    }
    
    func testMultipleObjectDeletion() {
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let attendees = twoPeople()
        XCTAssertEqual(attendees.count, 2)
        
        guard let p1 = attendees.first else {
            XCTFail()
            return
        }
        
        var saved = p1.saveToDB()
        XCTAssertTrue(saved)
        
        guard let p2 = attendees.last else {
            XCTFail()
            return
        }
        
        saved = p2.saveToDB()
        XCTAssertTrue(saved)
        
        let mtg1 = Meeting(dbManager: manager)
        mtg1.purpose = "Choose new hiree"
        mtg1.startTime = Date()
        mtg1.scheduledHours = 0.75
        
        mtg1.participants = [p1, p2]
        saved = mtg1.saveToDB()
        XCTAssertTrue(saved)
        
        let mtg1ID = mtg1.idNum
        
        guard let newMtg = Meeting.instanceWithIDNumber(mtg1ID, manager: manager) as? Meeting else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(mtg1.purpose, newMtg.purpose)
        XCTAssertEqual(mtg1.scheduledHours, newMtg.scheduledHours)
        XCTAssertEqual(mtg1.participants?.count, newMtg.participants?.count)
        XCTAssertEqual(mtg1.startTime, newMtg.startTime)
        guard let simon = newMtg.participants?.last else {
            XCTFail()
            return
        }
        XCTAssertEqual(simon.lastName, "Sez")
        XCTAssertEqual(simon.age, 27)
        XCTAssertEqual(simon.department, "Management")
        
        let mtg2 = Meeting(dbManager: manager)
        mtg2.purpose = "Vote on new hirees"
        mtg2.startTime = Date()
        mtg2.scheduledHours = 1
        
        let p3 = Person(firstName: "Joe", lastName: "Schmo", age: 29, dbManager: manager)
        p3.department = "Support"
        
        let p4 = Person(dbManager: manager)
        p4.firstName = "Sally"
        p4.lastName = "Smith"
        p4.department = "Marketing"
        
        saved = p3.saveToDB()
        XCTAssertTrue(saved)
        saved = p4.saveToDB()
        XCTAssertTrue(saved)

        mtg2.participants = [p3, p4]
        saved = mtg2.saveToDB()
        XCTAssertTrue(saved)

        let subProject = Project(dbManager: manager)
        subProject.name = "Sub project for testing"
        subProject.startDate = Date()
        saved = subProject.saveToDB()
        XCTAssertTrue(saved)
        
        let proj = Project(dbManager: manager)
        proj.name = "Project for meeting"
        proj.code = "MTG-4354"
        proj.startDate = Date()
        proj.endDate = Date()
        proj.budget = 43.99
        proj.meetings = [mtg1, mtg2]
        proj.subProject = subProject
        saved = proj.saveToDB()
        XCTAssertTrue(saved)
        
        let mtg3 = Meeting(dbManager: manager)
        mtg3.purpose = "Fire new hiree"
        mtg3.startTime = Date()
        mtg3.scheduledHours = 0.25
        mtg3.participants = attendees
        saved = mtg3.saveToDB()
        XCTAssertTrue(saved)

        var success = Meeting.deleteMultipleInstances([mtg1, mtg2], manager: manager)
        XCTAssertTrue(success)

        let allMeetings = Meeting.allInstances(manager: manager)
        XCTAssertEqual(allMeetings.count, 1)
        
        let projID = proj.idNum
        success = Project.deleteInstance(proj, manager: manager)
        XCTAssertTrue(success)
        
        let retrievedProject = Project.instanceWithIDNumber(projID, manager: manager)
        XCTAssertNil(retrievedProject)
    }
    
    func testReadWithQueue() {
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let attendees = twoPeople()
        XCTAssertEqual(attendees.count, 2)
        
        guard let p1 = attendees.first else {
            XCTFail()
            return
        }
        
        var saved = p1.saveToDB()
        XCTAssertTrue(saved)
        
        guard let p2 = attendees.last else {
            XCTFail()
            return
        }
        
        saved = p2.saveToDB()
        XCTAssertTrue(saved)
        
        let mtg1 = Meeting(dbManager: manager)
        mtg1.purpose = "Choose new hiree"
        mtg1.startTime = Date()
        mtg1.scheduledHours = 0.75
        
        mtg1.participants = [p1, p2]
        saved = mtg1.saveToDB()
        XCTAssertTrue(saved)
        
        let mtg1ID = mtg1.idNum
        
        Meeting.getInstancesFromQueue(withOptions: DBBQueryOptions(), manager: manager, sparsePopulation: false, completion: {objects, error in
            XCTAssertNil(error)
        
            guard let newMtg = objects.first as? Meeting else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(mtg1.purpose, newMtg.purpose)
            XCTAssertEqual(mtg1.scheduledHours, newMtg.scheduledHours)
            XCTAssertEqual(mtg1.participants?.count, newMtg.participants?.count)
            XCTAssertEqual(mtg1.startTime, newMtg.startTime)
            XCTAssertEqual(mtg1ID, newMtg.idNum)
            guard let simon = newMtg.participants?.last else {
                XCTFail()
                return
            }
            XCTAssertEqual(simon.lastName, "Sez")
            XCTAssertEqual(simon.age, 27)
            XCTAssertEqual(simon.department, "Management")

            let mtg2 = Meeting(dbManager: manager)
            mtg2.purpose = "Vote on new hirees"
            mtg2.startTime = Date()
            mtg2.scheduledHours = 1
            
            let p3 = Person(firstName: "Joe", lastName: "Schmo", age: 29, dbManager: manager)
            p3.department = "Support"
            
            let p4 = Person(dbManager: manager)
            p4.firstName = "Sally"
            p4.lastName = "Smith"
            p4.department = "Marketing"
            
            saved = p3.saveToDB()
            XCTAssertTrue(saved)
            saved = p4.saveToDB()
            XCTAssertTrue(saved)
            
            mtg2.participants = [p3, p4]
            saved = mtg2.saveToDB()
            XCTAssertTrue(saved)
            
            let subProject = Project(dbManager: manager)
            subProject.name = "Sub project for testing"
            subProject.startDate = Date()
            saved = subProject.saveToDB()
            XCTAssertTrue(saved)
            
            let proj = Project(dbManager: manager)
            proj.name = "Project for meeting"
            proj.code = "MTG-4354"
            proj.startDate = Date()
            proj.endDate = Date()
            proj.budget = 43.99
            proj.meetings = [mtg1, mtg2]
            proj.subProject = subProject
            saved = proj.saveToDB()
            XCTAssertTrue(saved)
            
            let mtg3 = Meeting(dbManager: manager)
            mtg3.purpose = "Fire new hiree"
            mtg3.startTime = Date()
            mtg3.scheduledHours = 0.25
            mtg3.participants = attendees
            saved = mtg3.saveToDB()
            XCTAssertTrue(saved)

            Project.getInstancesFromQueue(withOptions: DBBQueryOptions(), manager: manager, completion: { (objects, error) in
                XCTAssertNil(error)
                guard let retrievedProject = objects.first as? Project else {
                    XCTFail()
                    return
                }
                XCTAssertNotNil(retrievedProject)
            })
        })
    }
    
    // MARK: - Helper Methods
    
    func twoPeople() -> [Person] {
        guard let manager = CommonTestTask.defaultTestManager(tables: [Person.self]) else {
            return [Person]()
        }
        
        let p1 = Person(firstName: "Peter", lastName: "Piper", age: 23, dbManager: manager)
        p1.department = "Engineering"
        let p2 = Person(firstName: "Simon", lastName: "Sez", age: 27, dbManager: manager)
        p2.department = "Management"
        
        return [p1, p2]
    }

}

