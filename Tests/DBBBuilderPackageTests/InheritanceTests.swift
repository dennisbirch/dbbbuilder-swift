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
        let foods = ["Small Dog Kibble", "Puppy Chow"]
        let diet = "Anything"
        let owner = Mammal(dbManager: manager)
        owner.genus = "Human"
        owner.legs = 2
        
        let brotherName = "Cosmo"
        let sisterName = "Poppy"
        
        let brother = Pet(dbManager: manager)
        brother.name = brotherName
        brother.genus = genus
        brother.legs = legs
        
        let sister = Pet(dbManager: manager)
        sister.name = sisterName
        sister.genus = genus
        sister.legs = legs
        
        var success = brother.saveToDB()
        XCTAssertTrue(success)
        let brotherID = brother.idNum

        success = sister.saveToDB()
        XCTAssertTrue(success)
        let sisterID = sister.idNum
        
        puppy.genus = genus
        puppy.sex = sex
        puppy.legs = legs
        puppy.age = age
        puppy.name = puppyName
        puppy.owner = owner
        puppy.foods = foods
        puppy.diet = diet
        puppy.siblings = [sister, brother]
        
        success = puppy.saveToDB()
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
        XCTAssertEqual(savedPuppy.diet, diet)
        XCTAssertEqual(savedPuppy.foods, foods)
        XCTAssertNotNil(savedPuppy.owner)
        guard let savedOwner = savedPuppy.owner else {
            XCTFail()
            return
        }
        XCTAssertEqual(savedOwner.genus, owner.genus)
        XCTAssertEqual(savedOwner.legs, owner.legs)
        
        let savedSiblings = savedPuppy.siblings
        let savedSister = savedSiblings.first(where: {$0.idNum == sisterID})
        XCTAssertNotNil(savedSister)
        
        let savedBrother = savedSiblings.first(where: {$0.idNum == brotherID})
        XCTAssertNotNil(savedBrother)
        
        XCTAssertEqual(savedSister?.name, sisterName)
        
        XCTAssertEqual(savedBrother?.name, brotherName)
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
        let owner = Mammal(dbManager: manager)
        owner.genus = "Human"
        owner.legs = 2

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
        let monkeyID = monkey.idNum
        
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

        let fetchedMonkey = Mammal.instanceWithIDNumber(monkeyID, manager: manager)
        XCTAssertNotNil(fetchedMonkey)
        guard let savedMonkey = fetchedMonkey as? Mammal else {
            XCTFail()
            return
        }
        XCTAssertEqual(savedMonkey.genus, monkeyGenus)
        XCTAssertEqual(savedMonkey.legs, monkeyLegs)
        XCTAssertEqual(savedMonkey.sex, monkeySex)
        
        XCTAssertNotNil(savedKitty.owner)
        guard let kittyOwner = savedKitty.owner else {
            XCTFail()
            return
        }
        XCTAssertEqual(kittyOwner.genus, owner.genus)
        XCTAssertEqual(kittyOwner.legs, owner.legs)
    }
}
    
    
class Animal: DBBTableObject {
    struct Keys {
        static let Sex = "sex"
        static let Diet = "diet"
    }
    
    @objc var sex = ""
    @objc var diet = ""

    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        let map: [String : DBBPropertyPersistence] = [Keys.Sex : DBBPropertyPersistence(type: .string),
                                                      Keys.Diet : DBBPropertyPersistence(type: .string)]
        
        hasSubclass = true
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
        
        hasSubclass = true
        dbManager.addPersistenceMapping(map, for: self)
    }
}

class Pet: Mammal {
    struct Keys {
        static let Name = "name"
        static let Age = "age"
        static let Owner = "owner"
        static let Foods = "foods"
        static let Siblings = "siblings"
    }
    
    @objc var name = ""
    @objc var age = 0
    @objc var owner: Mammal?
    @objc var foods = [String]()
    @objc var siblings = [Pet]()
    
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        let map: [String : DBBPropertyPersistence] = [Keys.Name : DBBPropertyPersistence(type: .string),
                                                      Keys.Age : DBBPropertyPersistence(type: .int),
                                                      Keys.Owner : DBBPropertyPersistence(type: .dbbObject(objectType: Mammal.self)),
                                                      Keys.Foods : DBBPropertyPersistence(type: .stringArray),
                                                      Keys.Siblings : DBBPropertyPersistence(type: .dbbObjectArray(objectType: Pet.self))]
        
        dbManager.addPersistenceMapping(map, for: self)        
        self.finalizeClass()
    }
}
