//
//  CategoriesViewController.swift
//  ToDoList
//
//  Created by Waliok on 21/10/2022.
//

import UIKit
import CoreData
import ChameleonFramework
import UserNotifications
import EventKit

protocol CategoryViewControllerDelegate: AnyObject {
    func didTapMenuButton()
    func closeMenu()
    func openMenu()
}

class CategoriesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate{
    
    let eventStore = EKEventStore()
    let defaults = UserDefaults()
    var xStart: CGFloat?
    var yStart: CGFloat?
    var xEnd: CGFloat?
    var yEnd: CGFloat?
    var gradientDirection = [CGFloat]()
    var state = [Int]()
    
    
    weak var delegate: CategoryViewControllerDelegate?
    let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.rowHeight = 91
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.separatorColor = .darkGray
        return tableView
    }()
    let blurVisualEffectView: UIVisualEffectView = {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.alpha = 0.75
        return blur
    }()
    var selectedRow: Int?
    var models = [Category]()
    var gradient = [Gradient]()
    let gradientLayer = CAGradientLayer()
    let colorPickerVC = UIColorPickerViewController()
    var gradientOnOff = Bool()
    var colorsForGradient = [CGColor]()
    var arrayUIColors =  [UIColor]()
    var gradientDirectionChanger = UIBarButtonItem()
    var openCloseGradientSettings = UIBarButtonItem()
    var buttonPressed: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorizationCalendarEvent()
        authorizationPushNotification()
        title = "Categories"
        state = defaults.value(forKey: "state") as? [Int] ?? [1, 0, 0, 0]
        gradientDirection = defaults.value(forKey: "gradientDirection") as? [CGFloat] ?? [0.5, 0, 0.5, 1]
        setPoints(gradientDirection)
        getGradient()
        fillArrayOfGradient()
        addGestureRecognizers()
        setupPopUpMenuButton()
        getAllCategories()
        // Set up gradient layer
        gradientLayer.colors = colorsForGradient
        gradientLayer.startPoint = CGPoint(x: xStart ?? 0.5, y: yStart ?? 0)
        gradientLayer.endPoint = CGPoint(x: xEnd ?? 0.5, y: yEnd ?? 1)
        view.layer.addSublayer(gradientLayer)
        // Set up table view
        view.addSubview(tableView)
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.delegate = self
        tableView.dataSource = self
        // Set up Navigation bar buttons
        openCloseGradientSettings = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"), style: .plain, target: self, action: #selector(didTapSetNavigatinBarButtons))
        navigationItem.rightBarButtonItems = [openCloseGradientSettings,
      UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))]
        navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "list.dash"), style: .plain, target: self, action: #selector(didTapMenuButton))]
    }
    override func viewWillAppear(_ animated: Bool) {
        viewDidLoad()
    }
    
    func authorizationPushNotification() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in
        if success {
            print("USER PUSH NOTIFICATION SUCCESS")
        } else if let error = error {
            print("Error USER NOTIFICATION : \(error)")
        }
    }
    }
    
    // MARK: - Request to use Calendar
    func authorizationCalendarEvent() {
        
    let eventStore = EKEventStore()
        
    switch EKEventStore.authorizationStatus(for: .event) {
    case .authorized:
        print("CALENDAR AUTHORIZED")
    case .denied:
        print("CALENDAR ACCESS DENIED")
    case .notDetermined:
        eventStore.requestAccess(to: .event, completion:
            {(granted: Bool, error: Error?) -> Void in
                if granted {
                    print("CALENDAR GRANTED")
                } else {
                    print("CALENDAR ACCESS DENIED")
                }
        })
    default:
        print("CALENDAR CASE DEFAULT")
    }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        gradientLayer.frame = view.frame
        blurVisualEffectView.frame = view.frame
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
    
    @objc func didTapSetNavigatinBarButtons() {
        
        if buttonPressed {
            navigationItem.rightBarButtonItems = [
                openCloseGradientSettings,
                UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
            ]
            navigationItem.leftBarButtonItems = [
                UIBarButtonItem(image: UIImage(systemName: "list.dash"), style: .plain, target: self, action: #selector(didTapMenuButton)),
                UIBarButtonItem(image: UIImage(systemName: "paintpalette"), style: .plain, target: self, action: #selector(didTapGradientChange)),
                UIBarButtonItem(image: UIImage(systemName: "paintbrush"), style: .plain, target: self, action: #selector(didTapWipeGradient)),
                gradientDirectionChanger
            ]
            buttonPressed = false
        } else {
            navigationItem.rightBarButtonItems = [openCloseGradientSettings,
          UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))]
            navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "list.dash"), style: .plain, target: self, action: #selector(didTapMenuButton))]
            buttonPressed = true
        }
    }
    func setupPopUpMenuButton() {
        let menuClosure = {(action: UIAction) in
            self.update(number: action.image!)
        }
        gradientDirectionChanger.menu = UIMenu(children: [
            UIAction(title: "From up to down", image: UIImage(systemName: "arrow.down"), state: UIMenuElement.State(rawValue: state[0]) ?? .off, handler: menuClosure),
            UIAction(title: "From left to right", image: UIImage(systemName: "arrow.forward"), state: UIMenuElement.State(rawValue: state[1]) ?? .off, handler: menuClosure),
            UIAction(title: "From left corner", image: UIImage(systemName: "arrow.down.right"), state: UIMenuElement.State(rawValue: state[2]) ?? .off, handler: menuClosure),
            UIAction(title: "From right corner", image: UIImage(systemName: "arrow.down.left"), state: UIMenuElement.State(rawValue: state[3]) ?? .off, handler: menuClosure)
        ])
        //        button.showsMenuAsPrimaryAction = true
        gradientDirectionChanger.changesSelectionAsPrimaryAction = true
    }
    
    func setPoints(_ points: [CGFloat]) {
        xStart = points[0]
        yStart = points[1]
        xEnd = points[2]
        yEnd = points[3]
    }
    
    func setDirection() {
        gradientLayer.startPoint = CGPoint(x: xStart ?? 0, y: yStart ?? 0.5)
        gradientLayer.endPoint = CGPoint(x: xEnd ?? 1 , y: yEnd ?? 0.5)
        defaults.setValue(gradientDirection, forKey: "gradientDirection")
        defaults.setValue(state, forKey: "state")
    }
    
    func update(number: UIImage) {
        switch number {
        case UIImage(systemName: "arrow.down"):
            gradientDirectionChanger.image = UIImage(systemName: "arrow.down")
            gradientDirection = [0.5, 0.0, 0.5, 1]
            state = [1, 0, 0, 0]
            setPoints(gradientDirection)
            setDirection()
            
        case UIImage(systemName: "arrow.forward"):
            gradientDirectionChanger.image = UIImage(systemName: "arrow.forward")
            gradientDirection = [0, 0.5, 1, 0.5]
            state = [0, 1, 0, 0]
            setPoints(gradientDirection)
            setDirection()
        case UIImage(systemName: "arrow.down.right"):
            gradientDirectionChanger.image = UIImage(systemName: "arrow.down.right")
            gradientDirection = [0, 0, 1, 1]
            state = [0, 0, 1, 0]
            setPoints(gradientDirection)
            setDirection()
            
        case UIImage(systemName: "arrow.down.left"):
            gradientDirectionChanger.image = UIImage(systemName: "arrow.down.left")
            gradientDirection = [1, 0, 0, 1]
            state = [0, 0, 0, 1]
            setPoints(gradientDirection)
            setDirection()
            
        default:
            gradientDirectionChanger.image = UIImage(systemName: "arrow.down")
            gradientDirection = [0.5, 0.0, 0.5, 1]
            state = [1, 0, 0, 0]
            setPoints(gradientDirection)
            setDirection()
        }
    }
    
    func fillArrayOfGradient() {
        if gradient.count == 0 {
            colorsForGradient = [UIColor.systemYellow.cgColor, UIColor.systemGreen.cgColor, UIColor.systemBlue.cgColor]
            arrayUIColors = colorsForGradient.map({UIColor(cgColor: $0)})
            createGradient()
        } else {
            colorsForGradient = gradient[0].colorArray.map({$0.cgColor})
        }
    }
    
    @objc func didTapWipeGradient() {
        deleteGradient()
        gradientLayer.colors?.removeAll()
        gradientLayer.colors?.append(contentsOf: [UIColor.white.cgColor, UIColor.white.cgColor])
        colorsForGradient = gradientLayer.colors! as! [CGColor]
        wipeGradient()
        tableView.removeFromSuperview()
        view.addSubview(tableView)
    }
    
    @objc func didTapGradientChange() {
        gradientOnOff = true
        selectedRow = nil
        colorPickerVC.title = "Choose your gradient"
        colorPickerVC.delegate = self
        colorPickerVC.selectedColor = UIColor(cgColor: gradientLayer.colors!.last as! CGColor)
        present(colorPickerVC, animated: true)
    }
    
    @objc func didTapMenuButton() {
        delegate?.didTapMenuButton()
    }
    
    //MARK: - Button To Add New Item
    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "Create new category.", message: "Add new category name.", preferredStyle: .alert)
        alert.addTextField{ alertTextField in
            alertTextField.placeholder = "Type here..."
            alertTextField.autocorrectionType = .yes
            alertTextField.spellCheckingType = .yes
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in self!.blurVisualEffectView.removeFromSuperview()
            
        }))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak self] _ in
            guard let field = alert.textFields?.first, let text = field.text, !text.isEmpty else {
                let sheet = UIAlertController(title: "Text field is empty", message: "Please type something...", preferredStyle: .alert)
                sheet.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    self?.present(alert, animated: true, completion: nil)
                }))
                self?.view.addSubview(self!.blurVisualEffectView)
                self?.present(sheet, animated: true)
                
                return
            }
            self!.blurVisualEffectView.removeFromSuperview()
            self?.createItem(name: text)
        }))
        self.view.addSubview(blurVisualEffectView)
        present(alert, animated: true)
    }
    
    //MARK: - Gesture Recognition Methods
    func addGestureRecognizers() {
        // Add swipe left swipe gesture recognizer for close side menu
        let swipeGestureLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeToggleMenu(_:)))
        swipeGestureLeft.delegate = self
        swipeGestureLeft.direction = .left
        view.addGestureRecognizer(swipeGestureLeft)
        // Add right swipe gesture recognizer for open side menu
        let swipeGestureRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeToggleMenu(_:)))
        swipeGestureRight.delegate = self
        swipeGestureRight.direction = .right
        view.addGestureRecognizer(swipeGestureRight)
        // Add Double tap gesture Recognizer to change color of cell
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(colorPickerGetFired(_:) ))
        longPress.delegate = self
        tableView.addGestureRecognizer(longPress)
    }
    
    @objc func swipeToggleMenu(_ sender: UISwipeGestureRecognizer) {
        switch  sender.direction {
        case .left:
            delegate?.closeMenu()
            delegate?.didTapMenuButton()
        case .right:
            delegate?.openMenu()
            delegate?.didTapMenuButton()
        default:
            return
        }
    }

    //MARK: - TableView Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "\(String(describing: model.name))"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 25, weight: .medium)
        let backgroundView = UIView()
        backgroundView.backgroundColor = .separator
        cell.selectedBackgroundView = backgroundView
        cell.backgroundColor = model.color
        if let alphaColor = cell.backgroundColor?.rgba.alpha, alphaColor <= 0.5 {
            cell.textLabel?.textColor = .black
        } else {
            cell.textLabel?.textColor = ContrastColorOf(model.color, returnFlat: true)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemVC = ItemsViewController(selectedCategory: models[indexPath.row])
        navigationController?.pushViewController(itemVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    // Method to correct moving cells
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // Moving the cells with changing order indexes in core data
        let dataToMove = models.remove(at: sourceIndexPath.row)
        models.insert(dataToMove, at: destinationIndexPath.row)
        reOrder()
        saveDone()
    }
    // Implementing delete and editing actions with swipe action.
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Create delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [self] (contextualAction, someView, actionPerformed: @escaping (Bool) -> Void) in
            //Make deletion without Alert
            //            self.deleteItems(item: models[indexPath.row])
            //            tableView.deleteRows(at: [indexPath], with: .automatic)
            //            actionPerformed(true)
            //            saveDone()
            
            /// Make deletion with Alert
            let alert = UIAlertController(title: "Delete", message: "Are you shure?", preferredStyle: .alert)
            /// Cancel deletion
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { alertAction in
                actionPerformed(false)
                self.blurVisualEffectView.removeFromSuperview()
            }))
            /// Add Delete action
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { alertAction in
                self.deleteItems(category: self.models[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .automatic)
                actionPerformed(true)
                self.blurVisualEffectView.removeFromSuperview()
                self.saveDone()
            }))
            self.view.addSubview(blurVisualEffectView)
            present(alert, animated: true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        
        
        /// Create edit action
        let editAction = UIContextualAction(style: .destructive, title: "Edit") { [self] (contextualAction, someView, actionPerformed: @escaping (Bool) -> Void) in
            let alert = UIAlertController(title: "Edit", message: "Please make your changes", preferredStyle: .alert)
            alert.addTextField(configurationHandler: nil)
            alert.textFields?.first?.text = self.models[indexPath.row].name
            alert.addAction(UIAlertAction(title: "Save",  style: .cancel, handler: { [self] _ in
                guard let field = alert.textFields?.first, let newName = field.text, !newName.isEmpty else { return }
                actionPerformed(true)
                self.blurVisualEffectView.removeFromSuperview()
                self.updateItem(item: self.models[indexPath.row], newName: newName)
            }))
            self.view.addSubview(blurVisualEffectView)
            self.present(alert, animated: true)
        }
        editAction.image = UIImage(systemName: "pencil.line")
        editAction.backgroundColor = .systemYellow
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }

    //MARK: - CoreData Methods
    
    func reOrder() {
        guard models.count > 1 else { return }
        for i in 0...models.count - 1 {
            models[i].index = i
        }
    }
    
    func saveDone() {
        do {
            try context.save()
            getAllCategories()
        } catch {
            print("Error saving context \(error)")
        }
    }
    
    func getAllCategories() {
        do {
            //Define fetch request with sort descriptor
            let fetchRequest:NSFetchRequest = Category.fetchRequest()
            let sectionSortDescriptor = NSSortDescriptor(key: "index", ascending: true)
            let sortDescriptors = [sectionSortDescriptor]
            fetchRequest.sortDescriptors = sortDescriptors
            //Call fetch from database with sorting
            models = try context.fetch(fetchRequest)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print(error)
        }
    }
    
    func createItem(name: String) {
        let newItem = Category(context: context)
        newItem.name = name
        newItem.index = models.count
        newItem.color = .clear
        do {
            try context.save()
            getAllCategories()
        } catch {
            print(error)
        }
    }
    
    func deleteItems(category: Category) {
        for item in category.items ?? [] {
                
            if (item as! Item).createAt != nil {
                    let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.removePendingNotificationRequests(withIdentifiers: ["id_\(String(describing: (item as! Item).name))-\(String(describing: (item as! Item).createAt))"])
                }
                if let eventID = (item as! Item).eventID {
                    if let event = self.eventStore.event(withIdentifier: eventID) {
                        do {
                            try self.eventStore.remove(event, span: .thisEvent)
                        } catch let error as NSError {
                            print("FAILED TO DELETE EVENT WITH ERROR : \(error)")
                        }
                    }
                }
                
            }
            context.delete(category)
            reOrder()
            do {
                try context.save()
                getAllCategories()
            } catch {
                print(error)
            }
        }
    
    func updateItem(item: Category, newName: String) {
        item.name = newName
        do {
            try context.save()
            getAllCategories()
        } catch {
            print(error)
        }
    }
    //MARK: - Gradient CoreData Methods
    
    func getGradient() {
        do {
            let fetchRequest:NSFetchRequest = Gradient.fetchRequest()
            gradient = try context.fetch(fetchRequest)
        } catch {
            print(error)
        }
    }
    
    func createGradient() {
        let newItem = Gradient(context: context)
        if arrayUIColors.count > 0 {
            newItem.colorArray = arrayUIColors
        } else {
            newItem.colorArray = [UIColor.white, UIColor.white]
        }
        do {
            try context.save()
            
        } catch {
            print(error)
        }
    }
    
    func wipeGradient() {
        let newItem = Gradient(context: context)
        newItem.colorArray = [UIColor.white, UIColor.white]
        do {
            try context.save()
            
        } catch {
            print(error)
        }
    }
    
    func deleteGradient() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Gradient")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try persistentContainer.viewContext.execute(deleteRequest)
        } catch let error as NSError {
            debugPrint(error)
        }
    }
}
//MARK: - Drop And Drag Extensions

