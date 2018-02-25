//
//  RecipeEditableTextCell.swift
//  groma
//
//  Created by Ivan Schuetz on 25.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class RecipeEditableTextCell: UITableViewCell, UITextViewDelegate {

    @IBOutlet weak var recipeTextView: UITextView!
    @IBOutlet weak var recipeTextViewPlaceholder: UILabel!

    fileprivate var onTextChangeHandler: ((NSAttributedString) -> Void)?
    fileprivate var onTextFocusHandler: ((Bool) -> Void)?
    fileprivate var selectionChangeHandler: ((NSRange) -> Void)?

    func config(recipeText: NSAttributedString, onTextChangeHandler: @escaping (NSAttributedString) -> Void, onTextFocusHandler: @escaping (Bool) -> Void, selectionChangeHandler: @escaping (NSRange) -> Void) {
        recipeTextView.attributedText = recipeText
        self.onTextChangeHandler = onTextChangeHandler
        self.onTextFocusHandler = onTextFocusHandler
        self.selectionChangeHandler = selectionChangeHandler

        updateRecipeTextViewPlaceholderAlpha()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        recipeTextViewPlaceholder.text = trans("recipe_enter_text")
    }

    fileprivate func updateRecipeTextViewPlaceholderAlpha() {
        recipeTextViewPlaceholder.alpha = recipeTextView.text.isEmpty ? 1 : 0
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        logger.v("Selection changed: \(textView.selectedRange)", .ui)
        selectionChangeHandler?(textView.selectedRange)
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        onTextChangeHandler?(textView.attributedText)
        UIView.animate(withDuration: 0.3) {
            self.updateRecipeTextViewPlaceholderAlpha()
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        onTextFocusHandler?(true)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        onTextFocusHandler?(false)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newLen = (textView.text.count - range.length) + text.count
        return newLen <= 6000 // a generous limit - a normal recipe is 1000-2000 chars
    }
}
