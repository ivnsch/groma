//
//  IngredientDataController.swift
//  groma
//
//  Created by Ivan Schuetz on 16.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

struct IngredientDataControllerResult {
    let unitName: String
    let whole: Int
    let fraction: Fraction?
}

fileprivate struct IngredientDataControllerInputs {
    var unit: Providers.Unit? // TODO use only the name?
    var newUnitInput: String?
    var whole: Int?
    var fraction: Fraction?
    var unitMarkedToDelete: String? // name (assumed to be unique)
}

class IngredientDataController: UITableViewController, SubmitViewDelegate {

    static let defaultQuantity = 1
    static let defaultFraction = Fraction.zero
    static let defaultUnitName = "unit"

    weak var controller: UIViewController?

    fileprivate var unitsManager = UnitCollectionViewManager()

    fileprivate var quantityView: IngredientQuantityView!

    fileprivate var submitView: SubmitView?

    var cellCount = 0

    var productName: String = ""

    fileprivate var unitsViewHeight: CGFloat?

    fileprivate var inputs = IngredientDataControllerInputs() {
        didSet {
            updateHeader(inputs: inputs)
        }
    }

    var onSubmitInputs: ((IngredientDataControllerResult) -> Void)?
    var submitButtonParent: (() -> UIView?)?
    var onDidScroll: ((UIScrollView) -> Void)?

    // Optional config, e.g. for edit
    func config(productName: String, unit: Providers.Unit, whole: Int, fraction: Fraction) {
        self.productName = productName
        inputs.unit = unit
        inputs.whole = whole
        inputs.fraction = fraction
        unitsManager.reload()
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
        tableView.bottomInset = Theme.submitViewHeight

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(UINib(nibName: "IngredientDataSubHeaderCell", bundle: nil), forCellReuseIdentifier: "subHeaderCell")
        tableView.register(UINib(nibName: "AddNewItemInputCell", bundle: nil), forCellReuseIdentifier: "unitInputCell")

        tableView.keyboardDismissMode = .onDrag

        unitsManager.configure(controller: self, onSelectItem: { [weak self] unit in
            self?.inputs.unitMarkedToDelete = nil // clear possible marked to delete unit
            self?.inputs.unit = unit
            delay(0.2) { [weak self] in // make it less abrubt
                self?.tableView.scrollTo(row: 2)
            }
        })

        unitsManager.onMarkedItemToDelete = { [weak self] uniqueName in
            self?.inputs.unitMarkedToDelete = nil // clear possible marked to delete unit
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
            if unit.name == self?.inputs.unit?.name {
                self?.inputs.unit = nil
            }
        }

        unitsManager.clearToDeleteItemsState = { [weak self] in
            self?.inputs.unitMarkedToDelete = nil
        }

        unitsManager.selectedItem = { [weak self] in
            return self?.inputs.unit?.name
        }

        initQuantityView()

        cellCount = 5

        unitsManager.loadItems()
        
        reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        initVariableCellHeights()
        initSubmitButton()

        tableView.reloadData()
    }

    fileprivate func initVariableCellHeights() {
        unitsViewHeight = unitsManager.collectionViewContentHeight()
        tableView.reloadData()
    }

    fileprivate func initQuantityView() {
        quantityView = IngredientQuantityView.createView()
        quantityView.onQuantityChanged = { [weak self] whole, fraction in
            self?.inputs.whole = whole
            self?.inputs.fraction = fraction
        }
    }

    fileprivate func updateHeader(inputs: IngredientDataControllerInputs) {
        guard let header = tableView.headerView(forSection: 0) as? SelectIngredientDataHeader else {
            logger.e("No header or couldn't be casted", .ui)
            return
        }
        header.update(inputs: generateHeaderInputs())
    }

    fileprivate func generateHeaderInputs() -> SelectIngredientDataHeaderInputs {
        return SelectIngredientDataHeaderInputs(
            productName: productName,
            unitName: inputs.unit?.name ?? IngredientDataController.defaultUnitName,
            quantity: inputs.whole.map { Float($0) } ?? Float(IngredientDataController.defaultQuantity),
            fraction: inputs.fraction ?? IngredientDataController.defaultFraction
        )
    }

