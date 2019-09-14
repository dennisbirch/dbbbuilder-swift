//
//  DBBTableObjectSaveTests.swift
//  DBBBuilderTests
//
//  Created by Dennis Birch on 1/6/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import XCTest
@testable import DBBBuilder
#if os(iOS)
@testable import DBBBuilder_Demo_iOS
#else
@testable import DBBBuilder_Demo_OSX
#endif

class DBBTableObjectSaveTests: XCTestCase {

    var dbManager: DBBManager?
    
    override func setUp() {
        super.setUp()

        dbManager = CommonTestTask.defaultTestManager(tables: [Person.self, Company.self, Project.self])
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }
    
    func testBasicSave() {
         guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let startingAge = 31
        let endingAge = 43
        let firstName = "Luigi"
        let lastName = "Yakamoto"
        let person = Person(firstName: firstName, lastName: lastName, age: startingAge, dbManager: manager)
        let originalID = person.idNum
        var saved = person.saveToDB()
        let newIDNum = person.idNum
        
        XCTAssertTrue(saved)
        
        let created = person.createdTime
        
        XCTAssertFalse(newIDNum == originalID)
        XCTAssertTrue(newIDNum > 0)
        XCTAssertEqual(person.age, startingAge)
        
        let newAge = endingAge
        person.age = newAge
        saved = person.saveToDB()
        XCTAssertTrue(saved)
        XCTAssertEqual(person.age, endingAge)
        
        let modified = person.modifiedTime

        guard let testPerson = Person.instanceWithIDNumber(newIDNum, manager: manager) as? Person else {
            XCTFail()
            return
        }
        XCTAssertNotNil(testPerson)
        XCTAssertEqual(testPerson.age, newAge)
        XCTAssertEqual(testPerson.firstName, firstName)
        XCTAssertEqual(testPerson.lastName, lastName)
        guard let originalCreated = created, let savedCreated = testPerson.createdTime else {
            XCTFail()
            return
        }
        XCTAssertEqual(originalCreated, savedCreated)
        guard let originalMod = modified, let savedMod = testPerson.modifiedTime else {
            XCTFail()
            return
        }
        XCTAssertEqual(originalMod, savedMod)
        
        let company = Company(name: "Dynamic Systems", city: "Jukeville", state: "IA", dbManager: manager)
        let cSave = company.saveToDB()
        XCTAssertTrue(cSave)
    }
    

    func testJoinSave() {
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
        let originalID = daddy.idNum
        
        let child1 = Person(firstName: "Billy", lastName: "Doe", age: billyAge, dbManager: manager)
        let child2 = Person(firstName: "Sally", lastName: "Doe", age: sallyAge, dbManager: manager)
        let spouse = Person(firstName: "Mary", lastName: "Doe", age: spouseAge, dbManager: manager)
        
        var saved = child1.saveToDB()
        saved = child2.saveToDB()
        XCTAssertTrue(saved)
        saved = spouse.saveToDB()
        XCTAssertTrue(saved)

        let companyName = "Acme Stuff"
        let employer = Company(name: companyName, city: "", state: "", dbManager: manager)
        saved = employer.saveToDB()
        XCTAssertTrue(saved)
        
        let accountantName = "Joe Accountant, CPA"
        let accountant = Company(name: accountantName, city: "", state: "", dbManager: manager)
        saved = accountant.saveToDB()
        XCTAssertTrue(saved)
        
        let mechanicName = "Helen's Auto Repair"
        let mechanic = Company(name: mechanicName, city: "", state: "", dbManager: manager)
        saved = mechanic.saveToDB()
        XCTAssertTrue(saved)

        let daddyNickNames = ["Daddy", "Johnny"]
        daddy.nicknames = daddyNickNames
        daddy.children = [child1, child2]
        daddy.spouse = spouse
        daddy.employer = employer
        daddy.suppliers = [accountant, mechanic]
        
        saved = daddy.saveToDB()
        XCTAssertTrue(saved)

        let newIDNum = daddy.idNum

        XCTAssertTrue(saved)
        XCTAssertFalse(newIDNum == originalID)
        XCTAssertTrue(newIDNum > 0)
        
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
        
        
        let personIDs = Person.allInstanceIDs(manager: manager)
        XCTAssertEqual(personIDs, [1,2,3,4])
    }
    
