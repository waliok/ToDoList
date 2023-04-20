//
//  ViewController.swift
//  ToDoList
//
//  Created by Waliok on 21/10/2022.
//

import UIKit

class ContainerViewController: UIViewController {
    
    enum MenuState {
        case opened
        case closed
    }
    
    public var menuState: MenuState = .closed
    
    var controller: UIViewController!
    let sideMenuVC = SideMenuViewController()
    let mainVC = CategoriesViewController()
    var navVC: UINavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        configureSideMenuViewController()
        configureMainViewController()
    }
    
    func configureMainViewController() {
        let navVC = UINavigationController(rootViewController: mainVC)
        self.navVC = navVC
        addChild(navVC)
        view.addSubview(navVC.view)
        navVC.didMove(toParent: self)
        mainVC.delegate = self
        navVC.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navVC.navigationBar.shadowImage = UIImage()
        navVC.navigationBar.isTranslucent = true
        navVC.navigationBar.backgroundColor = .clear
        navVC.navigationBar.tintColor = .black
        navVC.navigationBar.prefersLargeTitles = true
        navVC.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]
        navVC.navigationBar.backIndicatorImage = UIImage(systemName: "chevron.left.2")
        navVC.navigationBar.backIndicatorTransitionMaskImage = UIImage(systemName: "chevron.left.2")
    }
    
    func configureSideMenuViewController() {
        addChild(sideMenuVC)
        view.addSubview(sideMenuVC.view)
        sideMenuVC.didMove(toParent: self)
    }
}

extension ContainerViewController: CategoryViewControllerDelegate {
    func openMenu() {
        menuState = .closed
    }
    func closeMenu() {
        menuState = .opened
    }
    func didTapMenuButton() {
        switch menuState {
        case .closed:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.navVC?.view.frame.origin.x = self.mainVC.view.frame.size.width - self.mainVC.view.frame.size.width / 1.6
            } completion: { [weak self] done in
                if done {
                    self?.menuState = .opened
                }
            }
        case .opened:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.navVC?.view.frame.origin.x = 0
            } completion: { [weak self] done in
                if done {
                    self?.menuState = .closed
                }
            }
            break
        }
    }
}
