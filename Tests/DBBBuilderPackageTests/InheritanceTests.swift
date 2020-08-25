//
//  File.swift
//  
//
//  Created by Dennis Birch on 8/16/20.
//

import XCTest
@testable import DBBBuilder


class InheritanceTests: XCTestCase {
    
    var dbManager: DBBManager?
    
    override func setUp() {
        super.setUp()
        
        dbManager = CommonTestTask.defaultTestManager(tables: [Pet.self,
                                                               Mammal.self])
    }
    
    
    override func tearDown() {
        super.tearDown()
        
        CommonTestTask.deleteDBFile(dbManager: dbManager)
    }
    
    func testInheritance() {
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let puppy = Pet(dbManager: manager)
        let puppyName = "Fido"
        let genus = "Dog"
        let sex = "F"
        let legs = 4
        let age = 1
        let owner = "Me"
        
        puppy.genus = genus
        puppy.sex = sex
        puppy.legs = legs
        puppy.age = age
        puppy.name = puppyName
        puppy.owner = owner
        
        let success = puppy.saveToDB()
        XCTAssertTrue(success)
        
        let options = DBBQueryOptions.options(withConditions: ["\(Pet.Keys.Name) = \(puppyName.dbb_SQLEscaped())"])
        let fetchedObject = Pet.instancesWithOptions(options, manager: manager)?.first
        XCTAssertNotNil(fetchedObject)
        let fetchedAnimal = fetchedObject as? Animal
        XCTAssertNotNil(fetchedAnimal)
        XCTAssertEqual(fetchedAnimal?.sex, sex)
        let fetchedMammal = fetchedObject as? Mammal
        XCTAssertNotNil(fetchedMammal)
        XCTAssertEqual(fetchedMammal?.genus, genus)
        XCTAssertEqual(fetchedMammal?.legs, legs)

        guard let savedPuppy = fetchedObject as? Pet else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(savedPuppy.genus, genus)
        XCTAssertEqual(savedPuppy.sex, sex)
        XCTAssertEqual(savedPuppy.legs, legs)
        XCTAssertEqual(savedPuppy.name, puppyName)
        XCTAssertEqual(savedPuppy.owner, owner)
    }
    
    func testMultipleSubclasses() {
        guard let manager = dbManager else {
            XCTFail()
            return
        }
        
        let kitty = Pet(dbManager: manager)
        let puppyName = "Homer"
        let genus = "Cat"
        let sex = "M"
        let legs = 4
        let age = 2
        let owner = "Mom"
        
        kitty.genus = genus
        kitty.sex = sex
        kitty.legs = legs
        kitty.age = age
        kitty.name = puppyName
        kitty.owner = owner
        
        var success = kitty.saveToDB()
        XCTAssertTrue(success)
        
        let monkeyLegs = 3
        let monkeyGenus = "Monkey"
        let monkeySex = "N/A"
        let monkey = Mammal(dbManager: manager)
        monkey.genus = monkeyGenus
        monkey.legs = monkeyLegs
        monkey.sex = monkeySex
        success = monkey.saveToDB()
        XCTAssertTrue(success)
        
        let options = DBBQueryOptions.options(withConditions: ["\(Pet.Keys.Name) = \(puppyName.dbb_SQLEscaped())"])
        let fetchedObject = Pet.instancesWithOptions(options, manager: manager)?.first
        XCTAssertNotNil(fetchedObject)
        let fetchedAnimal = fetchedObject as? Animal
        XCTAssertNotNil(fetchedAnimal)
        XCTAssertEqual(fetchedAnimal?.sex, sex)
        let fetchedMammal = fetchedObject as? Mammal
        XCTAssertNotNil(fetchedMammal)
        XCTAssertEqual(fetchedMammal?.genus, genus)
        XCTAssertEqual(fetchedMammal?.legs, legs)

        guard let savedKitty = fetchedObject as? Pet else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(savedKitty.genus, genus)
        XCTAssertEqual(savedKitty.sex, sex)
        XCTAssertEqual(savedKitty.legs, legs)
        XCTAssertEqual(savedKitty.name, puppyName)
        XCTAssertEqual(savedKitty.owner, owner)

        let fetchedMonkey = Mammal.allInstances(manager: manager).first as? Mammal
        XCTAssertNotNil(fetchedMonkey)
        guard let savedMonkey = fetchedMonkey else {
            XCTFail()
            return
        }
        XCTAssertEqual(savedMonkey.genus, monkeyGenus)
        XCTAssertEqual(savedMonkey.legs, monkeyLegs)
        XCTAssertEqual(savedMonkey.sex, monkeySex)
    }
}
    
    
class Animal: DBBTableObject {
    struct Keys {
        static let Sex = "sex"
    }
    
    @objc var sex = ""
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        let map: [String : DBBPropertyPersistence] = [Keys.Sex : DBBPropertyPersistence(type: .string)]
        
        dbManager.addPersistenceMapping(map, for: self)
    }
}
    
class Mammal: Animal {
    struct Keys {
        static let genus = "genus"
        static let legs = "legs"
    }
    
    @objc var genus = ""
    @objc var legs = 0
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        let map: [String : DBBPropertyPersistence] = [Keys.genus : DBBPropertyPersistence(type: .string),
                                                      Keys.legs : DBBPropertyPersistence(type: .string)]
        
        dbManager.addPersistenceMapping(map, for: self)
    }
}

class Pet: Mammal {
    struct Keys {
        static let Name = "name"
        static let Age = "age"
        static let Owner = "owner"
        static let Diet = "diet"
    }
    
    @objc var name = ""
    @objc var age = 0
    @objc var owner = ""
    @objc var diet = ""
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        let map: [String : DBBPropertyPersistence] = [Keys.Name : DBBPropertyPersistence(type: .string),
                                                      Keys.Age : DBBPropertyPersistence(type: .int),
                                                      Keys.Owner : DBBPropertyPersistence(type: .string),
                                                      Keys.Diet : DBBPropertyPersistence(type: .string)]
        
        dbManager.addPersistenceMapping(map, for: self)
    }
}
