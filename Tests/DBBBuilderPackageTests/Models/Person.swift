//
//  Person.swift
//  DBBBuilder
//
//  Created by Dennis Birch on 11/5/18.
//  Copyright © 2018 Dennis Birch. All rights reserved.
//

import Foundation
import DBBBuilder

final class Person: DBBTableObject {
    struct Keys {
        static let firstName = "firstName"
        static let middleInitial = "middleInitial"
        static let lastName = "lastName"
        static let age = "age"
        static let department = "department"
        static let children = "children"
        static let nicknames = "nicknames"
        static let spouse = "spouse"
        static let employer = "employer"
        static let suppliers = "suppliers"
        static let willSaveCount = "willSaveCount"
        static let didSaveCount = "didSaveCount"
    }
    
    @objc var firstName: String = ""
    @objc var middleInitial: String = ""
    @objc var lastName: String = ""
    @objc var age: Int = 0
    @objc var department: String = ""
    @objc var children = [Person]()
    @objc var nicknames = [String]()
    @objc var spouse: Person?
    @objc var employer: Company?
    @objc var suppliers: [Company]?
    @objc var willSaveCount = 0
    @objc var didSaveCount = 0
    
    private let personMap: [String : DBBPropertyPersistence] = [Keys.firstName : DBBPropertyPersistence(type: .string),
                                                                Keys.lastName : DBBPropertyPersistence(type: .string),
                                                                Keys.middleInitial : DBBPropertyPersistence(type: .string),
                                                                Keys.age : DBBPropertyPersistence(type: .int),
                                                                Keys.department : DBBPropertyPersistence(type: .string),
                                                                Keys.children : DBBPropertyPersistence(type: .dbbObjectArray(objectType: Person.self)),
                                                                Keys.nicknames : DBBPropertyPersistence(type: .stringArray),
                                                                Keys.spouse : DBBPropertyPersistence(type: .dbbObject(objectType: Person.self)),
                                                                Keys.employer: DBBPropertyPersistence(type: .dbbObject(objectType: Company.self)),
                                                                Keys.suppliers: DBBPropertyPersistence(type: .dbbObjectArray(objectType: Company.self)),
                                                                Keys.willSaveCount : DBBPropertyPersistence(type: .int),
                                                                Keys.didSaveCount : DBBPropertyPersistence(type: .int)]
    
    init(firstName: String, lastName: String, age: Int, dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        
        configurePersistenceMap()
        attributesDictionary = ["firstName" : DBBBuilder.ColumnAttribute.notNull]
    }
    
    override func performPreSaveActions() {
        willSaveCount += 1
    }
    
    override func performPostSaveActions() {
        didSaveCount += 1
    }
    
    required init(dbManager: DBBManager) {
        // for DBBManager initialization
        super.init(dbManager: dbManager)
        
        configurePersistenceMap()
    }
    
    func fullName() -> String {
        let trimmedFirst = firstName.trimmingCharacters(in: CharacterSet.whitespaces)
        let trimmedMiddle = middleInitial.trimmingCharacters(in: CharacterSet.whitespaces)
        let trimmedLast = lastName.trimmingCharacters(in: CharacterSet.whitespaces)
        
        var nameComponents = [String]()
        if trimmedFirst.isEmpty == false {
            nameComponents.append(trimmedFirst)
        }
        if trimmedMiddle.isEmpty == false {
            nameComponents.append(trimmedMiddle)
        }
        if trimmedLast.isEmpty == false {
            nameComponents.append(trimmedLast)
        }
        
        return nameComponents.joined(separator: " ")
    }
    
    func fullNameAndDepartment() -> String {
        let name = fullName()
        let trimmedDept = department.trimmingCharacters(in: CharacterSet.whitespaces)
        var components = [String]()
        if name.isEmpty == false {
            components.append(name)
        }
        if trimmedDept.isEmpty == false {
           components.append(trimmedDept)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func configurePersistenceMap() {
        dbManager.addPersistenceMapContents(personMap, forTableNamed: shortName)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherPerson = object as? Person else {
            return false
        }
        
        return otherPerson.firstName == firstName &&
            otherPerson.middleInitial == middleInitial &&
            otherPerson.lastName == lastName &&
            otherPerson.age == age    
    }
    
}
