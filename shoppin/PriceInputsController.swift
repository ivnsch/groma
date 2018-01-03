//
//  PriceInputsController.swift
//  groma
//
//  Created by Ivan Schuetz on 03.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

struct PriceInputsState {
    var quantity: Float
    var secondQuantity: Float?
    var price: Float
}

class PriceInputsController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var multiplySignLabel: UILabel!
    @IBOutlet weak var secondQuantityTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var unitLabel: UILabel!

    @IBOutlet weak var multiplySignWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondBaseWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondBaseToMultiplySignConstraint: NSLayoutConstraint!
    @IBOutlet weak var multiplySignToBaseConstraint: NSLayoutConstraint!

    var onPriceChange: ((Float) -> Void)?
    var onQuantityChange: ((Float) -> Void)?
    var onSecondQuantityChange: ((Float) -> Void)?

    func prefill(quantity: Float, secondQuantity: Float?, price: Float, unitName: String) {
        quantityTextField.text = quantity.quantityString
        secondQuantityTextField.text = secondQuantity?.quantityString
        priceTextField.text = price.toLocalCurrencyString()
        updateUnitName(unitName: unitName)

        if secondQuantity == nil {
            multiplySignLabel.text = ""
            multiplySignWidthConstraint.constant = 0
            secondBaseWidthConstraint.constant = 0
            secondBaseToMultiplySignConstraint.constant = 0
            multiplySignToBaseConstraint.constant = 0
        } else {
            multiplySignLabel.text = "x"
            multiplySignWidthConstraint.constant = 8
            secondBaseWidthConstraint.constant = 50
            secondBaseToMultiplySignConstraint.constant = 8
            multiplySignToBaseConstraint.constant = 8
        }
    }

    func updateUnitName(unitName: String) {
        unitLabel.text = unitName
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initStaticText()

        quantityTextField.delegate = self
        secondQuantityTextField.delegate = self
        priceTextField.delegate = self

        quantityTextField.addTarget(self, action: #selector(quantityTextFieldDidChange(_:)), for: .editingChanged)
        secondQuantityTextField.addTarget(self, action: #selector(quantityTextFieldDidChange(_:)), for: .editingChanged)
        priceTextField.addTarget(self, action: #selector(priceTextFieldDidChange(_:)), for: .editingChanged)
    }

    func initStaticText() {
        priceTextField.setPlaceholderWithColor(trans("placeholder_price_inputs_price"), color: UIColor.white)
        quantityTextField.setPlaceholderWithColor(trans("placeholder_price_inputs_quantity"), color: UIColor.white)
        secondQuantityTextField.setPlaceholderWithColor(trans("placeholder_price_inputs_quantity"), color: UIColor.white)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == priceTextField || textField == quantityTextField || textField == secondQuantityTextField {
            textField.selectAll(nil)
        }
    }

    @objc func quantityTextFieldDidChange(_ sender: UITextField) {
        onQuantityChange?(sender.text?.floatValue ?? 0)
        sender.invalidateIntrinsicContentSize()
    }

    @objc func secondQuantityTextFieldDidChange(_ sender: UITextField) {
        onSecondQuantityChange?(sender.text?.floatValue ?? 0)
        sender.invalidateIntrinsicContentSize()
    }

    @objc func priceTextFieldDidChange(_ sender: UITextField) {

        guard let currentInputText = priceTextField.text else { return }

        guard let numberString = getNumberStringFromCurrencyString(string: currentInputText) else {
            logger.e("Couldn't get number string from: \(currentInputText)", .ui)
            return
        }
        guard let textWithCurrency = numberString.floatValue?.toLocalCurrencyString() else {
            logger.e("Couldn't get textWithCurrency from: \(numberString)", .ui)
            return
        }

        onPriceChange?(numberString.floatValue ?? 0)

        let currencySymbolResult = getCurrencySymbolResult(string: currentInputText)
        let hasCurrencySymbolAlready = currencySymbolResult != nil
        let currentCursorPosition = priceTextField.cursorPosition

        if let currentCursorPosition = currentCursorPosition {
            let currencySymbolResult = getCurrencySymbolResult(string: textWithCurrency)

            if let currencySymbolResult = currencySymbolResult {

                let currencyIsLeading = currencySymbolResult.range.location == 0

                if let range = Range(currencySymbolResult.range, in: textWithCurrency) {
                    let currencySymbol = String(textWithCurrency[range])
                    let newText = (currencyIsLeading ? currencySymbol : "") + numberString + (currencyIsLeading ? "" : currencySymbol)
                    priceTextField.text = newText
                }
                let currencySymbolPosition = currencySymbolResult.range.location

                let updatedCursorPosition = currentCursorPosition > currencySymbolPosition ?
                    (hasCurrencySymbolAlready ? currentCursorPosition : currentCursorPosition + 1) : currentCursorPosition

                priceTextField.moveCursor(to: updatedCursorPosition)

            } else {
                logger.e("Couldn't get currencySymbolResult. String: \(textWithCurrency)", .ui)
            }
        } else {
            logger.e("Couldn't get current cursor position. Selected range: \(String(describing: priceTextField.selectedTextRange))", .ui)
        }

        sender.invalidateIntrinsicContentSize()
    }

    fileprivate func getNumberStringFromCurrencyString(string: String) -> String? {

        let pat = "\\d+([\\.|\\,]?\\d*)"
        let regex = try! NSRegularExpression(pattern: pat, options: [])
        let result = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))

        if let result = result.first {
            if let range = Range(result.range, in: string) {
                let numberString = string[range]
                return String(numberString)
            }
        }

        return nil
    }

    fileprivate func getCurrencySymbolResult(string: String) -> NSTextCheckingResult? {
        let currencySymbolPattern = "[^0-9|\\.|\\s]"
        let currencySymbolRegex = try! NSRegularExpression(pattern: currencySymbolPattern, options: [])
        let currencySymbolResult = currencySymbolRegex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        return currencySymbolResult.first
    }

}
