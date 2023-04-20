//
//  SideMenuViewController.swift
//  ToDoList
//
//  Created by Waliok on 21/10/2022.
//

import UIKit

class SideMenuViewController: UIViewController {
    
    let verticalStack = UIStackView()
    let imagesForButtons = [UIImage(systemName: "house"), UIImage(systemName: "info.bubble"), UIImage(systemName: "star"), UIImage(systemName: "gear")]
    let imagesTitle = ["Home", "Information", "App Rating", "Settings"]

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .darkGray
        configureStackView()
        setStackViewConstraints()
        addButtons()
    }
    
    func configureStackView() {
        view.addSubview(verticalStack)
        verticalStack.axis = .vertical
        verticalStack.distribution = .fillEqually
        verticalStack.spacing = 1
    }
    
    func setStackViewConstraints() {
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            verticalStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 200) ,
            verticalStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 150) ,
            verticalStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    func addButtons() {
        for i in 0..<imagesForButtons.count {
            let button = UIButton()
            button.tintColor = .white
            button.contentHorizontalAlignment = .leading
            button.setImage(imagesForButtons[i], for: .normal)
            button.setTitle(imagesTitle[i], for: .normal)
            button.setTitleColor(.white, for: .normal)
            verticalStack.addArrangedSubview(button)
        }
    }
}

