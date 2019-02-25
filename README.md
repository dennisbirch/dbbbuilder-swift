#DBBBuilder
###A framework for working in Swift with first-class objects persisted to SQLiite databases.###


- Works in conjunction with the [FMDB](https://github.com/ccgus/fmdb) framework
- Builds frameworks for iOS and Mac projects
- Generates and updates SQLite database files and tables automatically based on your class definitions
- Can be used to work with existing SQLite database files
- Carthage-enabled
- Swift 4.2
- Xcode 10.1 or higher

###Overview

DBBBuilder is a Swift project that makes it easy to work with first-class objects that are persisted to an SQLite database with the FMDB framework in your iOS or Mac projects.

DBBBuilder takes care of creating the database file if needed, and all database tables and indexes, at runtime, based on your class definitions and other configuration steps.

###Installation
####Carthage
You can add DBBBuilder to your Xcode project using the [Carthage](https://github.com/Carthage/Carthage) dependency manager.

After [installing Carthage](https://github.com/Carthage/Carthage#quick-start), add a dependency statement for DBBBuilder to your Cartfile:

`github "https://github.com/dennisbirch/dbbbuilder-swift/"`

Then in Terminal, cd into your project directory and run Carthage update:

`carthage update`

Then follow the [directions for adding frameworks to your project.](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application) Be sure to add the FMDB and DBBBuilder frameworks to your "Link Binary with Libraries" list in the Build Phases of the target setup pane. Also be sure to add the "libsqlite3.tbd" library.

You should now be able to begin using DBBBuilder in your Xcode project.

###Usage
DBBBuilder has two main classes you need to be concerned with to use it properly.

`DBBManager` is the class that holds a reference to the database file you're persisting data to. You can have more than one DBBManager instance in your project, but each one must be set up to work with a different file.

`DBBTableObject` is the parent class for each object you want to persist to the database.

Proper use of DBBBuilder requires setting up each DBBManager instance with the DBBTableObject subclass types it manages. You also need to configure the DBBManager with mapping for each DBBTableObject subclass, defining the properties that should be persisted to the database file and their types. You can optionally configure the DBBManager with indexing instructions for any DBBTableObject subclass to tell it which properties it should build indexes for.

####DBBManager
__Initalizing:__ `init(databaseURL: URL)`

_databaseURL_: The URL for a database file. Be sure it points to a file and not to a directory.

__Configuring with table types:__ `func addTableClasses(_ tableClasses: [DBBTableObject.Type])`

_tableClasses_: An array of DBBTableObject _types_.

After initializing a DBBManager instance, tell it what DBBTableObject subclasses it will include in its database table with this method.  For example:

```
let dbManager = DBBManager(databaseURL: dbFileURL)
let tableTypes = [Person.self, Project.self, Meeting.self]
dbManager.addTableClasses(tableClasses)
```

__Defining subclass properties:__ `func addPersistenceMapContents(_ contents: [String : DBBPropertyPersistence], forTableNamed table: String, indexer: DBBIndexer? = nil)`

_contents_: A [String : DBBPropertyPersistence] dictionary defining the name and type of each property in a DBBTableObject subclass that should be persisted to the database.

_table_: A String defining the name of the DBBTableObject subclass. You can use the DBBTableObject's _shortName_ property to get this.

It is best practice to call this method in your DBBTableObject subclass instances. [See below.](#complete-init)

####DBBTableObject

__Defining properties:__ Because DBBBuilder uses Key Value Observing to assign values from the database to DBBTableObject subclass instances, each of a DBBTableObject subclass's properties that you want to persist to the database must be marked with the `@objc` attribute.

For example:

```
class Project: DBBTableObject {
    @objc var name = ""
    @objc var code = ""
    @objc var startDate: Date?
    @objc var endDate: Date?
    @objc var budget: Float = 0
    @objc var meetings = [Meeting]()
    @objc var tags = [String]()
    @objc var subProject: Project?
    @objc var projectLead: Person?
```

__Initializing:__ `required init(dbManager: DBBManager)`

_dbManager_: The DBBManager instance managing the database file that this subclass's instances should be written to.

A DBBTableObject subclass must be initialized with this init method. 

As part of the initialization process, you should call DBBManager's addPersistenceMapContents(contents, table, indexer) method to configure the manager with the metadata it needs for writing subclass property values to the database file.

This method takes as its *contents* parameter, a [String : DBBPropertyPersistence] dictionary.
The String key is the case-sensitive name of the property. DBBProperty is a simple struct that defines a database column name and its type as one of a member of the DBBStorageType enum. This allows you to assign a custom name for a property in your class so that the property name and databse column name can differ if necessary, for example if you're working with a pre-existing table where you want the property name to be different from the column name already defined.

A complete DBBTableObject subclass's init method might look like this:<a name="complete-init"></a>

```
    required init(dbManager: DBBManager) {
        super.init(dbManager: dbManager)
        
        let map: [String : DBBPropertyPersistence] = ["name" : DBBPropertyPersistence(type: .string),
                                                      "code" : DBBPropertyPersistence(type: .string),
                                                      "startDate" : DBBPropertyPersistence(type: .date),
                                                      "endDate" : DBBPropertyPersistence(type: .date),
                                                      "budget" : DBBPropertyPersistence(type: .float),
                                                      "meetings" : DBBPropertyPersistence(type: .dbbObjectArray(objectType: Meeting.self)),
                                                      "tags" : DBBPropertyPersistence(type: .stringArray),
                                                      "subProject" : DBBPropertyPersistence(type: .dbbObject(objectType: Project.self)),
                                                      "projectLead" : DBBPropertyPersistence(type: .dbbObject(objectType: Person.self))]
        dbManager.addPersistenceMapContents(map, forTableNamed: shortName)
    }

```

You can see more examples of DBBTableObject initialization in the demo projects included in the DBBBuilder workspace.

In addition, there is an Xcode project in the workspace named _CodeGenerator_ that can automatically generate much of the boilerplate for a DBBTableObject subclass, given the subclass name and a list of properties. See the README in its folder for usage directions.

_Adding indexes_: If you want to include an index for any column (i.e. property), create a DBBIndex instance with that property's name in the indexer's _columNames_ String array property, and include that as the optional __indexer__ argument in the addPersistenceMapContents(contents, table, indexer) method call. You can add indexes for any property in a DBBTableObject subclass. If a property is defined as a DBBTableObject type or as an array, DBBBuilder stores data in a join table and automatically indexes that table.

__Additional properties__: DBBTableObject has two other properties you may want to take advantage of in different situations.

`attributesDictionary: [String : String]?`

An optional dictionary that lets you define attributes to apply to class properties. The dictionary's keys are property names, and values are attributes to their database columns, either NOT NULL or DISTINCT. See the section on [Helpers](#helpers) for more.
    
`isDirty`

A Boolean value you can set and read from your application code to set and determine whether an object is an altered state.

####DBBPropertyPersistence
DBBPropertyPersistence is used as part of the process of initializing a DBBManager instance to define the properties that should be persisted to the database file. As explained above, it is best practice to add this meta-data as part of a DBBTableObject subclass's initialization process.

__initialization:__ `public init(type: DBBStorageType)`

_type_: A member of the DBBStorageType enum that defines the property's type. [See below.](#dbbstoragetype)

__Or:__ `public init(type: DBBStorageType, columnName: String)`

_type_: Same as above.

_columnName_: A String argument that defines an alternate name to use in the database file to define this property. This is useful if you're working with an existing database table and want or need to have a different name for a corresponding property.

####DBBIndexer

DBBIndexer is used to contain the names of all database columns (properties) that should be indexed for a table. You can also set the indexer's _unique_ property to true if the index should only work on unique values.

__initialization:__ `public init(columnsToIndex: [String], unique: Bool = false)`

_columnsToIndex_: A String array of names of properties that should be indexed in the database file.

_unique_: A Bool value telling DBBBuilder to create UNIQUE indexes. It is set to False by default.

####DBBStorageType<a name="dbbstoragetype"></a>

An enum that defines the types DBBBuilder can persist to the database file. You use tyese types to configure your DBBManager instance(s) with mapping that tells them what to persist to file and how to persist it.

- .bool - Boolean values
- .int - All Integer types
- .float - All floating point numbers
- .string - Strings
- .date - Dates
- .dbbObject - Any DBBTableObject subclass
- .boolArray - Array of Boolean values
- .intArray - Array of Integer types
- .floatArray - Array of floating point numbers
- .stringArray - Array of Strings
- .dateArrat - Array of Dates
- .dbbObjectArray - Array of DBBTableObject subclass

The dbbObject and dbbObjectArray members take an `objectType` argument in their initializers. This is a specific subclass type.

See the [DBBTableObject discussion above](#complete-init) for an example of DBBStorageType usage.

####Writing Objects To The Database

There is one method for saving any DBBTableObject subclass instance to the database.

`public func saveToDB() -> Bool`

This method returns a Boolean value indicating whether the save succeeded. In case of failure you can get an error message from the underlying database by accessing the lastErrorMessage function of the DBManager's database object. For example:

```
print(dbMgr.database.lastErrorMessage())
```

####Retrieving Objects From the Database

There are several methods for retrieving objets from the database. All of them are static methods that should be clled on your DBBTableObject subclass types. Each method returns either a single DBBTableObject instance or an array of them. As such you will need to cast them to their subclass type in order to use them in most cases. For example:

```
guard let projects = Project.allInstances(manager: manager) as? [Project] else {
    return
}
```

`public static func allInstances(manager: DBBManager) -> [DBBTableObject]`

A static method to retrieve all instances of a DBBTableObject subclass from the database.
 
_manager_: A DBBManager instance that owns the FMDB instance/SQLite file being read from.`

_Returns_: An array of all instances of the subclass in the database, fully populated.

`public static func instancesWithOptions(_ options: DBBQueryOptions, manager: DBBManager, sparsePopulation: Bool = false) -> [DBBTableObject]?`

A static method to retrieve DBBTableObjects that meet defined criteria.

_options_: A DBBQueryOptions instance that defines characteristics of the DBBTableObjects you want to retrieve. See the section on _DBBQueryOptions_ [below](#dbbqueryoptions) for details.

_manager_: A DBBManager instance that owns the FMDB instance/SQLite file being read from.`

_sparsePopulation_: An optional Boolean value indicating whether you would like returned objects to be populated only with their id and created and modified dates. The default value is False.

_Returns_: An optional array of instances that meet the parameters passed in as options.

`public static func getInstancesFromQueue(withOptions options: DBBQueryOptions,
                                             manager: DBBManager,
                                             sparsePopulation: Bool = false,
                                             completion: ([DBBTableObject], NSError?) -> Void)`

A static method to get an array of DBBTableObjects that meet requested criteria in a completion handler.
                                             
_options_: A DBBQueryOptions instance that defines characteristics of the DBBTableObjects you want to retrieve. See the section on _DBBQueryOptions_ [below](#dbbqueryoptions) for details.

_manager_: A DBBManager instance that owns the FMDB instance/SQLite file being read from.`

_sparsePopulation_: An optional Boolean value indicating whether you would like returned objects to be populated only with their id and created and modified dates. The default value is False.

_completion_: A closure that is called when the fetch is complete. At the calling site you'll get an array of DBBTableObject subclasses that meet your criteria, and an optional error, which if non-nil, provides information on the reason for the failure.

`public static func instanceWithIDNumber(_ id: Int64, manager: DBBManager, sparsePopulation: Bool = false) -> DBBTableObject?`

A static method to get a single DBBTableObject subclass instance matching the ID number passed in.

_id_: An Int64 value representing the id number for the instance you want to retrieve.

_manager_: A DBBManager instance that owns the FMDB instance/SQLite file being read from.

_sparsePopulation_: An optional Boolean value indicating whether you would like the returned object to be populated only with its id and created and modified dates. The default value is False.

_Returns_: An optional DBBTableObject instance whose id property matches the id value passed in.

`public static func instancesWithIDNumbers(_ ids: [Int64], manager: DBBManager) -> [DBBTableObject]`

A static method to get an array of DBBTableObject subclass instances matching the ID numbers passed in.

_ids_: An array of Int64 values representing the id numbers for the instances you want to retrieve.

_manager_: A DBBManager instance that owns the FMDB instance/SQLite file being read from.

_sparsePopulation_: An optional Boolean value indicating whether you would like returned objects to be populated only with their id and created and modified dates. The default value is False.

_Returns_: An array of DBBTableObject instance whose id properties match the id values passed in.

`public static func allInstanceIDs(manager: DBBManager) -> [Int64]`

A static method to retrieve the ids of all instances of a DBBTableObject subclass from the database. 

_manager_: A DBBManager instance that owns the FMDB instance/SQLite file being read from.

_Returns_: An optional DBBTableObject instance whose id property matches the id value passed in.n array of Int64 values representing all the id values for the subclass you ran the request on.

####DBBQueryOptions<a name="dbbqueryoptions"></a>

When retrieving objects from the database, some methods take a DBBQueryOptions argument to determine which and how objects should be returned.

The DBBQueryOptions struct has five properties that can be set to influence fetch results for methods that take a DBBQueryOptions argument.

_propertyNames_: An optional array of strings for properties to include in the results. Properties that are omitted do not have their values populated. This can enhance performance if the object graph is complex and not all properties are needed in certain cases.
    
_joinPropertiesToPopulate_: An optional array of strings for properties from join tables (arrays, binary values and DBBTableObject types) to include in the results. Properties that are omitted do not have their values populated. This can enhance performance if the object graph is complex and not all properties are needed in certain cases.

_sorting_: An optional array of strings for column sort orders, by sort priorty. All columns receive the same ascending or descending order. You can change the default ascending sort order to descending by including the `ColumnSorting.descending` value (defined in DBBBuilder.swift) as one of the items in the array.

_conditions_: An optional array of strings specifying conditions to match on, which are added to a WHERE clause. Each array item should define one condition to match on, e.g. "score > 50". By default, condition clauses are created with AND logic. If you instead want OR logic, add "OR" as an item in the array.

_distinct_: A boolean value for specifying distinct return values. The default for this option is False.

There are several convenience methods for getting partially populated DBBQueryOptions instances. If you declare the instance as a var at the calling site, you can modify other properties as desired.

`public static func queryOptionsWithPropertyNames(_ properties: [String], distinct: Bool = false) -> DBBQueryOptions`

Method to get a DBBQueryOptions instance with the propertyNames values passed in, and optionally its distinct value.

_properties_: A string array of property names to populate.

_distinct_: An optional Boolean value to specify returning only distinct values. Pass True if you want to override the default False value.

`public static func queryOptionsWithAscendingSortForColumns(_ columnNames: [String]) -> DBBQueryOptions`

Method to get a DBBQueryOptions instance for sorting in ascending order by the columns passed in, and optionally its distinct value.

_columnNames_: A string array of column names to determine sorting order.

_distinct_: An optional Boolean value to specify returning only distinct values. Pass True if you want to override the default False value.

`public static func queryOptionsWithDescendingSortForColumns(_ columnNames: [String]) -> DBBQueryOptions`

Method to get a DBBQueryOptions instance for sorting in descending order by the columns passed in, and optionally its distinct value.

_columnNames_: A string array of column names to determine sorting order.

_distinct_: An optional Boolean value to specify returning only distinct values. Pass True if you want to override the default False value.

`public static func queryOptionsWithConditions(_ conditions: [String], distinct: Bool = false) -> DBBQueryOptions`

Method to get a DBBQueryOptions instance with conditions to match on, and optionally its distinct value.

_conditions_: A string array of conditions to match on.

_distinct_: An optional Boolean value to specify returning only distinct values. Pass True if you want to override the default False value.

####Optimizing Reads

There are a couple of strategies you can pursue to enhance the performance of object retrieval. If your object graph is complex, you may want to consider one of these strategies to improve the user experience.

__Sparse object population:__ Some of the object retrieval methods have an optional _sparsePopulation_ argument which defaults to False. If you pass in True for this value, you will get back objects which only have their _id_, _createdTime_, and _modifiedTime_ values populated.

__Explicit object population:__ Some of the object retrieval methods let you specify what properties should be populated with a DBBQueryOptions instance. This is a less severe form of sparse population that can still improve performance for complex objects. You could benefit from this approach when you need to fetch many objects, but only need to display basic information to the user in a view.

####Helpers<a name="helpers"></a>

There are some helper methods and definitions available in different classes that may be useful at various points of development.

__ColumnAttributes:__ There is a publicly accessible _ColumnAttributes_ struct in the DBBBuilder.swift file that defines `notNull = "NOT NULL"` and `unique = "UNIQUE"` which you may want to use if setting a DBBTableObject subclass's _attributesDictionary_ property.

__ColumnSorting:__ There is a publicly accessible _ColumnSorting_ struct in the DBBBuilder.swift file that defines `ascending = "ASC` and `descending = "DESC"` which you may want to use for assigning sort order query options.

__Table/object count:__ `public func countForTable(_ tableName: String) -> Int`

A publicly accessible method in DBBManager for getting the count of rows in any table.

_tableName_: The name of the DBBTableObject subclass whose count you want to access.

_Returns_: The number of rows (object instances) in the database file for that subclass.

__Database cleanup:__ `public func vacuumDB()`

You may want to periodically clean up the database file. You can do so by calling this helper method in the DBBManager class.

__Dropping indexes:__ `public func dropIndex(named indexName: String) -> Bool`

If you ever want to delete an index from a database file, you can call this method to do so.

_indexName_: The name of the index to drop.