    // MARK: Table view

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = SelectIngredientDataHeader.createView()
        header.update(inputs: generateHeaderInputs())
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        func dequeueDefaultCell() -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.selectionStyle = .none
            cell.contentView.removeSubviews()
            return cell
        }

        switch indexPath.row {
        case 1:
            let cell = dequeueDefaultCell()
            let view = unitsManager.view
            cell.contentView.addSubview(view)
            view.frame = cell.contentView.bounds // appears to be necessary
            view.fillSuperview()
            return cell
        case 0, 3:
            let header = tableView.dequeueReusableCell(withIdentifier: "subHeaderCell", for: indexPath) as! IngredientDataSubHeaderCell
            header.title.text = indexPath.row == 0 ? trans("select_ingredient_data_header_units") : trans("select_ingredient_data_header_quantity")
            return header
        case 2:
            let unitInputCell = tableView.dequeueReusableCell(withIdentifier: "unitInputCell", for: indexPath) as! AddNewItemInputCell
            unitInputCell.configure(placeholder: trans("enter_custom_unit_placeholder"), onlyNumbers: false, onInputUpdate: { [weak self] unitInput in
                self?.inputs.newUnitInput = unitInput.isEmpty ? nil : unitInput
                if !unitInput.isEmpty {
                    self?.inputs.unit = nil
                    self?.unitsManager.clearSelectedItems() // Input overwrites possible selection
                    self?.unitsManager.clearToDeleteItems() // Clear delete state too
                }
            })
            return unitInputCell
        case 4:
            let cell = dequeueDefaultCell()
            cell.contentView.addSubview(quantityView)
            quantityView.frame = cell.contentView.bounds // appears to be necessary
            quantityView.fillSuperview()

            let moundUnit = inputs.unit?.id ?? .none
            let whole = inputs.whole ?? IngredientDataController.defaultQuantity
            let fraction = inputs.fraction ?? IngredientDataController.defaultFraction
            quantityView.configure(unitId: moundUnit, whole: whole, fraction: fraction)
            
            return cell
        default: fatalError("Not supported index: \(indexPath.row)")
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 1: return  unitsViewHeight ?? 600 // dummy big default size, with 0 constraint errors in console (at the beginning the collection collection view has no width)
        case 0, 3: return 50
        case 2: return 80
        case 4: return 300
        default: fatalError("Not supported index: \(indexPath.row)")
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onDidScroll?(scrollView)
    }

    // MARK: Submit buttom

    fileprivate func initSubmitButton() {
        // Some places where we show this already have a submit button, so we don't add a submit button here.
        guard let submitButtonParent = submitButtonParent else { logger.d("No function to get parent"); return }

        guard self.submitView == nil else {logger.v("Already showing a submit view"); return}
        //        guard let parentViewForAddButton = delegate?.parentViewForAddButton() else {logger.e("No delegate: \(delegate)"); return}
        guard let parent = submitButtonParent() else {logger.e("Function didn't return parent!"); return}

        let height = Theme.submitViewHeight
        let submitView = SubmitView(frame: CGRect(x: 0, y: parent.frame.maxY - height, width: parent.width, height: height))
        submitView.delegate = self
        submitView.setButtonTitle(title: trans("select_ingredient_data_submit"))
        parent.addSubview(submitView)

        submitView.translatesAutoresizingMaskIntoConstraints = false

//        let tabbarHeight: CGFloat = self.parent?.tabBarController?.tabBar.size.height ?? {
//            logger.e("Couldn't get tabbar. Parent: \(parent)", .ui)
//            return 49 // Default to non-iPhoneX tabbar height, though this shouldn't happen
//        } ()

        _ = submitView.alignLeft(parent)
        _ = submitView.alignRight(parent)
        let bottomConstraint = submitView.alignBottom(parent, constant: 0)
        _ = submitView.heightConstraint(height)

        self.submitView = submitView

        // anchor with center translation doesn't work because autolayout, and transform doesn't work because we have to
        // scale, so using the bottom constraint instead
        func setAnchorWithoutMovingWithBottomConstraint(view: UIView, anchor: CGPoint) -> CGPoint {
            let offsetAnchor = CGPoint(x: anchor.x - view.layer.anchorPoint.x, y: anchor.y - view.layer.anchorPoint.y)
            let offset = CGPoint(x: view.frame.width * offsetAnchor.x, y: view.frame.height * offsetAnchor.y)
            view.layer.anchorPoint = anchor
            bottomConstraint.constant = offset.y
            return offset
        }

        _ = setAnchorWithoutMovingWithBottomConstraint(view: submitView, anchor: CGPoint(x: submitView.layer.anchorPoint.x, y: 1))
        submitView.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 0.00001)
        delay(0.5) {
            parent.bringSubview(toFront: submitView)
            UIView.animate(withDuration: Theme.defaultAnimDuration) {
                submitView.transform = CGAffineTransform.identity
            }
        }
    }

    func removeSubmitButton(onFinish: @escaping () -> Void) {
        UIView.animate(withDuration: Theme.defaultAnimDuration, animations: { [weak self] in
            self?.submitView?.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 0.00001)
        }, completion: { [weak self] onFinished in
            self?.submitView?.removeFromSuperview()
            onFinish()
        })
    }

    // MARK: - SubmitViewDelegate

    func onSubmitButton() {
        submit()
    }

    func getResult() -> IngredientDataControllerResult {
        return IngredientDataControllerResult(
            unitName: inputs.newUnitInput ?? inputs.unit?.name ?? IngredientDataController.defaultUnitName,
            whole: inputs.whole ?? IngredientDataController.defaultQuantity,
            fraction: inputs.fraction
        )
    }

    fileprivate func submit() {
        guard let onSubmitInputs = onSubmitInputs else { logger.e("No submit callback"); return }
        onSubmitInputs(getResult())
    }
}
