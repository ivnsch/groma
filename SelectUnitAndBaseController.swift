//
//  SelectUnitAndBaseController.swift
//  groma
//
//  Created by Ivan Schuetz on 20.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import RealmSwift

struct SelectUnitAndBaseControllerInputs {
    var unitId: UnitId? = nil
    var unitName: String? = nil // assumed to be unique
    var textInputUnitId: UnitId? = nil
    var textInputUnitName: String? = nil
    var hideUnitSelected = false // hide selected state while there's something in the input - we can't just clear the selection input because we have to restore it if the text field is emptied

    var baseQuantity: Float? = nil // assumed to be unique
    var baseQuantityName: String? = nil // assumed to be unique // TODO remove this
    var textInputBaseQuantity: Float? = nil
    var textInputBaseQuantityName: String? = nil
    var hideBaseQuantitySelected = false // see comment for analogous field in unit

    var secondBaseQuantity: Float? = nil // assumed to be unique
    var secondBaseQuantityName: String? = nil // assumed to be unique // TODO remove this
    var textInputSecondBaseQuantity: Float? = nil
    var textInputSecondBaseQuantityName: String? = nil
    var hideSecondBaseQuantitySelected = false // see comment for analogous field in unit

    var unitMarkedToDelete: String? = nil // name (assumed to be unique)
    var baseQuantityMarkedToDelete: String? = nil // name (assumed to be unique)
    var secondBaseQuantityMarkedToDelete: String? = nil // name (assumed to be unique)
}

struct SelectUnitAndBaseControllerResult {
    var unitId: UnitId // TODO remove unitName?
    var unitName: String // assumed to be unique
    var baseQuantity: Float // assumed to be unique
    var secondBaseQuantity: Float? // assumed to be unique
}

class SelectUnitAndBaseController: UIViewController {

    fileprivate let unitsHeaderIndex = 0
    fileprivate let unitsCollectionViewIndex = 1
    fileprivate let unitInputIndex = 2
    fileprivate let basesHeaderIndex = 3
    fileprivate let basesCollectionViewIndex = 4
    fileprivate let basesInputIndex = 5
    fileprivate let secondBasesHeaderIndex = 6
    fileprivate let secondBasesCollectionViewIndex = 7
    fileprivate let secondBasesInputIndex = 8

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var helpButtonImage: UIImageView!

    fileprivate var unitsManager = UnitCollectionViewManager(filterBuyable: true)
    fileprivate var baseQuantitiesManager = BaseQuantitiesCollectionViewManager()
    fileprivate var secondBaseQuantitiesManager = BaseQuantitiesCollectionViewManager()

    fileprivate var inputs = SelectUnitAndBaseControllerInputs()

    fileprivate var unitsViewHeight: CGFloat?
    fileprivate var baseQuantitiesViewHeight: CGFloat?

    var onSubmit: ((SelectUnitAndBaseControllerResult) -> Void)?

    // Optional - if not provided this controller will fetch the units/bases. Reason: Improve performance when it's possible to pre-fetch the unit/bases (e.g. in add recipe to list controller) instead of doing this each time we open this controller, which causes a noticeable delay.
    var fetchUnitsFunc: (() -> AnyRealmCollection<Providers.Unit>?)?
    var fetchBaseQuantitiesFunc: (() -> AnyRealmCollection<BaseQuantity>?)?

    override func viewDidLoad() {
        super.viewDidLoad()
        initTableView()
        configUnitsManager()
        configBaseQuantitiesManager()
        configSecondBaseQuantitiesManager()
        initSubmitView()
        initHelpButton()
        registerKeyboardNotifications()

        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = .all
    }

    func loadItems() {
        unitsManager.loadItems()
        baseQuantitiesManager.loadItems()
        secondBaseQuantitiesManager.loadItems()
    }

    fileprivate func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(SelectUnitAndBaseController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SelectUnitAndBaseController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }

    func config(selectedUnitId: UnitId, selectedUnitName: String, selectedBaseQuantity: Float, secondSelectedBaseQuantity: Float?) {
        // TODO redundancy - only one identifier for unit and base respectively
        inputs.unitId = selectedUnitId
        inputs.unitName = selectedUnitName
        inputs.baseQuantity = selectedBaseQuantity
        inputs.baseQuantityName = selectedBaseQuantity.quantityString
        inputs.secondBaseQuantityName = secondSelectedBaseQuantity?.quantityString

        unitsManager.reload()
        baseQuantitiesManager.reload()
        secondBaseQuantitiesManager.reload()
    }

