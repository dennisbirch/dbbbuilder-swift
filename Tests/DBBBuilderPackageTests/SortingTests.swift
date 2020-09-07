//
//  SortingTests.swift
//  DBBBuilder-Demo-OSXTests
//
//  Created by Dennis Birch on 9/7/20.
//  Copyright © 2020 Dennis Birch. All rights reserved.
//

import XCTest
@testable import DBBBuilder

class SortingTests: XCTestCase {
    var dbManager: DBBManager?
    
    override func setUp() {
        super.setUp()

        dbManager = CommonTestTask.defaultTestManager(tables: [Person.self, Company.self, Project.self])
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }
    
    func testSorting() {
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let lowBudget = Float(500.0)
        let mediumBudget = Float(1000.0)
        let highBudget = Float(10000.0)
        
        let lowProject = Project(dbManager: manager)
        lowProject.budget = lowBudget
        
        let mediumProject = Project(dbManager: manager)
        mediumProject.budget = mediumBudget
        
        let highProject = Project(dbManager: manager)
        highProject.budget = highBudget
        
        let success = Project.saveObjects([lowProject, mediumProject, highProject], dbManager: manager)
        XCTAssertTrue(success)
        
        // ascending sort default
        let ascendingOptions = DBBQueryOptions.options(sortColumns: ["budget"])
        let ascendingBudgets = Project.instancesWithOptions(ascendingOptions, manager: manager) as? [Project]
        XCTAssertNotNil(ascendingBudgets)
        XCTAssertEqual(ascendingBudgets?.count, 3)
        XCTAssertEqual(ascendingBudgets?[0].budget, lowBudget)
        XCTAssertEqual(ascendingBudgets?[1].budget, mediumBudget)
        XCTAssertEqual(ascendingBudgets?[2].budget, highBudget)
        
        // force descending sort
        let descendingOptions = DBBQueryOptions.options(sortColumns: ["budget", ColumnSorting.descending])
        let descendingBudgets = Project.instancesWithOptions(descendingOptions, manager: manager) as? [Project]
        XCTAssertNotNil(descendingBudgets)
        XCTAssertEqual(descendingBudgets?.count, 3)
        XCTAssertEqual(descendingBudgets?[0].budget, highBudget)
        XCTAssertEqual(descendingBudgets?[1].budget, mediumBudget)
        XCTAssertEqual(descendingBudgets?[2].budget, lowBudget)
    }
}
