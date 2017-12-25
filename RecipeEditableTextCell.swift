//
//  RecipeEditableTextCell.swift
//  groma
//
//  Created by Ivan Schuetz on 25.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class RecipeEditableTextCell: UITableViewCell, UITextViewDelegate {

    @IBOutlet weak var recipeTextView: UITextView!

    fileprivate var onTextChangeHandler: ((String) -> Void)?

    func config(recipeText: String, onTextChangeHandler: ((String) -> Void)?) {
        recipeTextView.text = recipeText
        self.onTextChangeHandler = onTextChangeHandler
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        onTextChangeHandler?(textView.text)
    }
}
