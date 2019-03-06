//
//  DistinctTests.swift
//  DBBBuilder-Demo-OSXTests
//
//  Created by Dennis Birch on 3/5/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import XCTest
@testable import DBBBuilder
#if os(iOS)
@testable import DBBBuilder_Demo_iOS
#else
@testable import DBBBuilder_Demo_OSX
#endif

class DistinctTests: XCTestCase {

    var dbManager: DBBManager?
    
    override func setUp() {
        super.setUp()
        
        dbManager = CommonTestTask.defaultTestManager(tables: [Person.self, Company.self, Project.self])
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }

    func testDistinctSelect() {
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
        
        let daddyNickNames = ["Daddy", "Johnny"]
        daddy.nicknames = daddyNickNames
        daddy.children = [child1, child2]
        daddy.spouse = spouse
        
        saved = daddy.saveToDB()
        XCTAssertTrue(saved)
        
        var options = DBBQueryOptions.queryOptionsWithAscendingSortForColumns([Person.Keys.lastName])
        options.distinct = true
        guard let results = Person.instancesWithOptions(options, manager: manager) as? [Person] else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(results.count, 1)
        
        options.conditions = ["\(Person.Keys.lastName) = 'Doe'"]
        options.propertyNames = [Person.Keys.lastName]
        guard let does = Person.instancesWithOptions(options, manager: manager) as? [Person] else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(does.count, 1)
        guard let firstDoe = does.first else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(firstDoe.lastName, "Doe")
    }

}
