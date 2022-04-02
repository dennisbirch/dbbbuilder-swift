//
//  NullItemsTests.swift
//  Test
//
//  Created by Dennis Birch on 8/20/21.
//

import XCTest
@testable import DBBBuilder

class NullItemsTests: XCTestCase {
    
    var dbManager: DBBManager?
    
    override func setUp() {
        super.setUp()
        
        createManager()
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }
    
    func testWriteNullPropertyValues() {
        guard let manager = dbManager else {
            XCTFail("DBManager must not be nil")
            return
        }
        let person1FirstName = "Joe"
        let person1Age = 23
        let person1 = NullTestPerson(dbManager: manager)
        person1.firstName = person1FirstName
        person1.age = person1Age
        var success = person1.saveToDB()
        XCTAssertTrue(success)
        
        guard let fetchedPerson1 = fetchPersonWithFirstName(person1FirstName) else {
            XCTFail("Fetch should not fail")
            return
        }
        
        XCTAssertEqual(fetchedPerson1.firstName, person1FirstName)
        XCTAssertEqual(fetchedPerson1.age, person1Age)
        XCTAssertEqual(fetchedPerson1.lastName, "")
        XCTAssertNil(fetchedPerson1.middleInitial)
        XCTAssertNil(fetchedPerson1.department)
        XCTAssertNil(fetchedPerson1.children)
        XCTAssertNil(fetchedPerson1.nicknames)
        XCTAssertNil(fetchedPerson1.spouse)
        
        let person1MiddleInitial = "Z"
        let person1Dept = "Engineering"
        person1.middleInitial = person1MiddleInitial
        person1.department = person1Dept
        success = person1.saveToDB()
        XCTAssertTrue(success)
        
        guard let refetchedPerson1 = fetchPersonWithFirstName(person1FirstName) else {
            XCTFail("Fetch should not fail")
            return
        }
        
        XCTAssertEqual(refetchedPerson1.firstName, person1FirstName)
        XCTAssertEqual(refetchedPerson1.age, person1Age)
        XCTAssertEqual(refetchedPerson1.lastName, "")
        XCTAssertEqual(refetchedPerson1.middleInitial, person1MiddleInitial)
        XCTAssertEqual(refetchedPerson1.department, person1Dept)
        XCTAssertNil(refetchedPerson1.children)
        XCTAssertNil(refetchedPerson1.nicknames)
        XCTAssertNil(refetchedPerson1.spouse)
        
        let spouseName = "Mary"
        let spouse = NullTestPerson(dbManager: manager)
        spouse.firstName = spouseName
        success = spouse.saveToDB()
        XCTAssertTrue(success)
        
        guard let fetchedSpouse = fetchPersonWithFirstName(spouseName) else {
            XCTFail("Fetch should succeed")
            return
        }
        
        XCTAssertEqual(fetchedSpouse.firstName, spouseName)
        
        person1.spouse = spouse
        success = person1.saveToDB()
        XCTAssertTrue(success)
        
        let person1Options = DBBQueryOptions.options(withConditions: ["firstName = \(person1FirstName.dbb_SQLEscaped())"])
        guard let fetchedPerson1WithSpouse = NullTestPerson.instancesWithOptions(person1Options, manager: manager)?.first as? NullTestPerson else {
            XCTFail("Fetch should succeed")
            return
        }
        let firstPersonSpouse = fetchedPerson1WithSpouse.spouse
        XCTAssertNotNil(firstPersonSpouse)
        XCTAssertEqual(firstPersonSpouse?.firstName, spouseName)
        
        XCTAssertEqual(fetchedPerson1WithSpouse.firstName, person1FirstName)
        XCTAssertEqual(fetchedPerson1WithSpouse.age, person1Age)
        XCTAssertEqual(fetchedPerson1WithSpouse.lastName, "")
        XCTAssertEqual(fetchedPerson1WithSpouse.middleInitial, person1MiddleInitial)
        XCTAssertEqual(fetchedPerson1WithSpouse.department, person1Dept)
        XCTAssertNil(fetchedPerson1WithSpouse.children)
        XCTAssertNil(fetchedPerson1WithSpouse.nicknames)

        let child1Name = "Billy"
        let child2Name = "Courtney"
        let child1 = NullTestPerson(dbManager: manager)
        child1.firstName = child1Name
        let child2 = NullTestPerson(dbManager: manager)
        child2.firstName = child2Name
        person1.children = [child1, child2]
        success = person1.saveToDB()
        XCTAssertTrue(success)
        
        guard let personWithChildren = fetchPersonWithFirstName(person1FirstName) else {
            XCTFail("Fetch should not fail")
            return
        }
        guard let children = personWithChildren.children else {
            XCTFail("Children should not be nil")
            return
        }
        XCTAssertEqual(children.count, 2)
        XCTAssertTrue(children.contains(where: { $0.firstName == child1Name }))
        XCTAssertTrue(children.contains(where: { $0.firstName == child2Name }))
    }
    
    // Private Helper Methods

    private func createManager() {
        dbManager = CommonTestTask.defaultTestManager(tables: [NullTestPerson.self])
    }
    
    private func fetchPersonWithFirstName(_ name: String) -> NullTestPerson? {
        guard let manager = dbManager else { return nil }
        let person1Options = DBBQueryOptions.options(withConditions: ["firstName = \(name.dbb_SQLEscaped())"])
        let fetchedPerson = NullTestPerson.instancesWithOptions(person1Options, manager: manager)?.first as? NullTestPerson
        return fetchedPerson
    }

}

class NullTestPerson: DBBTableObject {
    struct Keys {
        static let firstName = "firstName"
        static let middleInitial = "middleInitial"
        static let lastName = "lastName"
        static let age = "age"
        static let department = "department"
        static let children = "children"
        static let nicknames = "nicknames"
        static let spouse = "spouse"
    }
    
    @objc var firstName: String = ""
    @objc var middleInitial: String?
    @objc var lastName: String = ""
    @objc var age: Int = 0
    @objc var department: String?
    @objc var children: [NullTestPerson]?
    @objc var nicknames: [String]?
    @objc var spouse: NullTestPerson?
    
    private let personMap: [String : DBBPropertyPersistence] = [
        Keys.firstName : DBBPropertyPersistence(type: .string),
        Keys.lastName : DBBPropertyPersistence(type: .string),
        Keys.middleInitial : DBBPropertyPersistence(type: .string),
        Keys.age : DBBPropertyPersistence(type: .int),
        Keys.department : DBBPropertyPersistence(type: .string),
        Keys.children : DBBPropertyPersistence(type: .dbbObjectArray(objectType: NullTestPerson.self)),
        Keys.nicknames : DBBPropertyPersistence(type: .stringArray),
        Keys.spouse : DBBPropertyPersistence(type: .dbbObject(objectType: NullTestPerson.self))
    ]
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        dbManager.addPersistenceMapping(personMap, for: self)
    }

}
