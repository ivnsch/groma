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

    fileprivate var onTextChangeHandler: ((NSAttributedString) -> Void)?
    fileprivate var onTextFocusHandler: ((Bool) -> Void)?
    fileprivate var selectionChangeHandler: ((NSRange) -> Void)?

    func config(recipeText: NSAttributedString, onTextChangeHandler: @escaping (NSAttributedString) -> Void, onTextFocusHandler: @escaping (Bool) -> Void, selectionChangeHandler: @escaping (NSRange) -> Void) {
        recipeTextView.attributedText = recipeText
        self.onTextChangeHandler = onTextChangeHandler
        self.onTextFocusHandler = onTextFocusHandler
        self.selectionChangeHandler = selectionChangeHandler
    }


    func textViewDidChangeSelection(_ textView: UITextView) {
        selectionChangeHandler?(textView.selectedRange)
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        onTextChangeHandler?(textView.attributedText)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        onTextFocusHandler?(true)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        onTextFocusHandler?(false)
    }
}
