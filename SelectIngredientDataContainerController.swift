//
//  SelectIngredientDataContainerController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 25/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs

protocol SelectIngredientDataContainerControllerDelegate {
    func onSelectIngrentTapOutsideOfContent()
    func parentViewForSelectIngredientControllerAddButton() -> UIView?
    func onSubmitIngredientInputs(item: Item, inputs: SelectIngredientDataControllerInputs)
    func submitButtonBottomOffset(parent: UIView, buttonHeight: CGFloat) -> CGFloat // TODO improve this
}

class SelectIngredientDataContainerController: UIViewController, SelectUnitControllerDelegate, QuantityViewDelegate, SelectIngredientFractionControllerDelegate, SubmitViewDelegate {
    
    @IBOutlet weak var wholeNumberLabel: UILabel!
    @IBOutlet weak var fractionLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var wholeNumberTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var fractionTrailingConstraint: NSLayoutConstraint!
    
    fileprivate var titleLabelsFont: UIFont?

    @IBOutlet weak var tableView: TableViewHitTest!
    
    
    var item: Item?
    
    var inputs: SelectIngredientDataControllerInputs = SelectIngredientDataControllerInputs()
    fileprivate var currentUnit: Providers.Unit? // TODO merge this with inputs?
    
    fileprivate func updateRowsForUnit(_ unit: Providers.Unit) {
        let unitsWithFraction: [UnitId] = [.liter, .teaspoon, .spoon, .cup, .ounce]
        
        if unitsWithFraction.contains(unit.id) {
            if expandedSteps == 2 {
                expandedSteps = 3
                tableView.insertRows(at: [IndexPath(row: 2, section: 0)], with: Theme.defaultRowAnimation)
            }
        } else {
            if expandedSteps == 3 {
                expandedSteps = 2
                tableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: Theme.defaultRowAnimation)
            }
        }
    }
    
    var selectUnitController: SelectIngredientUnitController?
    var selectQuantityController: SelectIngredientQuantityController?
    var selectFractionController: SelectIngredientFractionController?

    var delegate: SelectIngredientDataContainerControllerDelegate?
    
    fileprivate var selectedUnitFirstTime = false
    
    fileprivate var expandedSteps = 1
    
    fileprivate var submitView: SubmitView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableViewHitTest()
        
        tableView.allowsSelection = false
        
        titleLabelsFont = itemNameLabel.font // NOTE: Assumes that all labels in title have same font
        
        initSubmitButton()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTableViewTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObserver()
    }
    
    func onTableViewTap(_ sender: UITapGestureRecognizer) {
        UIApplication.shared.delegate!.window??.endEditing(true)
    }
    
    func configForEditMode(ingredient: Ingredient) {
        fill(ingredient: ingredient)
        updateStepsAfterSelectingUnitIfConditions(unit: ingredient.unit, scrollToQuantityRow: false)
    }
    
    // for edit case
    func fill(ingredient: Ingredient) {
        self.currentUnit = ingredient.unit
        selectUnitController?.selectUnit(unit: ingredient.unit)
        
        selectQuantityController?.quantityView.quantity = ingredient.quantity
        
        selectFractionController?.config(fraction: ingredient.fraction)
    }
    
    fileprivate func initSubmitButton() {
        guard self.submitView == nil else {QL1("Already showing a submit view"); return}
        guard let delegate = delegate else {QL1("No delegate"); return}
//        guard let parentViewForAddButton = delegate?.parentViewForAddButton() else {QL4("No delegate: \(delegate)"); return}
        guard let parentViewForAddButton = view else {QL4("No delegate: \(delegate)"); return}
        
        let height = Theme.submitViewHeight
        let submitView = SubmitView(frame: CGRect(x: 0, y: parentViewForAddButton.frame.maxY - height, width: parentViewForAddButton.width, height: height))
        submitView.delegate = self
        submitView.setButtonTitle(title: "select_ingredient_data_submit")
        parentViewForAddButton.addSubview(submitView)

        submitView.translatesAutoresizingMaskIntoConstraints = false
        
        _ = submitView.alignLeft(parentViewForAddButton)
        _ = submitView.alignRight(parentViewForAddButton)
        _ = submitView.alignBottom(parentViewForAddButton, constant: Float(delegate.submitButtonBottomOffset(parent: parentViewForAddButton, buttonHeight: height)))
        _ = submitView.heightConstraint(height)
        
        self.submitView = submitView
    }
    
    fileprivate func initTableViewHitTest() {
        // There doesn't seem to be a (good) way to perform hit test on the controller's view so we observe the hit test of the table view and pass this to delegate
        // The reason we work with hit test, is that it seems better to set a fixed height to the table view and control the content only via row insertion rather than row insertion + animating the height of the controller at the same time (can't say for sure though as the later wan't tried out).
        tableView.onHit = {[weak self] inCell in
            if !inCell {
                self?.delegate?.onSelectIngrentTapOutsideOfContent()
            }
        }
    }
    

    fileprivate func generateUnitController() -> SelectIngredientUnitController {
        guard self.selectUnitController == nil else {return self.selectUnitController!}
        
        let selectUnitController = UIStoryboard.selectIngredientUnitController()
        
        selectUnitController.delegate = self
        
        self.selectUnitController = selectUnitController
        
        return selectUnitController
    }
    
    fileprivate func generateQuantityController() -> SelectIngredientQuantityController {
        guard self.selectQuantityController == nil else {return self.selectQuantityController!}
        
        let selectQuantityController = SelectIngredientQuantityController()
        selectQuantityController.onUIReady = {[weak selectQuantityController] in
            selectQuantityController?.quantityView.delegate = self
        }

        self.selectQuantityController = selectQuantityController
        
        return selectQuantityController
    }

    fileprivate func generateFractionController() -> SelectIngredientFractionController {
        guard self.selectFractionController == nil else {return self.selectFractionController!}
        
        let selectFractionController = SelectIngredientFractionController()
        
        selectFractionController.delegate = self
        
        self.selectFractionController = selectFractionController
        selectFractionController.onUIReady = {[weak selectFractionController, weak self] in
            selectFractionController?.unit = self?.currentUnit
        }
        
        return selectFractionController
    }

    
    // MARK: - SelectUnitControllerDelegate
    
    func onSelectUnit(unit: Providers.Unit) {
        
        self.currentUnit = unit
        inputs.unitName = unit.name
        updateTitle(inputs: inputs)
        selectFractionController?.unit = unit
        
        updateStepsAfterSelectingUnitIfConditions(unit: unit, scrollToQuantityRow: true)
    }
    
    fileprivate func updateStepsAfterSelectingUnitIfConditions(unit: Providers.Unit, scrollToQuantityRow: Bool) {
        
        if !selectedUnitFirstTime {
            selectedUnitFirstTime = true
        
            expandedSteps = 2
            let quantityRowIndexPath = IndexPath(row: 1, section: 0)
            tableView.insertRows(at: [quantityRowIndexPath], with: .top)
            
            delay(0.3) {[weak self] in
                self?.updateRowsForUnit(unit)
                
                if scrollToQuantityRow {
                    self?.tableView.scrollToRow(at: quantityRowIndexPath, at: .top, animated: true)
                }
            }
            
        } else {
            updateRowsForUnit(unit)
        }
    }
    
    // MARK: - QuantityViewDelegate
    
    func onRequestUpdateQuantity(_ delta: Float) {
        inputs.quantity = inputs.quantity + delta
        selectQuantityController?.quantityView.quantity = inputs.quantity
        updateTitle(inputs: inputs)
    }
    
    // MARK: - SelectIngredientFractionControllerDelegate
    
    func onSelectFraction(fraction: Fraction?) {
        inputs.fraction = fraction ?? Fraction.one
        updateTitle(inputs: inputs)
    }
    
    // MARK: - SubmitViewDelegate
    
    func onSubmitButton() {
        submit()
    }
    
    
    // MARK: -
    
    fileprivate func updateTitle(inputs: SelectIngredientDataControllerInputs) {
        guard let titleLabelsFont = titleLabelsFont else {QL4("No title labels font. Can't update title."); return}
        
        let fractionStr = inputs.fraction.isValidAndNotZeroOrOneByOne ? inputs.fraction.description : ""
        // Don't show quantity if it's 0 and there's a fraction. If there's no fraction we show quantity 0, because otherwise there wouldn't be any number and this doesn't make sense.
        let wholeNumberStr = inputs.quantity == 0 ? (fractionStr.isEmpty ? inputs.quantity.quantityString : "") : "\(inputs.quantity.quantityString)"
        let unitStr = inputs.unitName.isEmpty ? "unit" : inputs.unitName
        
        let boldTime: Double = 1
        
        if fractionLabel.text != fractionStr {
            fractionLabel.animateBold(boldTime, regularFont: titleLabelsFont)
        }
        if wholeNumberLabel.text != wholeNumberStr {
            wholeNumberLabel.animateBold(boldTime, regularFont: titleLabelsFont)
        }
        if unitLabel.text != unitStr {
            unitLabel.animateBold(boldTime, regularFont: titleLabelsFont)
        }
        
        fractionLabel.text = fractionStr
        wholeNumberLabel.text = wholeNumberStr
        unitLabel.text = unitStr
        
        wholeNumberTrailingConstraint.constant = wholeNumberStr.isEmpty || fractionStr.isEmpty ? 0 : 10
        fractionTrailingConstraint.constant = wholeNumberStr.isEmpty && fractionStr.isEmpty ? 0 : 10
    }
    
    fileprivate func submit() {
        guard let item = item else {QL4("Illegal state: no item. Can't submit"); return}
        
        delegate?.onSubmitIngredientInputs(item: item, inputs: inputs)
    }
    
    // MARK: - Keyboard
    
    func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func removeKeyboardObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func keyboardWillChangeFrame(_ notification: Foundation.Notification) {
        if let userInfo = (notification as NSNotification).userInfo {
            if let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

                let offset = frame.height - (tabBarController?.tabBar.height ?? 0)
                tableView.bottomInset = offset
                tableView.contentOffset = CGPoint(x: 0, y: tableView.contentOffset.y + offset)
                
            } else {
                QL3("Couldn't retrieve keyboard size from user info")
            }
        } else {
            QL3("Notification has no user info")
        }
    }
    
    func keyboardWillDisappear(_ notification: Foundation.Notification) {
        tableView.bottomInset = 0
    }
}


extension SelectIngredientDataContainerController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expandedSteps
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        func addController(_ controller: UIViewController, isFirst: Bool = false) {
            cell.contentView.addSubview(controller.view)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            controller.view.fillSuperview()
            addChildViewController(controller)
            
            if !isFirst {
                controller.view.alpha = 0
                anim(0.5) {
                    controller.view.alpha = 1
                }
            }
        }
        
        switch indexPath.row {
        case 0:
            let controller = generateUnitController()
            addController(controller, isFirst: true)
            controller.view.backgroundColor = Theme.lightGreyBackground
        case 1:
            let controller = generateQuantityController()
            addController(controller)
            controller.view.backgroundColor = Theme.lightGreyBackground
        default:
            let controller = generateFractionController()
            addController(controller)
            controller.view.backgroundColor = Theme.lightGreyBackground
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0: return DimensionsManager.quickAddHeight + 20
        case 1: return 100
        default: return 500
        }
    }
}