extension CategoriesViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return [UIDragItem(itemProvider: NSItemProvider())]
    }
}

extension CategoriesViewController: UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if session.localDragSession != nil { // Drag originated from the same app.
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UITableViewDropProposal(operation: .cancel, intent: .unspecified)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
    }
    
    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        
        let param = UIDragPreviewParameters()
        param.backgroundColor = .clear
        return param
    }
    
    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        
        let param = UIDragPreviewParameters()
        param.backgroundColor = .clear
        return param
    }
}

//MARK: - Color Picker Methods

extension CategoriesViewController: UIColorPickerViewControllerDelegate {
    
    @objc func colorPickerGetFired(_ sender: UIGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.ended {
            gradientOnOff = false
            let tapLocation = sender.location(in: tableView)
            if let tapIndexPath = self.tableView.indexPathForRow(at: tapLocation) {
                if self.tableView.cellForRow(at: tapIndexPath) != nil /* add  as? MyTableViewCell for custom cell */{
                   
                    selectedRow = tapIndexPath.row
                    colorPickerVC.title = "Choose the color"
                    colorPickerVC.selectedColor = models[selectedRow!].color
                    colorPickerVC.delegate = self
                    present(colorPickerVC, animated: true)
                    tableView.deselectRow(at: tapIndexPath, animated: true)
                }
            }
        }
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        
        let color = viewController.selectedColor
        if gradientOnOff {
            guard gradientLayer.colors!.count < 7 else { return }
            if gradientLayer.colors?[0] as! CGColor == UIColor.white.cgColor {
                gradientLayer.colors?.removeAll()
                gradientLayer.colors?.append(contentsOf: [color.cgColor,color.cgColor])
            } else if gradientLayer.colors?[0] as! CGColor == gradientLayer.colors?[1] as! CGColor {
                gradientLayer.colors?.removeLast()
                gradientLayer.colors?.append(color.cgColor)
            } else {
                gradientLayer.colors?.append(color.cgColor)
            }
            deleteGradient()
            colorsForGradient = gradientLayer.colors as! [CGColor]
            arrayUIColors = colorsForGradient.map({UIColor(cgColor: $0)})
            createGradient()
            tableView.removeFromSuperview()
            view.addSubview(tableView)
            gradientOnOff = false
        }
        if let colorIndex = selectedRow {
            models[colorIndex].color = color
            saveDone()
        }
    }
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        let color = viewController.selectedColor
        if let colorIndex = selectedRow {
            models[colorIndex].color = color
            saveDone()
        }
    }
}
