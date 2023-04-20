//
//  TranformerUIColor.swift
//  ToDoList
//
//  Created by Waliok on 24/10/2022.
//

import Foundation
import UIKit

//MARK: - Creating transformer for persist UiColors in Core Data Base

// Subclass from `NSSecureUnarchiveFromDataTransformer`
@objc(UIColorValueTransformer)
final class ColorValueTransformer: NSSecureUnarchiveFromDataTransformer {
    // The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
    static let name = NSValueTransformerName(rawValue: String(describing: ColorValueTransformer.self))
    // Make sure `UIColor` is in the allowed class list.
    override static var allowedTopLevelClasses: [AnyClass] {
        return super.allowedTopLevelClasses + [UIColor.self]
    }
    // Registers the transformer.
    public static func register() {
        let transformer = ColorValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
