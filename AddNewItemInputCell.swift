//
//  AddNewItemInputCell.swift
//  groma
//
//  Created by Ivan Schuetz on 20.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class AddNewItemInputCell: UITableViewCell {

    @IBOutlet var textField: LineTextField!

    fileprivate var onInputUpdate: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    func configure(placeholder: String, onlyNumbers: Bool, onInputUpdate: @escaping (String) -> Void) {
        self.onInputUpdate = onInputUpdate
        textField.setPlaceholderWithColor(placeholder, color: Theme.midGrey)
        textField.lineColor = Theme.midGrey
        if onlyNumbers {
            textField.keyboardType = .decimalPad
        } else {
            textField.keyboardType = .default
        }
    }

    @IBAction func onTextInputChange(_ sender: LineTextField) {
        onInputUpdate?(sender.text ?? "")
    }

}
