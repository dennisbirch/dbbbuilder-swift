//
//  DBBQueryOptions.swift
//  DBBBuilder-OSX
//
//  Created by Dennis Birch on 1/19/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Foundation

/**
 A struct for use with DBBTableObject methods that require an `options` object for filtering results.
*/
public struct DBBQueryOptions {
    /**
     An optional array of strings for properties to include in the results. Properties that are omitted do not have their values populated.
     */
    public var propertyNames: [String]?
    /**
     An optional array of strings for properties from join tables (arrays, binary values and DBBTableObject types) to include in the results. Properties that are omitted do not have their values populated.
     */
    public var joinPropertiesToPopulate: [String]?
    /**
     An optional array of strings for column sort orders, by sort priorty. All columns receive the same ascending or descending order. You can change the default ascending sort order to descending by including the `ColumnSorting.descending` value (defined in DBBBuilder.swift) as one of the items in the array.
     */
    public var sorting: [String]?
    /**
     An optional array of strings specifying conditions to match on, which are added to a WHERE clause. Each array item should define one condition to match on, e.g. "score > 50". By default, condition clauses are created with AND logic. If you instead want OR logic, add "OR" as an item in the array.
    */
    public var conditions: [String]?
    /**
     A boolean value for specifying distinct return values. The default for this option is False.
    */
    public var distinct = false
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Convenience Methods

    /**
     Convenience method to create a DBBQueryOptions instance with conditions, property name, and sorting arrays, or any combination thereof.
     
     - Parameters:
     - conditions: A string array with the conditions that should be met. Optional.
     - properties: A string array with the names of properties to include in query results. Optional.
     - sortColumns: A string array with the names of columns results should be sorted on, in priority order. Optional.
     - ascendingSort: A Bool value indicating whether columns should be sorted in ascending order. Optional. The default value is True.
     - distinct: An optional Bool value specifying whether it should be a DISTINCT fetch. Optional. The default value is False.
     
     - Returns: A DBBQueryOptions instance with the specified options set to the input received.
     */
    public static func options(withConditions conditions: [String]? = nil, properties: [String]? = nil, sortColumns: [String]? = nil, ascendingSort: Bool = true, distinct: Bool = false) -> DBBQueryOptions {
        var options = DBBQueryOptions()
        options.propertyNames = properties
        options.conditions = conditions
        options.sorting = sortColumns
        let sortOrder = (ascendingSort == true) ? ColumnSorting.ascending : ColumnSorting.descending
        options.sorting?.append(sortOrder)
        options.distinct = distinct
        return options
    }
    
    /**
     Convenience method to create a DBBQueryOptions instance with the specified property names array.
     
     - Parameters:
        - properties: A string array with the names of properties to include in query results.
        - distinct: An optional Bool value specifying whether it should be a DISTINCT fetch. The default value is False.
     
     - Returns: A DBBQueryOptions instance with the `propertyNames` option set to the input received.
    */
    @available(*, deprecated, message: "Use options(withConditions:properties:sortColumns:ascendingSort:distinct:) instead")
    public static func queryOptionsWithPropertyNames(_ properties: [String], distinct: Bool = false) -> DBBQueryOptions {
        var options = DBBQueryOptions()
        options.propertyNames = properties
        options.distinct = distinct
        return options
    }
    
    /**
     Convenience method to create a DBBQueryOptions instance with the specified sorting options in Ascending order.
     
     - Parameters:
         - columnNames: A string array with the names of columns results should be sorted on, in priority order.
         - distinct: An optional Bool value specifying whether it should be a DISTINCT fetch. The default value is False.
     
     - Returns: A DBBQueryOptions instance with the `sorting` option set to the input received.
     */
    @available(*, deprecated, message: "Use options(withConditions:properties:sortColumns:ascendingSort:distinct:) instead")
    public static func queryOptionsWithAscendingSortForColumns(_ columnNames: [String]) -> DBBQueryOptions {
        var options = DBBQueryOptions()
        options.sorting = columnNames
        options.sorting?.append(ColumnSorting.ascending)
        return options
    }

    /**
     Convenience method to create a DBBQueryOptions instance with the specified sorting options in Descending order.
     
     - Parameters:
         - columnNames: A string array with the names of columns results should be sorted on, in priority order.
         - distinct: An optional Bool value specifying whether it should be a DISTINCT fetch. The default value is False.
     
     - Returns: A DBBQueryOptions instance with the `sorting` option set to the input received.
     */
    @available(*, deprecated, message: "Use options(withConditions:properties:sortColumns:ascendingSort:distinct:) instead")
    public static func queryOptionsWithDescendingSortForColumns(_ columnNames: [String]) -> DBBQueryOptions {
        var options = DBBQueryOptions()
        options.sorting = columnNames
        options.sorting?.append(ColumnSorting.descending)
        return options
    }

    /**
     Convenience method to create a DBBQueryOptions instance with the specified condition options.
     
     - Parameters:
         - conditions: A string array with the conditions that should be met.
         - distinct: An optional Bool value specifying whether it should be a DISTINCT fetch. The default value is False.
     
     - Returns: A DBBQueryOptions instance with the `sorting` option set to the input received.
     */
    @available(*, deprecated, message: "Use options(withConditions:properties:sortColumns:ascendingSort:distinct:) instead")
    public static func queryOptionsWithConditions(_ conditions: [String], distinct: Bool = false) -> DBBQueryOptions {
        var options = DBBQueryOptions()
        options.conditions = conditions
        options.distinct = distinct
        return options
    }

}
