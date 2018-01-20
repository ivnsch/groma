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
        let hasCancel: Bool
    }

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextView: UILabel!
    @IBOutlet weak var messageTextView: UILabel!
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

    var handleOkPress: (() -> Void)?
    var handleCancelPress: (() -> Void)?

    func config(type: MyPopupDefaultContentType, title: String? = nil, message: String) {
        let contents: Contents = {
            switch type {
            case .info: return Contents(title: title ?? trans("popup_title_info"), image: #imageLiteral(resourceName: "empty_page"), message: message, hasCancel: false)
            case .warning: return Contents(title: title ?? trans("popup_title_warning"), image: #imageLiteral(resourceName: "empty_page"), message: message, hasCancel: true)
            case .error: return Contents(title: title ?? trans("popup_title_error"), image: #imageLiteral(resourceName: "empty_page"), message: message, hasCancel: false)
            case .confirmCartBuy: return Contents(title: title ?? trans("popup_title_confirm"), image: #imageLiteral(resourceName: "empty_page"), message: message, hasCancel: true)
            }
        } ()
        fill(contents: contents)
    }

    fileprivate func fill(contents: Contents) {
        imageView.image = contents.image
        titleTextView.text = contents.title
        messageTextView.text = contents.message
        cancelButton.isHidden = !contents.hasCancel

        if !contents.hasCancel {
            cancelButtonHeightConstraint.constant = 0
        }

        titleTextView.sizeToFit()
        messageTextView.sizeToFit()

        // Adjust frame height to contents
        let contentHeight = topConstraint.constant + imageHeightConstraint.constant + imageBottomConstraint.constant + titleBottomConstraint.constant + messageBottomConstraint.constant + okButtonHeightConstraint.constant + okButtonBottomConstraint.constant + cancelButtonHeightConstraint.constant + cancelButtonBottomConstraint.constant + titleTextView.height + messageTextView.estimatedHeight()

        logger.i("Content height: \(contentHeight), label height: \(messageTextView.height), est. height: \(messageTextView.estimatedHeight())", .ui)

        view.frame = view.frame.copy(height: contentHeight)
    }

    @IBAction func onOkPress(_ sender: UIButton) {
        handleOkPress?()
    }

    @IBAction func onCancelPress(_ sender: UIButton) {
        handleCancelPress?()
    }
}