    func testBlobSave() {
        guard let manager = self.dbManager else {
            XCTFail()
            return
        }
        
        let blurb =
        """
Soon her eye fell on a little glass box that was lying under the table: she opened it, and found in it a very small cake, on which the words 'EAT ME' were beautifully marked in currants. 'Well, I'll eat it,' said Alice, 'and if it makes me grow larger, I can reach the key; and if it makes me grow smaller, I can creep under the door; so either way I'll get into the garden, and I don't care which happens!
"""
        let blurbData = blurb.data(using: .utf8)
        let companyName = "ALICE"
        let company = Company(name: companyName, city: "", state: "", dbManager: manager)
        company.blurbData = blurbData
        let saved = company.saveToDB()
        XCTAssertTrue(saved)
        
        let id = company.idNum
        
        guard let aliceCompany = Company.instanceWithIDNumber(id, manager: manager) as? Company else {
            XCTFail()
            return
        }
        
        guard let data = aliceCompany.blurbData else {
            XCTFail()
            return
        }
        
        guard let aliceBlurbString = String(data: data, encoding: .utf8) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(aliceBlurbString, blurb)
    }
    
    func testQueryWithConditions() {
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
        
        var saved = child1.saveToDB()
        saved = child2.saveToDB()
        XCTAssertTrue(saved)
        saved = spouse.saveToDB()
        XCTAssertTrue(saved)
        
        daddy.children = [child1, child2]
        daddy.spouse = spouse
        saved = daddy.saveToDB()
        
        XCTAssertTrue(saved)
        
        var queryOptions = DBBQueryOptions()
        queryOptions.sorting = ["firstName"]
        guard let sortedPeople = Person.instancesWithOptions(queryOptions, manager: manager, sparsePopulation: false) as? [Person] else  {
            XCTFail()
            return
        }
        
        let count = sortedPeople.count
        XCTAssertEqual(count, 4) // John, Sally, Billy & Mary
        
        var sortedPerson = sortedPeople[0]
        XCTAssertEqual(sortedPerson.firstName, "Billy")
        sortedPerson = sortedPeople[1]
        XCTAssertEqual(sortedPerson.firstName, "John")
        sortedPerson = sortedPeople[2]
        XCTAssertEqual(sortedPerson.firstName, "Mary")
        sortedPerson = sortedPeople[3]
        XCTAssertEqual(sortedPerson.firstName, "Sally")

        // test that retrieving only firstName does not populate lastName property
        queryOptions = DBBQueryOptions.options(properties: [Person.Keys.firstName])
        guard let firstOnlyPeople = Person.instancesWithOptions(queryOptions, manager: manager) as? [Person] else {
            XCTFail()
            return
        }
        XCTAssertEqual(firstOnlyPeople.count, 4)
        let lastNamePeople = firstOnlyPeople.filter{ $0.lastName.isEmpty == false }
        XCTAssertEqual(lastNamePeople.count, 0)
    }
    
    func testSubtypeSaveAndDelete() {
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
       let canning = Project(dbManager: manager)
        canning.name = "Canning Vegetables"
        let jarCleaning = Project(dbManager: manager)
        let jarCleaningName = "Cleaning jars"
        jarCleaning.name = jarCleaningName
        var saved = jarCleaning.saveToDB()
        XCTAssertTrue(saved)
        
        canning.subProject = jarCleaning
        saved = canning.saveToDB()
        XCTAssertTrue(saved)
        
        let canningID = canning.idNum
        XCTAssertTrue(canningID > 0)
        
        guard let newProject = Project.instanceWithIDNumber(canningID, manager: manager) as? Project else {
            XCTFail()
            return
        }
        
        let subproj = newProject.subProject
        XCTAssertNotNil(subproj)
        
        let subProjName = subproj?.name
        XCTAssertEqual(subProjName, jarCleaningName)
        
        canning.subProject = nil
        saved = canning.saveToDB()
        XCTAssertTrue(saved)
        
        let resavedID = canning.idNum
        XCTAssertEqual(resavedID, canningID)
        
        guard let noSubprojectCanning = Project.instanceWithIDNumber(resavedID, manager: manager) as? Project else {
            XCTFail()
            return
        }
        
        XCTAssertNil(noSubprojectCanning.subProject)
    }
    
    
}
