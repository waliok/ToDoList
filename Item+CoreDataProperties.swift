//
//  Item+CoreDataProperties.swift
//  ToDoList
//
//  Created by Waliok on 27/10/2022.
//
//

import Foundation
import CoreData
import UIKit


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var color: UIColor
    @NSManaged public var createAt: Date?
    @NSManaged public var done: Bool
    @NSManaged public var index: Int
    @NSManaged public var name: String
    @NSManaged public var eventID: String?
    @NSManaged public var dateReminder: String?
    @NSManaged public var category: Category?

}

extension Item : Identifiable {

}
