//
//  SelectIngredientDataController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 09/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs
import RealmSwift

struct SelectIngredientDataControllerInputs {
    var unitName: String = ""
    var quantity: Float = 1
    var fraction: Fraction = Fraction(wholeNumber: 0, numerator: 1, denominator: 1)
}

protocol SelectIngredientDataControllerDelegate: class {

    func parentViewForAddButton() -> UIView?
    func onSubmitIngredientInputs(item: Item, inputs: SelectIngredientDataControllerInputs)
}

class SelectIngredientDataController: UIViewController, QuantityViewDelegate, SwipeToIncrementHelperDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var wholeNumberLabel: UILabel!
    @IBOutlet weak var fractionLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var wholeNumberTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var fractionTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var quantityView: QuantityView!
    @IBOutlet weak var quantityBackgroundView: UIView!
    
    @IBOutlet weak var unitTextField: MyAutoCompleteTextField!

    @IBOutlet weak var fractionsCollectionView: UICollectionView!
    
    fileprivate var inputs: SelectIngredientDataControllerInputs = SelectIngredientDataControllerInputs()
    
    
    fileprivate var titleLabelsFont: UIFont?

    
    fileprivate var addButtonHelper: AddButtonHelper?
    
    weak var delegate: SelectIngredientDataControllerDelegate?

    fileprivate var currentNewFractionInput: Fraction?
    
    var item: Item? {
        didSet {
            if let item = item {
                itemNameLabel.text = item.name // TODO string should be "2/1/2 units Onions" etc
            }
        }
    }
    
    fileprivate var units: Results<Providers.Unit>?
    fileprivate var unitNames: [String] = [] // we need this because we can't touch the Realm Units in the autocompletions thread (get diff. thread exception). So we have to map to Strings in advance.
    
    var quantity: Float {
        return quantityView.quantity
    }
    
    
    var onViewDidLoad: (() -> Void)?
    
    fileprivate var swipeToIncrementHelper: SwipeToIncrementHelper?
    
    fileprivate var fractions: RealmSwift.List<DBFraction>? {
        didSet {
            fractionsCollectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onViewDidLoad?()
        
        quantityView.delegate = self
        quantityView.quantity = 1
        
        swipeToIncrementHelper = SwipeToIncrementHelper(view: quantityBackgroundView)
        swipeToIncrementHelper?.delegate = self
        
        initTextFieldPlaceholders()
        initAutocompletionTextFields()
        initTextListeners()
        
        titleLabelsFont = itemNameLabel.font // NOTE: Assumes that all labels in title have same font
        
        addButtonHelper = initAddButtonHelper()
        
        loadUnits()
        loadFractions()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        view.addGestureRecognizer(tap)
        
        if let flow = fractionsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.estimatedItemSize = CGSize(width: 100, height: 50)
        } else {
            QL4("No flow layout")
        }
    }
    
    func loadFractions() {
        Prov.fractionProvider.fractions(successHandler {fractions in
            self.fractions = fractions
        })
    }
    
    func onTap(_ sender: UIView) {
        guard let fractions = fractions else {QL4("No fractions"); return}
        
        if let currentNewFractionInput = currentNewFractionInput {
            
            let dbFraction = DBFraction(numerator: currentNewFractionInput.numerator, denominator: currentNewFractionInput.denominator)
            Prov.fractionProvider.add(fraction: dbFraction, successHandler {[weak self] isNew in guard let weakSelf = self else {return}
                
                if isNew {
                    weakSelf.fractionsCollectionView.insertItems(at: [IndexPath(row: fractions.count - 1, section: 0)])
                    if let editCell = weakSelf.fractionsCollectionView.cellForItem(at: IndexPath(row: fractions.count, section: 0)) as? EditableFractionCell {
                        editCell.editableFractionView.clear()
                    }
                }
            })
        }
    }
    
    fileprivate func loadUnits() {
        Prov.unitProvider.units(successHandler{[weak self] units in
            self?.units = units
            self?.unitNames = units.map{$0.name} // see comment on var why this is necessary
        })
    }
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentViewForAddButton = delegate?.parentViewForAddButton() else {QL4("No delegate: \(delegate)"); return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentViewForAddButton) {[weak self] in guard let weakSelf = self else {return}
            weakSelf.submit()
        }
        return addButtonHelper
    }

    fileprivate func initTextListeners() {
        for textField in [unitTextField] {
            textField?.addTarget(self, action: #selector(onTextChange(_:)), for: .editingChanged)
        }
    }
    
    fileprivate func initAutocompletionTextFields() {
        for textField in [unitTextField] {
            textField?.defaultAutocompleteStyle()
            textField?.myDelegate = self
        }
    }
    
    fileprivate func initTextFieldPlaceholders() {
        unitTextField.attributedPlaceholder = NSAttributedString(string: unitTextField.placeholder ?? "", attributes: [NSForegroundColorAttributeName: UIColor.gray])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addButtonHelper?.addObserver()
        addButtonHelper?.animateVisible(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
        addButtonHelper?.animateVisible(false)
    }
    
    
    func onTextChange(_ sender: UITextField) {
        updateInputsAndTitle()
    }

    func onRequestUpdateQuantity(_ delta: Float) {
        quantityView.quantity += delta
        updateTitle(inputs: inputs)
    }
    
    // MARK: - SwipeToIncrementHelperDelegate
    
    func currentQuantity() -> Float {
        return quantity
    }
    
    func onQuantityUpdated(_ quantity: Float) {
        quantityView.quantity = quantity
        updateTitle(inputs: inputs)
    }
    
    func onFinishSwipe() {
        // do nothing
    }
    
    
    // MARK: - Private
    
    fileprivate func updateInputsAndTitle() {
//        inputs.unitName = unitTextField.text ?? ""
        inputs.quantity = quantity

        updateTitle(inputs: inputs)
    }
    
    fileprivate func updateTitle(inputs: SelectIngredientDataControllerInputs) {
        guard let titleLabelsFont = titleLabelsFont else {QL4("No title labels font. Can't update title."); return}
        
        let fractionStr = inputs.fraction.isValidAndNotZeroOrOne ? inputs.fraction.description : ""
        // Don't show quantity if it's 0 and there's a fraction. If there's no fraction we show quantity 0, because otherwise there wouldn't be any number and this doesn't make sense.
        let wholeNumberStr = quantity == 0 ? (fractionStr.isEmpty ? quantity.quantityString : "") : quantity.quantityString
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
    
    // TODO validation - don't allow e.g. to add item with 0 quantity
    
    fileprivate func onSelect(fraction: DBFraction) {
        updateInputsAndTitle()
    }
    
    fileprivate func submit() {
        guard let item = item else {QL4("Illegal state: no item. Can't submit"); return}
        
        delegate?.onSubmitIngredientInputs(item: item, inputs: inputs)
    }
}


extension SelectIngredientDataController: MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate, MyAutoCompleteTextFieldDelegate {
    
    // MARK: - MLPAutoCompleteTextFieldDataSource
    
    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, possibleCompletionsFor string: String!, completionHandler handler: @escaping (([Any]?) -> Void)) {
        switch textField {
        case unitTextField:
            guard let text = unitTextField.text else {handler([]); return}
            
            handler(unitNames.filter{$0.contains(text)})

        case _:
            QL4("Not handled text field in autoCompleteTextField")
            break
        }
    }
    
    
    // MARK: - MyAutoCompleteTextFieldDelegate
    
    func onDeleteSuggestion(_ string: String, sender: MyAutoCompleteTextField) {
        switch sender {

        case unitTextField:
            guard let unitText = unitTextField.text else {return}
            
            ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("popup_remove_unit_completion_confirm"), okTitle: trans("popup_button_yes"), cancelTitle: trans("popup_button_no"), controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
                Prov.unitProvider.delete(name: unitText, weakSelf.successHandler {
                    AlertPopup.show(message: trans("popup_was_removed", unitText), controller: weakSelf)
                })
            })

        default: QL4("Not handled input")
        }
    }
}

extension SelectIngredientDataController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, EditableFractionViewDelegate {
    
    // TODO!!!!!!!!!!!!!!!!!!!!! on select suggestion the top label should also be updated. doesn't seem to be the case currently
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fractions.map{$0.count + 1} ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let fractions = fractions else {QL4("No fractions"); return UICollectionViewCell()}
        
        if indexPath.row < fractions.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FractionCell
            cell.fractionView.fraction = fractions[indexPath.row]
            cell.fractionView.backgroundColor = UIColor.white
            cell.fractionView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "editableCell", for: indexPath) as! EditableFractionCell
            cell.editableFractionView.backgroundColor = UIColor.white
            cell.editableFractionView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
            cell.editableFractionView.delegate = self
            cell.editableFractionView.prefill(fraction: currentNewFractionInput)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let fractions = fractions else {QL4("No fractions"); return}

        onSelect(fraction: fractions[indexPath.row])
    }

    func onFractionInputChange(fractionInput: Fraction?) {
        currentNewFractionInput = fractionInput
    }
}
