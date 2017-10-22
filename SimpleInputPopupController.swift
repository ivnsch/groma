//
//  SimpleInputPopupController.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

protocol SimpleInputPopupControllerDelegate: class {
    func onSubmitInput(_ text: String)
    func onDismissSimpleInputPopupController(_ cancelled: Bool)
}

class SimpleInputPopupController: UIViewController {

    @IBOutlet weak var textView: UITextView!
//    @IBOutlet weak var bgView: UIView!
    
    weak var delegate: SimpleInputPopupControllerDelegate?
    
    var animatedBG = false
    
    var overlay: UIView!
    
    var onUIReady: VoidFunction?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textContainer.maximumNumberOfLines = 2
        
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black
        overlay.alpha = 0

        self.overlay = overlay
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(SimpleInputPopupController.onTapBG(_:)))
        overlay.addGestureRecognizer(tapRecognizer)
        
        onUIReady?()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !animatedBG { // ensure fade-in animation is not shown again if e.g. user comes back from receiving a call
            animatedBG = true
            
            
            view.superview?.insertSubview(overlay, belowSubview: view)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            overlay.fillSuperview()
            animateOverlayAlpha(true)
        }
    }
    
    fileprivate func animateOverlayAlpha(_ show: Bool, onComplete: VoidFunction? = nil) {
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.overlay?.alpha = show ? 0.3 : 0
            onComplete?()
        }) 
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        overlay.removeFromSuperview()
    }
    
    @IBAction func onOkTap(_ sender: UIButton) {
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
    @objc func onTapBG(_ recognizer: UITapGestureRecognizer) {
        delegate?.onDismissSimpleInputPopupController(true)
    }
}
