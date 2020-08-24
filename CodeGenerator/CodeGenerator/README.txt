
This "CodeGenerator" project is a helper application for DBBBuilder that can generate the boilerplate required to set up a DBBTableObject subclass, which is used by DBBBuilder to model its objects.

To use this project, launch it in Xcode and type or paste a comma-, return-, or space-delimited list of property names into the "Input" text view. Choose a "Default var type" from the popup button in the upper left of the screen. This var type will set the output to use the type you choose for all properties, so pick the one that will require the least editing after copying it into your actual project. Then enter the name of the class to generate in the "Class name" textfield.

Hit the "Generate Code" button and the project will populate the "Output" text view with a complete class definition that includes a struct of Key names, property declarations, and an init method that adds each property to the DBBManager instance's persistenceMap.

You can copy this code to the clipboard by hitting the "Copy Code" button, and then paste it into your DBBTableObject subclass code file. Be sure to change the property declarations and persistence map types for any properties that were not of the default type you selected in the generator default type popup.

NEW: You can now paste a code snippet of your return-delimited iVar declarations into the Input field and the Code Generator should be able to clean it up properly. You can also paste in Objective-C property declarations.

For example, the Test class declared with a default type of String and this input:

@objc weak var project: Project?
@objc var participants: [Person]?
@objc var purpose = ""
@objc var startTime: Date?
@objc var finishTime: Date?
@objc var scheduledHours: Float = 0

...or this Objective-C input:

@property (nullable, nonatomic, weak) DBBProject *project;
@property (nullable, nonatomic, strong) NSArray *participants;
@property (nullable, nonatomic, copy) NSString *purpose;
@property (nullable, nonatomic, strong) NSDate *startTime;
@property (nullable, nonatomic, strong) NSDate *finishTime;
@property (nonatomic, assign) double scheduledHours;


...comes out as:

class Test: DBBTableObject {
    struct Keys {
        static let project = "project"
        static let participants = "participants"
        static let purpose = "purpose"
        static let startTime = "startTime"
        static let finishTime = "finishTime"
        static let scheduledHours = "scheduledHours"
    }

    @objc var project = ""
    @objc var participants = ""
    @objc var purpose = ""
    @objc var startTime = ""
    @objc var finishTime = ""
    @objc var scheduledHours = ""

    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)

        let map: [String : DBBPropertyPersistence] = [Keys.project : DBBPropertyPersistence(type: .string),
        Keys.participants : DBBPropertyPersistence(type: .string),
        Keys.purpose : DBBPropertyPersistence(type: .string),
        Keys.startTime : DBBPropertyPersistence(type: .string),
        Keys.finishTime : DBBPropertyPersistence(type: .string),
        Keys.scheduledHours : DBBPropertyPersistence(type: .string)]

        dbManager.addPersistenceMapping(map, for: self)
    }
}
