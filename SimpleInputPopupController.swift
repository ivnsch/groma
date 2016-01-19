//
//  SimpleInputPopupController.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

protocol SimpleInputPopupControllerDelegate {
    func onSubmitInput(text: String)
    func onDismissSimpleInputPopupController(cancelled: Bool)
}

class SimpleInputPopupController: UIViewController {

    @IBOutlet weak var textView: UITextView!
//    @IBOutlet weak var bgView: UIView!
    
    var delegate: SimpleInputPopupControllerDelegate?
    
    var animatedBG = false
    
    var overlay: UIView!
    
    var onUIReady: VoidFunction?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textContainer.maximumNumberOfLines = 2
        
        let overlay = UIView()
        overlay.backgroundColor = UIColor.blackColor()
        overlay.alpha = 0

        self.overlay = overlay
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "onTapBG:")
        overlay.addGestureRecognizer(tapRecognizer)
        
        onUIReady?()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !animatedBG { // ensure fade-in animation is not shown again if e.g. user comes back from receiving a call
            animatedBG = true
            
            
            view.superview?.insertSubview(overlay, belowSubview: view)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            overlay.fillSuperview()
            animateOverlayAlpha(true)
        }
    }
    
    private func animateOverlayAlpha(show: Bool, onComplete: VoidFunction? = nil) {
        UIView.animateWithDuration(0.3) {[weak self] in
            self?.overlay?.alpha = show ? 0.3 : 0
            onComplete?()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        overlay.removeFromSuperview()
    }
    
    @IBAction func onOkTap(sender: UIButton) {
        delegate?.onSubmitInput(textView.text)
    }
    
    func dismiss() {
        animateOverlayAlpha(false) {[weak self] in
            self?.overlay.removeFromSuperview()
        }
        delegate?.onDismissSimpleInputPopupController(false)
        // see TODO below
    }
    
    // TODO popup should contain logic to animate back... not the parent controller
    func onTapBG(recognizer: UITapGestureRecognizer) {
        delegate?.onDismissSimpleInputPopupController(true)
    }
}