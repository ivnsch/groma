//
//  MyPopupDefaultContentViewController.swift
//  groma
//
//  Created by Ivan Schuetz on 20.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

enum MyPopupDefaultContentType {
    case info, warning, error, confirmCartBuy
}

class MyPopupDefaultContentViewController: UIViewController {

    fileprivate struct Contents {
        let title: String
        let image: UIImage
        let message: String
        let highlightRanges: [NSRange]
        let hasCancel: Bool
    }

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextView: UILabel!
    @IBOutlet weak var messageTextView: UILabel!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var okButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var okButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButtonBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!

    var handleOkPress: (() -> Void)?
    var handleCancelPress: (() -> Void)?

    // maxMsgLines: override default from nib - can be used when showing exceptionally long messages
    func config(type: MyPopupDefaultContentType, title: String? = nil, message: String, highlightRanges: [NSRange] = [], maxMsgLines: Int? = nil) {
        if let maxMsgLines = maxMsgLines {
            messageTextView.numberOfLines = maxMsgLines
        }

        let contents: Contents = {
            switch type {
            case .info: return Contents(title: title ?? trans("popup_title_info"), image: #imageLiteral(resourceName: "popup_info"), message: message, highlightRanges: highlightRanges, hasCancel: false)
            case .warning: return Contents(title: title ?? trans("popup_title_warning"), image: #imageLiteral(resourceName: "popup_warning"), message: message, highlightRanges: highlightRanges, hasCancel: true)
            case .error: return Contents(title: title ?? trans("popup_title_error"), image: #imageLiteral(resourceName: "popup_error"), message: message, highlightRanges: highlightRanges, hasCancel: false)
            case .confirmCartBuy: return Contents(title: title ?? trans("popup_title_confirm"), image: #imageLiteral(resourceName: "popup_buy"), message: message, highlightRanges: highlightRanges, hasCancel: true)
            }
        } ()
        fill(contents: contents)
    }

    fileprivate func fill(contents: Contents) {
        imageView.image = contents.image
        titleTextView.text = contents.title

        if contents.highlightRanges.isEmpty {
            messageTextView.text = contents.message
        } else {
            if let fontSize = LabelMore.mapToFontSize(40) {
                let normalFont = UIFont.systemFont(ofSize: fontSize)
                messageTextView.attributedText = contents.message.applyBoldColor(ranges: contents.highlightRanges, font: normalFont, color: Theme.blue)
            } else {
                logger.e("An error ocurred loading font/font size - defaulting to plain label", .ui)
                messageTextView.text = contents.message
            }
        }

        cancelButton.isHidden = !contents.hasCancel

        if !contents.hasCancel {
            cancelButtonHeightConstraint.constant = 0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        okButton.layer.cornerRadius = DimensionsManager.submitButtonCornerRadius
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Several attempts to calculate the labels height correctly (including sizeToFit, DispatchQueue.main.async, using only height or the default (that is, without passing the precalculated width) estimatedHeight, etc. failed, either it shows incorrectly when msg is one liner or when message is long. So we calculate the width manually and pass this to estimatedHeight - this seems to be working. Note in didAppear probably this works but that seems too late to set the frame.
        let labelsWidth = view.width - leftConstraint.constant - rightConstraint.constant

        let contentHeight = topConstraint.constant + imageHeightConstraint.constant + imageBottomConstraint.constant + titleBottomConstraint.constant + messageBottomConstraint.constant + okButtonHeightConstraint.constant + okButtonBottomConstraint.constant + cancelButtonHeightConstraint.constant + cancelButtonBottomConstraint.constant + titleTextView.estimatedHeight(overrideWidth: labelsWidth) + messageTextView.estimatedHeight(overrideWidth: labelsWidth)
        self.view.frame = self.view.frame.copy(height: contentHeight)
    }

    @IBAction func onOkPress(_ sender: UIButton) {
        handleOkPress?()
    }

    @IBAction func onCancelPress(_ sender: UIButton) {
        handleCancelPress?()
    }
}
