//
//  NoteViewController.swift
//  groma
//
//  Created by Ivan Schuetz on 10.06.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class NoteViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!

    var closeTapHandler: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = trans("popup_note_title")
    }

    @IBAction func onCloseTap(_ sender: UIButton) {
        closeTapHandler?()
    }

    static func show(parent: UIViewController, text: String, from: UIView? = nil) -> MyPopup {
        let controller = NoteViewController()
        let preferredFrame = CGRect(x: 100, y: 10, width: 340, height: 250)

        controller.view.frame = {
            let width = min(preferredFrame.width, UIScreen.main.bounds.width - DimensionsManager.minPopupHMargin * 2)
            return preferredFrame.copy(width: width)
        } ()

        controller.view.layer.cornerRadius = Theme.popupCornerRadius
        controller.view.clipsToBounds = true

        let popup = MyPopupHelper.showCustomPopupFrom(parent: parent, centerYOffset: 0, contentController: controller, swipeEnabled: true, useDefaultFrame: false, from: from)

        controller.closeTapHandler = {
            controller.removeFromParentViewController()
            popup.hide()
        }

        controller.noteLabel.text = text

        return popup
    }
}
