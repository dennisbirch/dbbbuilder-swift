//
//  PreAndPostSaveActionTests.swift
//  DBBBuilder-Demo-OSXTests
//
//  Created by Dennis Birch on 3/4/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import XCTest
@testable import DBBBuilder
#if os(iOS)
@testable import DBBBuilder_Demo_iOS
#else
@testable import DBBBuilder_Demo_OSX
#endif

class PreAndPostSaveActionTests: XCTestCase {

    var dbManager: DBBManager?
    
    override func setUp() {
        super.setUp()
        
        dbManager = CommonTestTask.defaultTestManager(tables: [Person.self, Company.self, Project.self])
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }
    
    func testSaveCounts() {
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let startingAge = 31
        let endingAge = 43
        let firstName = "Luigi"
        let lastName = "Yakamoto"
        let person = Person(firstName: firstName, lastName: lastName, age: startingAge, dbManager: manager)
        var willSaveCount = person.willSaveCount
        var didSaveCount = person.didSaveCount
        let originalID = person.idNum
        var saved = person.saveToDB()
        let newIDNum = person.idNum
        
        XCTAssertTrue(saved)
        XCTAssertNotEqual(willSaveCount, person.willSaveCount)
        XCTAssertNotEqual(didSaveCount, person.didSaveCount)
        XCTAssertEqual(person.willSaveCount, person.didSaveCount)

        willSaveCount = person.willSaveCount
        didSaveCount = person.didSaveCount
        
        XCTAssertFalse(newIDNum == originalID)
        XCTAssertTrue(newIDNum > 0)
        XCTAssertEqual(person.age, startingAge)
        
        let newAge = endingAge
        person.age = newAge
        saved = person.saveToDB()
        XCTAssertTrue(saved)
        XCTAssertEqual(person.age, endingAge)
        XCTAssertNotEqual(willSaveCount, person.willSaveCount)
        XCTAssertNotEqual(didSaveCount, person.didSaveCount)
        XCTAssertEqual(person.willSaveCount, person.didSaveCount)
        
        willSaveCount = person.willSaveCount
        
        guard let testPerson = Person.instanceWithIDNumber(newIDNum, manager: manager) as? Person else {
            XCTFail()
            return
        }
        XCTAssertNotNil(testPerson)
        XCTAssertEqual(testPerson.age, newAge)
        XCTAssertEqual(testPerson.firstName, firstName)
        XCTAssertEqual(testPerson.lastName, lastName)
        
        XCTAssertEqual(testPerson.willSaveCount, willSaveCount)
        XCTAssertEqual(testPerson.didSaveCount, didSaveCount)
    }
    
}
