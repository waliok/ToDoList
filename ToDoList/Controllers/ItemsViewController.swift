//
//  ItemsViewController.swift
//  ToDoList
//
//  Created by Waliok on 21/10/2022.
//

import UIKit
import CoreData
import UserNotifications
import EventKit
import ChameleonFramework

class ItemsViewController: UIViewController , UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    var itemArray = [Item]()
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    
    
    let eventStore = EKEventStore()
    let defaults = UserDefaults()
    var xStart: CGFloat?
    var yStart: CGFloat?
    var xEnd: CGFloat?
    var yEnd: CGFloat?
    var gradientDirection = [CGFloat]()
    var state = [Int]()
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
    var gradient = [Gradient]()
    let gradientLayer = CAGradientLayer()
    let colorPickerVC = UIColorPickerViewController()
    var gradientOnOff = Bool()
    var colorsForGradient = [CGColor]()
    var arrayUIColors =  [UIColor]()
    var gradientDirectionChanger = UIBarButtonItem()
    var openCloseGradientSettings = UIBarButtonItem()
    var buttonPressed: Bool = true
    let searchController = UISearchController(searchResultsController: nil)
    
    init(selectedCategory: Category) {
        self.selectedCategory = selectedCategory
        super .init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = selectedCategory?.name
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        navigationItem.searchController = searchController
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.searchTextField.backgroundColor = .placeholderText
        searchController.searchBar.setPlaceholderColor(.black)
        searchController.searchBar.setIconColor(.black)
        definesPresentationContext = true
        
        state = defaults.value(forKey: "state") as? [Int] ?? [1, 0, 0, 0]
        gradientDirection = defaults.value(forKey: "gradientDirection") as? [CGFloat] ?? [0.5, 0, 0.5, 1]
        setPoints(gradientDirection)
        getGradient()
        fillArrayOfGradient()
        addGestureRecognizers()
        setupPopUpMenuButton()
        loadItems()
        /// Set up gradient layer
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
                UIBarButtonItem(image: UIImage(systemName: "paintpalette"), style: .plain, target: self, action: #selector(didTapGradientChange)),
                UIBarButtonItem(image: UIImage(systemName: "paintbrush"), style: .plain, target: self, action: #selector(didTapWipeGradient)),
                gradientDirectionChanger
            ]
            buttonPressed = false
        } else {
            navigationItem.rightBarButtonItems = [openCloseGradientSettings,
                                                  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))]
            navigationItem.leftBarButtonItems = []
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
    
    //MARK: - Button To Add New Item
    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "Create new item.", message: "Add new item name.", preferredStyle: .alert)
        alert.addTextField{ (alertTextField) in
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
    //MARK: - Gesture recognizers
    
    func addGestureRecognizers() {
        
        /// Adding double tap gesture
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didAddRemind))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        tableView.addGestureRecognizer(doubleTapGesture)
        
        /// Adding a single tap gesture
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didAddCheckmark))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        singleTapGesture.require(toFail: doubleTapGesture)
        tableView.addGestureRecognizer(singleTapGesture)
        /// Adding long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didChangeColorOfRow))
        longPressGesture.delegate = self
        tableView.addGestureRecognizer(longPressGesture)
    
    }
    
    @objc func didAddCheckmark(sender: UIGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.ended {
            searchController.searchBar.endEditing(true)
            let tapLocation = sender.location(in: tableView)
            if let tapIndexPath = self.tableView.indexPathForRow(at: tapLocation) {
                if self.tableView.cellForRow(at: tapIndexPath) != nil {
                    guard tableView.isEditing != true else { return }
                    itemArray[tapIndexPath.row].done = !itemArray[tapIndexPath.row].done
//                    tableView.deselectRow(at: tapIndexPath, animated: true)
                    save()
                    loadItems()
                }
            }
        }
    }

    
    // MARK: - LongPress Gesture Configuration (Add a New Date Notification)
    
    @objc func didAddRemind(sender: UIGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.ended {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                var dateSet: Date?
                
                /// Create Alert Controller
                let alert = UIAlertController(title: "Choose a Date to create Remind", message: "Select Date", preferredStyle: .actionSheet)
                /// Add Date Picker to alert controller
//                let datePicker = UIDatePicker()
//                datePicker.datePickerMode = .dateAndTime
//                datePicker.timeZone = NSTimeZone.local
//                datePicker.preferredDatePickerStyle = .wheels
//                datePicker.minimumDate = .now
//                dateSet = datePicker.date
//                alert.view.addSubview(datePicker)

                /// Add constraints
//                NSLayoutConstraint.activate([
//                    alert.view.heightAnchor.constraint(equalToConstant: 370),
//                    datePicker.widthAnchor.constraint(equalTo: alert.view.widthAnchor),
//                    datePicker.heightAnchor.constraint(equalToConstant: 217),
//                    datePicker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 40)
//                ])
//                datePicker.translatesAutoresizingMaskIntoConstraints = false
               
                /// Add date picker via AlertControllerExtension
                alert.addDatePicker(mode: .dateAndTime, date: Date(), minimumDate: .now, maximumDate: nil) { date in
                    dateSet = date
                }
                print("\(String(describing: dateSet))")
                
                /// Add Cancel Buttons
                alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { [weak self] _ in
                    self!.blurVisualEffectView.removeFromSuperview()
                }))
                /// Add OK  button with handler
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler:  { [weak self] _ in
                    guard dateSet != nil else {
                        let sheet = UIAlertController(title: "Date do not selected", message: "Please choose a date", preferredStyle: .alert)
                        sheet.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                            self!.present(alert, animated: true)
                        }))
                        self?.view.addSubview(self!.blurVisualEffectView)
                        self!.present(sheet, animated: true)
                        return
                    }
                    let item = self!.itemArray[indexPath.row]
                    
                    /// Using Date Extension also
                    // item.dateReminder = dateSet?.dateTimeString(ofStyle: .short)
                    /// Without Date Extension
                    let dateFormatter = DateFormatter()
                    dateFormatter.timeStyle = .short
                    dateFormatter.dateStyle = .short
                    /// End
                    item.dateReminder = dateFormatter.string(from: dateSet!)
                    self!.save()
                    self!.loadItems()
                    
                    /// Delete Push Notification if exist
                    if item.createAt != nil {
                        let notificationCenter = UNUserNotificationCenter.current()
                        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["id_\(item.name)-\(String(describing: item.createAt))"])
                        print("Old PUSH Notification date DELETED")
                    }
                    
                    /// Create a new PUSH Notification
                    let content = UNMutableNotificationContent()
                    content.title = "To_Do List - You have something to do :)"
                    content.sound = .default
                    content.body = "\(item.name)"
                    
                    if let targetDate = dateSet {
                        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate), repeats: false)
                        
                        let request = UNNotificationRequest(identifier: "id_\(item.name)-\(String(describing: item.createAt))", content: content, trigger: trigger)
                        UNUserNotificationCenter.current().add(request) { (error) in
                            if error != nil {
                                print("Error Push Notifications Request: \(String(describing: error))")
                            }
                        }
                        DispatchQueue.main.async {
                            
                            /// Delete calendar event if exist
                            if let eventID = item.eventID {
                                if let event = self!.eventStore.event(withIdentifier: eventID) {
                                    do {
                                        try self!.eventStore.remove(event, span: .thisEvent)
                                        item.eventID = nil
                                        self!.save()
                                    } catch let error as NSError {
                                        print("FAILED TO SAVE EVENT WITH ERROR : \(error)")
                                    }
                                    print("Old Calendar Event DELETED")
                                }
                            }
                            
                            /// Create new event
                            let event:EKEvent = EKEvent(eventStore: self!.eventStore)
                            let startDate = targetDate
                            let endDate = startDate.addingTimeInterval(1 * 60 * 60)
                            let alarm = EKAlarm(relativeOffset: -300)
                            let alarm1H = EKAlarm(relativeOffset: -3600)
                            
                            event.title = item.name
                            event.startDate = startDate
                            event.endDate = endDate
                            event.notes = "Created by To_Do List"
                            event.addAlarm(alarm)
                            event.addAlarm(alarm1H)
                            event.calendar = self!.eventStore.defaultCalendarForNewEvents
                            do {
                                try self!.eventStore.save(event, span: .thisEvent)
                                item.eventID = event.eventIdentifier
                                self!.save()
                                self!.loadItems()
                            } catch let error as NSError {
                                print("Failed to save Event With Error: \(error)")
                            }
                            print("Event Saved with ID: \(event.eventIdentifier ?? "error ID")")
                        }
                    }
                    self!.blurVisualEffectView.removeFromSuperview()
                }))
                self.view.addSubview(blurVisualEffectView)
                present(alert, animated: true)
                print("Long press Pressed:\(indexPath.row) \(String(describing: itemArray[indexPath.row].name))")
            }
            self.tableView.reloadData()
        }
    }
    
    
   
    //MARK: - TableView Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = itemArray[indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = model.name
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 25, weight: .medium)
        cell.detailTextLabel?.text = model.dateReminder
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
        
        cell.accessoryType = model.done ? .checkmark : .none
        let backgroundView = UIView()
        backgroundView.backgroundColor = .separator
        cell.selectedBackgroundView = backgroundView
        cell.backgroundColor = model.color
        if let alphaColor = cell.backgroundColor?.rgba.alpha, alphaColor <= 0.5 {
            cell.textLabel?.textColor = .black
            cell.detailTextLabel?.textColor = .black
        } else {
            cell.textLabel?.textColor = ContrastColorOf(model.color, returnFlat: true)
            cell.detailTextLabel?.textColor = ContrastColorOf(model.color, returnFlat: true)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        searchController.searchBar.endEditing(true)
//        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
//        save()
//        loadItems()
//        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    // Method to correct moving cells
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // Moving the cells with changing order indexes in core data
        let dataToMove = itemArray.remove(at: sourceIndexPath.row)
        itemArray.insert(dataToMove, at: destinationIndexPath.row)
        reOrder()
        save()
        loadItems()
    }
    // Implementing delete and editing actions with swipe action.
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Create Delete Reminder
        let deleteReminder = UIContextualAction(style: .destructive, title: "Delete Remind") { [self] (contextualAction, someView, actionPerformed: @escaping (Bool) -> Void) in
            // Make deletion with Alert
            let alert = UIAlertController(title: "Delete Remind", message: "Are you shure?", preferredStyle: .alert)
            // Cancel deletion
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { alertAction in
                actionPerformed(false)
                self.blurVisualEffectView.removeFromSuperview()
            }))
            // Delete action
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { alertAction in
                
                // Delete Notifacations from Notification center
                if self.itemArray[indexPath.row].createAt != nil {
                    let notificationCenter = UNUserNotificationCenter.current()
                    notificationCenter.removePendingNotificationRequests(withIdentifiers: ["id_\(self.itemArray[indexPath.row].name)-\(String(describing: self.itemArray[indexPath.row].createAt))"])
                }
                
                // Delete Event from Calendar and Data base
                if let eventID = self.itemArray[indexPath.row].eventID {
                    if let event = self.eventStore.event(withIdentifier: eventID) {
                        do {
                            try self.eventStore.remove(event, span: .thisEvent)
                            self.itemArray[indexPath.row].eventID = nil
                            self.itemArray[indexPath.row].dateReminder = nil
                        } catch let error as NSError {
                            print("FAILED TO SAVE EVENT WITH ERROR : \(error)")
                        }
                        print("Old Calendar Event DELETED")
                    }
                }
                actionPerformed(true)
                self.blurVisualEffectView.removeFromSuperview()
                self.save()
                self.loadItems()
            }))
            self.view.addSubview(blurVisualEffectView)
            present(alert, animated: true)
        }
        deleteReminder.image = UIImage(systemName: "bookmark.slash")
        deleteReminder.backgroundColor = .systemMint
        return UISwipeActionsConfiguration(actions: [deleteReminder])
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Create delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [self] (contextualAction, someView, actionPerformed: @escaping (Bool) -> Void) in
            //Make deletion without Alert
            //            self.deleteItems(item: models[indexPath.row])
            //            tableView.deleteRows(at: [indexPath], with: .automatic)
            //            actionPerformed(true)
            //            save()
            
            // Make deletion with Alert
            let alert = UIAlertController(title: "Delete", message: "Are you shure?", preferredStyle: .alert)
            // Cancel deletion
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { alertAction in
                actionPerformed(false)
                self.blurVisualEffectView.removeFromSuperview()
            }))
            // Delete action
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { alertAction in
                
                // Delete Notifacations from Notification center
                if self.itemArray[indexPath.row].createAt != nil {
                    let notificationCenter = UNUserNotificationCenter.current()
                    notificationCenter.removePendingNotificationRequests(withIdentifiers: ["id_\(self.itemArray[indexPath.row].name)-\(String(describing: self.itemArray[indexPath.row].createAt))"])
                }
                // Delete event from calendar
                
                if let eventID = self.itemArray[indexPath.row].eventID {
                    if let event = self.eventStore.event(withIdentifier: eventID) {
                        do {
                            try self.eventStore.remove(event, span: .thisEvent)
                        } catch let error as NSError {
                            print("FAILED TO SAVE EVENT WITH ERROR : \(error)")
                        }
                        print("Old Calendar Event DELETED")
                    }
                }
                
                // Delete Item from Data bese
                self.deleteItems(item: self.itemArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .automatic)
                actionPerformed(true)
                self.blurVisualEffectView.removeFromSuperview()
                self.save()
            }))
            self.view.addSubview(blurVisualEffectView)
            present(alert, animated: true)
        }
        deleteAction.title = "Delete"
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        
//        // Create Delete Reminder
//        let deleteReminder = UIContextualAction(style: .destructive, title: "Delete Remind") { [self] (contextualAction, someView, actionPerformed: @escaping (Bool) -> Void) in
//            // Make deletion with Alert
//            let alert = UIAlertController(title: "Delete Remind", message: "Are you shure?", preferredStyle: .alert)
//            // Cancel deletion
//            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { alertAction in
//                actionPerformed(false)
//                self.blurVisualEffectView.removeFromSuperview()
//            }))
//            // Delete action
//            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { alertAction in
//
//                // Delete Notifacations from Notification center
//                if self.itemArray[indexPath.row].createAt != nil {
//                    let notificationCenter = UNUserNotificationCenter.current()
//                    notificationCenter.removePendingNotificationRequests(withIdentifiers: ["id_\(self.itemArray[indexPath.row].name)-\(String(describing: self.itemArray[indexPath.row].createAt))"])
//                }
//
//                // Delete Event from Calendar and Data base
//                if let eventID = self.itemArray[indexPath.row].eventID {
//                    if let event = self.eventStore.event(withIdentifier: eventID) {
//                        do {
//                            try self.eventStore.remove(event, span: .thisEvent)
//                            self.itemArray[indexPath.row].eventID = nil
//                            self.itemArray[indexPath.row].dateReminder = nil
//                        } catch let error as NSError {
//                            print("FAILED TO SAVE EVENT WITH ERROR : \(error)")
//                        }
//                        print("Old Calendar Event DELETED")
//                    }
//                }
//                actionPerformed(true)
//                self.blurVisualEffectView.removeFromSuperview()
//                self.save()
//                self.loadItems()
//            }))
//            self.view.addSubview(blurVisualEffectView)
//            present(alert, animated: true)
//        }
//        deleteReminder.image = UIImage(systemName: "bookmark.slash")
//        deleteReminder.backgroundColor = .systemMint
        
        // Create edit action
        let editAction = UIContextualAction(style: .destructive, title: "Edit") { [self] (contextualAction, someView, actionPerformed: @escaping (Bool) -> Void) in
            let alert = UIAlertController(title: "Edit", message: "Please make your changes", preferredStyle: .alert)
            alert.addTextField(configurationHandler: nil)
            alert.textFields?.first?.text = self.itemArray[indexPath.row].name
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
                self!.blurVisualEffectView.removeFromSuperview()
                actionPerformed(true)
            }))
            alert.addAction(UIAlertAction(title: "Save",  style: .default, handler: { [self] _ in
                guard let field = alert.textFields?.first, let newName = field.text, !newName.isEmpty else {
                    let sheet = UIAlertController(title: "Text field is empty", message: "Please type something...", preferredStyle: .alert)
                    sheet.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        self.present(alert, animated: true, completion: nil)
                    }))
                    self.present(sheet, animated: true)
                    return
                }
                actionPerformed(true)
                self.blurVisualEffectView.removeFromSuperview()
                self.updateItem(item: self.itemArray[indexPath.row], newName: newName)
            }))
            self.view.addSubview(blurVisualEffectView)
            self.present(alert, animated: true)
        }
        editAction.image = UIImage(systemName: "pencil.line")
        editAction.backgroundColor = .systemYellow
        
        return UISwipeActionsConfiguration(actions: [deleteAction, /*deleteReminder,*/ editAction])
    }
    //MARK: - CoreData Methods
    
    func reOrder() {
        guard itemArray.count > 1 else { return }
        for i in 0...itemArray.count - 1 {
            itemArray[i].index = i
        }
    }
    
    func save() {
        do {
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
    }
    
    func createItem(name: String) {
        let newItem = Item(context: self.context)
        newItem.name = name
        newItem.createAt = Date()
        newItem.index = itemArray.count
        newItem.color = .clear
        newItem.category = selectedCategory
        newItem.done = false
        
        do {
            try self.context.save()
            loadItems()
        } catch {
            print(error)
        }
    }
    
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        let categoryPredicate = NSPredicate(format: "category.name MATCHES %@", selectedCategory!.name)
        let sectionSortDescriptor = NSSortDescriptor(key: "index", ascending: true)
        let sortDescriptors = [sectionSortDescriptor]
        request.sortDescriptors = sortDescriptors
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        do {
            itemArray = try context.fetch(request)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Error fetching data from context \(error)")
        }
    }
    
    func deleteItems(item: Item) {
        if item.createAt != nil {
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.removePendingNotificationRequests(withIdentifiers: ["id_\(item.name)-\(String(describing: item.createAt))"])
        }
        
        if let eventID = item.eventID {
            if let event = self.eventStore.event(withIdentifier: eventID) {
                do {
                    try self.eventStore.remove(event, span: .thisEvent)
                } catch let error as NSError {
                    print("ERROR DELETING EVENT: \(error)")
                }
            }
        }
        context.delete(item)
        reOrder()
        do {
            try context.save()
            loadItems()
        } catch {
            print(error)
        }
    }
    
    func updateItem(item: Item, newName: String) {
        item.name = newName
        do {
            try context.save()
            loadItems()
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

extension ItemsViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return [UIDragItem(itemProvider: NSItemProvider())]
    }
}

