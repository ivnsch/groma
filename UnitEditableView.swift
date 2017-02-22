//
//  UnitEditableView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 19/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

protocol UnitEditableViewDelegate: class {
    func onUnitInputChange(nameInput: String)
}

class UnitEditableView: UIView {

    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var nameTextFieldWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: UnitEditableViewDelegate?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    // TODO find a way to not have extra view here (add subview) since this is used in tableview cells.
    fileprivate func xibSetup() {
        let view = Bundle.loadView("UnitEditableView", owner: self)!
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        view.fillSuperview()
        
        isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true
        
        view.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
    }
    
    func prefill(name: String) {
        nameTextField.text = name
    }
    
    fileprivate func initTextListeners() {
        for textField in [nameTextField] {
            textField?.addTarget(self, action: #selector(onNameInputChange(_:)), for: .editingChanged)
        }
    }
    
    func onNameInputChange(_ sender: UITextField) {
        // If the input is nil (meaning at least one of the text fields is empty), we pass nil to the delegate
        // Note that we handle invalid characters theh same as if fields are empty. Shouldn't happen anyway as keyboard should be numeric.
        delegate?.onUnitInputChange(nameInput: nameTextField.text ?? "")
    }
    
    func clear() {
        nameTextField.text = ""
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initTextListeners()
    }
    
    func setMinTextFieldWidth(_ width: CGFloat) {
        nameTextFieldWidthConstraint.constant = width // for now we lose here the >=
    }
    
//    override var intrinsicContentSize: CGSize {
//        return CGSize(width: nameTextField.intrinsicContentSize.width + 20, height: nameTextField.intrinsicContentSize.height + 20) // + 20 padding
//    }
}