    fileprivate func initTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(UINib(nibName: "IngredientDataSubHeaderCell", bundle: nil), forCellReuseIdentifier: "subHeaderCell")
        tableView.register(UINib(nibName: "AddNewItemInputCell", bundle: nil), forCellReuseIdentifier: "inputCell")
        tableView.bottomInset = Theme.submitViewHeight
        tableView.keyboardDismissMode = .onDrag
    }

    fileprivate func configUnitsManager() {
        unitsManager.configure(controller: self, canDeselect: false, onSelectItem: { [weak self] unit in guard let weakSelf = self else { return }
            self?.inputs.unitMarkedToDelete = nil // clear possible marked to delete unit
            self?.inputs.unitId = unit?.id
            self?.inputs.unitName = unit?.name
            delay(0.2) { [weak self] in // make it less abrubt
                self?.tableView.scrollTo(row: weakSelf.basesCollectionViewIndex)
            }
        })

        unitsManager.onMarkedItemToDelete = { [weak self] uniqueName in
            self?.inputs.unitMarkedToDelete = uniqueName
            //            if let unit = unit {
            //                self?.unitsManager.markUnitToDelete(unit: unit)
            //            }
        }

        unitsManager.itemMarkedToDelete = { [weak self] in
            return self?.inputs.unitMarkedToDelete
        }
        // for now clear variables BEFORE of realm delete - reason: clear possible selected unit - we have to compare with deleted unit to see if it's the same, and this crashes if it is, because after realm delete the object is invalid.
        // TODO possible solution: Don't retain any Realm objects here, only ids.
        unitsManager.willDeleteItem = { [weak self] unit in
            self?.inputs.unitMarkedToDelete = nil
            if unit.name == self?.inputs.unitName {
                self?.inputs.unitName = trans("unit_unit")
                self?.inputs.unitId = UnitId.none
            }
        }

        unitsManager.clearToDeleteItemsState = { [weak self] in
            self?.inputs.unitMarkedToDelete = nil
        }

        unitsManager.selectedItem = { [weak self] in guard let weakSelf = self else { return nil }
            return weakSelf.inputs.hideUnitSelected ? nil : weakSelf.inputs.unitName
        }

        unitsManager.onFetchedData = { [weak self] in
            self?.initVariableCellHeights()
        }

        unitsManager.fetchFunc = fetchUnitsFunc
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Here collection view width (needed to calculate the content height) is correct - this is for the case
        // where data is fetched before did appear (loadItems() called before showing view)
        initVariableCellHeights()
    }

    fileprivate func initVariableCellHeights() {
        unitsViewHeight = unitsManager.collectionViewContentHeight()
        baseQuantitiesViewHeight = baseQuantitiesManager.collectionViewContentHeight()
        tableView.reloadData()
    }

    fileprivate func configBaseQuantitiesManager() {
        baseQuantitiesManager.configure(controller: self, canDeselect: false, onSelectItem: { [weak self] baseQuantity in
            self?.inputs.baseQuantityMarkedToDelete = nil // clear possible marked to delete unit
            self?.inputs.baseQuantity = baseQuantity?.val
            self?.inputs.baseQuantityName = baseQuantity?.uniqueName
        })

        baseQuantitiesManager.onMarkedItemToDelete = { [weak self] base in
            self?.inputs.baseQuantityMarkedToDelete = base
            //            if let unit = unit {
            //                self?.unitsManager.markUnitToDelete(unit: unit)
            //            }
        }
        baseQuantitiesManager.itemMarkedToDelete = { [weak self] in
            return self?.inputs.baseQuantityMarkedToDelete
        }
        // for now clear variables BEFORE of realm delete - reason: clear possible selected unit - we have to compare with deleted unit to see if it's the same, and this crashes if it is, because after realm delete the object is invalid.
        // TODO possible solution: Don't retain any Realm objects here, only ids.
        baseQuantitiesManager.willDeleteItem = { [weak self] base in
            self?.inputs.baseQuantityMarkedToDelete = nil
            if base.val.quantityString == self?.inputs.baseQuantityName {
                self?.inputs.baseQuantity = 1
                self?.inputs.baseQuantityName = "1"
            }
        }

        baseQuantitiesManager.clearToDeleteItemsState = { [weak self] in
            self?.inputs.baseQuantityMarkedToDelete = nil
        }

        baseQuantitiesManager.selectedItem = { [weak self] in guard let weakSelf = self else { return nil }
            return weakSelf.inputs.hideBaseQuantitySelected ? nil : weakSelf.inputs.baseQuantityName
        }

        baseQuantitiesManager.onFetchedData = { [weak self] in
            self?.initVariableCellHeights()
        }

        baseQuantitiesManager.fetchFunc = fetchBaseQuantitiesFunc

        baseQuantitiesManager.reloadContainerData = { [weak self] in
            self?.tableView.reloadData()
        }
    }

    func setUnitsNotificationToken(token: NotificationToken) {
        unitsManager.notificationToken = token
    }

    func setFirstBaseQuantitiesNotificationToken(token: NotificationToken) {
        baseQuantitiesManager.notificationToken = token
    }

    func setSecondBaseQuantitiesNotificationToken(token: NotificationToken) {
        secondBaseQuantitiesManager.notificationToken = token
    }

    // Realm notifications entry point
    func updateUnits(insertions: [Int], deletions: [Int], modifications: [Int]) {
        unitsManager.update(insertions: insertions, deletions: deletions, modifications: modifications)
    }

    // Realm notifications entry point
    func updateBaseQuantities(insertions: [Int], deletions: [Int], modifications: [Int]) {
        baseQuantitiesManager.update(insertions: insertions, deletions: deletions, modifications: modifications)
    }

    // Realm notifications entry point
    func updateSecondBaseQuantities(insertions: [Int], deletions: [Int], modifications: [Int]) {
        secondBaseQuantitiesManager.update(insertions: insertions, deletions: deletions, modifications: modifications)
    }

    fileprivate func configSecondBaseQuantitiesManager() {
        secondBaseQuantitiesManager.configure(controller: self, canDeselect: true, onSelectItem: { [weak self] baseQuantity in
            self?.inputs.secondBaseQuantityMarkedToDelete = nil // clear possible marked to delete unit
            self?.inputs.secondBaseQuantity = baseQuantity?.val
            self?.inputs.secondBaseQuantityName = baseQuantity?.uniqueName
        })

        secondBaseQuantitiesManager.onMarkedItemToDelete = { [weak self] base in
            self?.inputs.secondBaseQuantityMarkedToDelete = base
            //            if let unit = unit {
            //                self?.unitsManager.markUnitToDelete(unit: unit)
            //            }
        }
        secondBaseQuantitiesManager.itemMarkedToDelete = { [weak self] in
            return self?.inputs.secondBaseQuantityMarkedToDelete
        }
        // for now clear variables BEFORE of realm delete - reason: clear possible selected unit - we have to compare with deleted unit to see if it's the same, and this crashes if it is, because after realm delete the object is invalid.
        // TODO possible solution: Don't retain any Realm objects here, only ids.
        secondBaseQuantitiesManager.willDeleteItem = { [weak self] base in
            self?.inputs.secondBaseQuantityMarkedToDelete = nil
            if base.val.quantityString == self?.inputs.secondBaseQuantityName {
                self?.inputs.baseQuantity = nil
                self?.inputs.secondBaseQuantityName = nil
            }
        }

        secondBaseQuantitiesManager.clearToDeleteItemsState = { [weak self] in
            self?.inputs.secondBaseQuantityMarkedToDelete = nil
        }

        secondBaseQuantitiesManager.selectedItem = { [weak self] in guard let weakSelf = self else { return nil }
            return weakSelf.inputs.hideSecondBaseQuantitySelected ? nil : weakSelf.inputs.secondBaseQuantityName
        }

        secondBaseQuantitiesManager.onFetchedData = { [weak self] in
            self?.initVariableCellHeights()
        }

        secondBaseQuantitiesManager.fetchFunc = fetchBaseQuantitiesFunc
    }

    fileprivate func submit() {
        // TODO ensure that there's always a unit and a base selected!
        guard let unitId = inputs.unitId else { logger.e("Can't submit without a unit"); return }
        guard let unitName = inputs.unitName else { logger.e("Can't submit without unit name"); return } // TODO remove name?
        guard let baseQuantity = inputs.baseQuantity else { logger.e("Can't submit without base"); return }

        // Text input overrides collection view selection
        let finalUnitId = inputs.textInputUnitId ?? unitId
        let finalUnitName = inputs.textInputUnitName ?? unitName
        let finalBaseQuantity = inputs.textInputBaseQuantity ?? baseQuantity
        let finalSecondBaseQuantity = inputs.textInputSecondBaseQuantity ?? inputs.secondBaseQuantity // optional

        // TODO why are we handling errors here with logger instead of the default handler (alert)?
        
        // Possible creation of unit/base quantity, if they were entered via text input
        Prov.unitProvider.getOrCreate(name: finalUnitName) { result in
            if !result.success {
                logger.e("Couldn't get/create unit: \(unitName)", .db)
            }
            Prov.unitProvider.getOrCreate(baseQuantity: finalBaseQuantity) { [weak self] result in
                if !result.success {
                    logger.e("Couldn't get/create base quantity: \(finalBaseQuantity)", .db)
                }

                func doSubmit(secondBaseQuantity: Float?) {
                    let result = SelectUnitAndBaseControllerResult(
                        unitId: unitId,
                        unitName: unitName,
                        baseQuantity: baseQuantity,
                        secondBaseQuantity: secondBaseQuantity
                    )
                    self?.onSubmit?(result)
                }

                if let secondBaseQuantity = finalSecondBaseQuantity {
                    Prov.unitProvider.getOrCreate(baseQuantity: secondBaseQuantity) { result in
                        if !result.success {
                            logger.e("Couldn't get/create second base quantity: \(secondBaseQuantity)", .db)
                        }
                        doSubmit(secondBaseQuantity: secondBaseQuantity)
                    }
                } else {
                    doSubmit(secondBaseQuantity: nil)
                }
            }
        }
    }

    fileprivate func initSubmitView() {
        let submitView = SubmitView()
        submitView.setButtonTitle(title: trans("update_base_unit_submit_button_title"))
        submitView.delegate = self
        view.addSubview(submitView)

        submitView.translatesAutoresizingMaskIntoConstraints = false
        _ = submitView.alignLeft(self.view)
        _ = submitView.alignRight(self.view)
        _ = submitView.alignBottom(self.view, constant: 0)
        _ = submitView.heightConstraint(Theme.submitViewHeight)
    }

    fileprivate func initHelpButton() {
        helpButtonImage.backgroundColor = UIColor.white
        helpButtonImage.layer.cornerRadius = helpButtonImage.width / 2
        helpButtonImage.tintColor = Theme.grey
        helpButtonImage.layer.borderColor = Theme.grey.cgColor
        helpButtonImage.layer.borderWidth = 3

        if !(PreferencesManager.loadPreference(.hasTappedOnUnitBaseHelp) ?? false) {
            UIView.animateKeyframes(withDuration: 2, delay: 1, options: [.`repeat`],
                                    animations: {
                                        UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3, animations: { [weak self] in
                                            self?.helpButtonImage.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                                        })
                                        UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.2, animations: { [weak self] in
                                            self?.helpButtonImage.transform = CGAffineTransform(scaleX: 1.15, y: 1.15).concatenating(CGAffineTransform(rotationAngle: 0.15))
                                        })
                                        UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.2, animations: { [weak self] in
                                            self?.helpButtonImage.transform = CGAffineTransform(scaleX: 1.15, y: 1.15).concatenating(CGAffineTransform(rotationAngle: -0.15))
                                        })
                                        UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3, animations: { [weak self] in
                                            self?.helpButtonImage.transform = CGAffineTransform.identity
                                        })
            }, completion: nil)
        }
    }

    // MARK: Keyboard Notifications

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            self.tableView.bottomInset = keyboardHeight
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.2, animations: {
            // For some reason adding inset in keyboardWillShow is animated by itself but removing is not, that's why we have to use animateWithDuration here
            self.tableView.bottomInset = Theme.submitViewHeight
        })
    }

    // MARK: Help

    @IBAction func onHelpTap(_ sender: UIButton) {
        let helpController = BaseUnitHelpViewController()
        helpController.view.frame = CGRect(x: 100, y: 10, width: 340, height: 520)
        helpController.view.layer.cornerRadius = Theme.popupCornerRadius
        helpController.view.clipsToBounds = true

        let popup = MyPopupHelper.showCustomPopupFrom(parent: self, centerYOffset: 0, contentController: helpController, swipeEnabled: false, useDefaultFrame: false, from: helpButtonImage)

        helpController.closeTapHandler = {
            helpController.removeFromParentViewController()
            popup.hide()
        }

        helpButtonImage.layer.removeAllAnimations()
        helpButtonImage.transform = CGAffineTransform.identity
        PreferencesManager.savePreference(PreferencesManagerKey.hasTappedOnUnitBaseHelp, value: true)
    }
}

