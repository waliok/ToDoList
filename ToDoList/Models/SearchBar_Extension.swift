//
//  SearchBar_Extension.swift
//  ToDoList
//
//  Created by Waliok on 25/10/2022.
//

import Foundation
import UIKit

extension UISearchBar {
    
    func setBackgroundColor(_ color: UIColor) {
        if let textfield = self.value(forKey: "searchField") as? UITextField {
            textfield.backgroundColor = color
        }
    }
    
    func setTextColor(_ color: UIColor) {
        if let textfield = self.value(forKey: "searchField") as? UITextField {
            textfield.textColor = color
        }
    }
    
    func setPlaceholderColor(_ color: UIColor) {
        if let textfield = self.value(forKey: "searchField") as? UITextField {
            textfield.attributedPlaceholder = NSAttributedString(string: textfield.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor : color])
        }
    }
    
    func setIconColor(_ color: UIColor) {
        if let textfield = self.value(forKey: "searchField") as? UITextField {
            if let leftView = textfield.leftView as? UIImageView {
                leftView.image = leftView.image?.withRenderingMode(.alwaysTemplate)
                leftView.tintColor = color
            }
        }
    }
}
