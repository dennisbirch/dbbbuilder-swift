//
//  MultiObjectSaveTests.swift
//  DBBBuilder-Demo-OSXTests
//
//  Created by Dennis Birch on 3/1/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import XCTest
@testable import DBBBuilder

class MultiObjectSaveTests: XCTestCase {
    var dbManager: DBBManager?
    
    override func setUp() {
        super.setUp()
        
        dbManager = CommonTestTask.defaultTestManager(tables: [Person.self, Company.self, Project.self])
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }
    
    func testMultiSave() {
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let firstName = "John"
        let lastName = "Doe"
        let daddyAge = 35
        let billyAge = 7
        let sallyAge = 5
        let spouseAge = 33
        let daddy = Person(firstName: firstName, lastName: lastName, age: daddyAge, dbManager: manager)
        var saved = daddy.saveToDB()
        XCTAssertTrue(saved)
        
        let originalID = daddy.idNum
        
        let child1 = Person(firstName: "Billy", lastName: "Doe", age: billyAge, dbManager: manager)
        let child2 = Person(firstName: "Sally", lastName: "Doe", age: sallyAge, dbManager: manager)
        let spouse = Person(firstName: "Mary", lastName: "Doe", age: spouseAge, dbManager: manager)
        
        let dependents = [child1, child2, spouse]
        saved = Person.saveObjects(dependents, dbManager: manager)
        XCTAssertTrue(saved)

        let companyName = "Acme Stuff"
        let employer = Company(name: companyName, city: "", state: "", dbManager: manager)
        
        let accountantName = "Joe Accountant, CPA"
        let accountant = Company(name: accountantName, city: "", state: "", dbManager: manager)
        
        let mechanicName = "Helen's Auto Repair"
        let mechanic = Company(name: mechanicName, city: "", state: "", dbManager: manager)
        
        let companies = [employer, accountant, mechanic]
        saved = Company.saveObjects(companies, dbManager: manager)

        let daddyNickNames = ["Daddy", "Johnny"]
        daddy.nicknames = daddyNickNames
        daddy.children = [child1, child2]
        daddy.spouse = spouse
        daddy.employer = employer
        daddy.suppliers = [accountant, mechanic]
        
        var family = dependents
        family.append(daddy)
        
        saved = Person.saveObjects(family, dbManager: manager)
        XCTAssertTrue(saved)
        
        let newIDNum = daddy.idNum
        
        XCTAssertTrue(saved)
        XCTAssertEqual(newIDNum, originalID)
        
        guard let daddyCopy = Person.instanceWithIDNumber(newIDNum, manager: manager) as? Person else {
            XCTFail()
            return
        }
        XCTAssertEqual(daddy.firstName, daddyCopy.firstName)
        XCTAssertEqual(daddy.lastName, daddyCopy.lastName)
        XCTAssertEqual(daddy.age, daddyCopy.age)
        XCTAssertEqual(daddy.nicknames, daddyCopy.nicknames)
        XCTAssertEqual(daddyCopy.children.count, 2)
        XCTAssertEqual(daddyCopy.spouse?.firstName, spouse.firstName)
        XCTAssertEqual(daddyCopy.spouse?.lastName, spouse.lastName)
        XCTAssertEqual(daddyCopy.spouse?.age, spouse.age)
        XCTAssertEqual(daddyCopy.employer?.name, companyName)
        let suppliers = daddyCopy.suppliers
        XCTAssertNotNil(suppliers)
        let retrievedAccountant = suppliers?.filter{ $0.name == accountantName }
        XCTAssertNotNil(retrievedAccountant)
        let retrievedMechanic = suppliers?.filter{ $0.name == mechanicName }
        XCTAssertNotNil(retrievedMechanic)
        XCTAssertEqual(daddyCopy.nicknames, daddyNickNames)
    }

    
    func testSavingNonHomogenousTypesFails() {
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let firstName = "John"
        let lastName = "Doe"
        let daddyAge = 35
        let billyAge = 7
        let sallyAge = 5
        let spouseAge = 33
        let daddy = Person(firstName: firstName, lastName: lastName, age: daddyAge, dbManager: manager)
        
        let child1 = Person(firstName: "Billy", lastName: "Doe", age: billyAge, dbManager: manager)
        let child2 = Person(firstName: "Sally", lastName: "Doe", age: sallyAge, dbManager: manager)
        let spouse = Person(firstName: "Mary", lastName: "Doe", age: spouseAge, dbManager: manager)
        
        let companyName = "Acme Stuff"
        let employer = Company(name: companyName, city: "", state: "", dbManager: manager)
        
        let accountantName = "Joe Accountant, CPA"
        let accountant = Company(name: accountantName, city: "", state: "", dbManager: manager)
        
        let mechanicName = "Helen's Auto Repair"
        let mechanic = Company(name: mechanicName, city: "", state: "", dbManager: manager)
        
        let people = [daddy, child1, child2, spouse]
        let savePeople = Person.saveObjects(people, dbManager: manager)
        XCTAssertTrue(savePeople)

        let objects = [daddy, child1, child2, spouse, employer, accountant, mechanic]
        let saved = Person.saveObjects(objects, dbManager: manager)
        XCTAssertFalse(saved)
    }
    
    func testManySaves() {
        guard let url = dbManager?.database.databaseURL else {
            XCTFail("Database URL required")
            return
        }
        
        dbManager = DBBManager(databaseURL: url)
        dbManager?.addTableClasses([NullTestPerson.self])
        
        guard let manager = dbManager else {
            XCTFail("DBManager must not be nil")
            return
        }
        
        let baseName = "Person"
        let lastName = "Jones"
        var people: [NullTestPerson] = []
        for idx in 1..<10000 {
            let name = baseName + String(idx)
            let person = NullTestPerson(dbManager: manager)
            person.firstName = name
            person.lastName = lastName
            person.age = idx
            people.append(person)
        }
        let startTime = Date()
        let success = NullTestPerson.saveObjects(people, dbManager: manager)
        let endTime = Date()
        XCTAssertTrue(success)
        let elapsed = endTime.timeIntervalSince(startTime)

        // TODO: Remove!!!
        print("Elapsed time for saving: \(elapsed) seconds")
        
    }
}
