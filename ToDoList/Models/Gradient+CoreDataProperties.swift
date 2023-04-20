//
//  Gradient+CoreDataProperties.swift
//  ToDoList
//
//  Created by Waliok on 21/10/2022.
//
//

import Foundation
import CoreData
import UIKit


extension Gradient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Gradient> {
        return NSFetchRequest<Gradient>(entityName: "Gradient")
    }

    @NSManaged public var colorArray: [UIColor]

}

extension Gradient : Identifiable {

}