extension ItemsViewController: UITableViewDropDelegate {
    
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

extension ItemsViewController: UIColorPickerViewControllerDelegate {
    
    @objc func didChangeColorOfRow(sender: UIGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.ended {
            gradientOnOff = false
            let tapLocation = sender.location(in: tableView)
            if let tapIndexPath = self.tableView.indexPathForRow(at: tapLocation) {
                if self.tableView.cellForRow(at: tapIndexPath) != nil /* add  as? MyTableViewCell for custom cell */{
                    
                    selectedRow = tapIndexPath.row
                    colorPickerVC.title = "Choose the color"
                    colorPickerVC.selectedColor = itemArray[selectedRow!].color
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
            itemArray[colorIndex].color = color
            save()
            loadItems()
        }
    }
    
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        let color = viewController.selectedColor
        if let colorIndex = selectedRow {
            itemArray[colorIndex].color = color
            save()
            loadItems()
        }
    }
}

extension ItemsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        tableView.dragInteractionEnabled = false
        guard let text = searchController.searchBar.text else { return }
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        let predicate = NSPredicate(format: "name CONTAINS[cd] %@", text)
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        loadItems(with: request, predicate: predicate)
        if searchController.searchBar.text?.count == 0 {
            loadItems()
            tableView.dragInteractionEnabled = true
        }
    }
}

extension ItemsViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //        searchBar.resignFirstResponder()
        searchController.searchBar.endEditing(true)
        searchController.isActive = false
        tableView.dragInteractionEnabled = true
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //        searchBar.resignFirstResponder()
        searchController.searchBar.endEditing(true)
        searchController.isActive = false
        loadItems()
        tableView.dragInteractionEnabled = true
    }
}