extension SelectUnitAndBaseController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        func dequeueDefaultCell() -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.selectionStyle = .none
            cell.contentView.removeSubviews()
            return cell
        }

        switch indexPath.row {
        case unitsCollectionViewIndex:
            let cell = dequeueDefaultCell()
            let view = unitsManager.view
            view.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(view)
            view.frame = cell.contentView.bounds // appears to be necessary
            view.fillSuperview()
            return cell
        case basesCollectionViewIndex, secondBasesCollectionViewIndex:
            let cell = dequeueDefaultCell()
            let view = indexPath.row == basesCollectionViewIndex ? baseQuantitiesManager.view : secondBaseQuantitiesManager.view
            view.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(view)
            view.frame = cell.contentView.bounds // appears to be necessary
            view.fillSuperview()
            return cell
        case unitsHeaderIndex, basesHeaderIndex, secondBasesHeaderIndex: // headers
            let header = tableView.dequeueReusableCell(withIdentifier: "subHeaderCell", for: indexPath) as! IngredientDataSubHeaderCell
            header.title.text = {
                switch indexPath.row {
                case unitsHeaderIndex: return trans("select_ingredient_data_header_units")
                case basesHeaderIndex: return trans("select_unit_base_header_quantity")
                case secondBasesHeaderIndex: return trans("select_unit_base_header_second_quantity")
                default: fatalError("Forgot to handle index: \(indexPath.row)")
                }
            } ()
            return header
        case unitInputIndex: // unit input
            let itemInputCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as! AddNewItemInputCell
            itemInputCell.configure(placeholder: trans("enter_custom_unit_placeholder"), onlyNumbers: false, onInputUpdate: { [weak self] unitInput in
                self?.inputs.textInputUnitId = .custom
                self?.inputs.textInputUnitName = unitInput.isEmpty ? nil : unitInput
                self?.inputs.hideUnitSelected = !unitInput.isEmpty
                if !unitInput.isEmpty {
                    self?.unitsManager.clearSelectedItems() // Input overwrites possible selection
                    self?.unitsManager.clearToDeleteItems() // Clear delete state too
                } else {
                    self?.unitsManager.reload() // make last selection show
                }
            })
            return itemInputCell
        case basesInputIndex: // base input
            let itemInputCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as! AddNewItemInputCell
            itemInputCell.configure(placeholder: trans("enter_custom_base_quantity_placeholder"), onlyNumbers: true, onInputUpdate: { [weak self] baseInput in
                self?.inputs.textInputBaseQuantityName = baseInput.isEmpty ? nil : baseInput
                self?.inputs.textInputBaseQuantity = baseInput.isEmpty ? nil : baseInput.floatValue
                self?.inputs.hideBaseQuantitySelected = !baseInput.isEmpty
                if !baseInput.isEmpty {
                    self?.baseQuantitiesManager.clearSelectedItems() // Input overwrites possible selection
                    self?.baseQuantitiesManager.clearToDeleteItems() // Clear delete state too
                } else {
                    self?.baseQuantitiesManager.reload() // make last selection show
                }
            })
            return itemInputCell
        case secondBasesInputIndex: // second base input
            let itemInputCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as! AddNewItemInputCell
            itemInputCell.configure(placeholder: trans("enter_custom_base_quantity_placeholder"), onlyNumbers: true, onInputUpdate: { [weak self] baseInput in
                self?.inputs.textInputSecondBaseQuantityName = baseInput.isEmpty ? nil : baseInput
                self?.inputs.textInputSecondBaseQuantity = baseInput.isEmpty ? nil : baseInput.floatValue
                self?.inputs.hideSecondBaseQuantitySelected = !baseInput.isEmpty
                if !baseInput.isEmpty {
                    self?.secondBaseQuantitiesManager.clearSelectedItems() // Input overwrites possible selection
                    self?.secondBaseQuantitiesManager.clearToDeleteItems() // Clear delete state too
                } else {
                    self?.secondBaseQuantitiesManager.reload() // make last selection show
                }
            })
            return itemInputCell
        default: fatalError("Not supported index: \(indexPath.row)")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case unitsCollectionViewIndex: return unitsViewHeight ?? 600 // dummy big default size, with 0 constraint errors in console (at the beginning the collection collection view has no width)
        case basesCollectionViewIndex, secondBasesCollectionViewIndex: return baseQuantitiesViewHeight ?? 600
        case unitsHeaderIndex, basesHeaderIndex, secondBasesHeaderIndex: return 50 // header
        case unitInputIndex, basesInputIndex, secondBasesInputIndex: return 80 // text inputs
        default: fatalError("Not supported index: \(indexPath.row)")
        }
    }
}

extension SelectUnitAndBaseController: SubmitViewDelegate {

    func onSubmitButton() {
        submit()
    }
}
