//
//  EditSectionViewController.swift
//  shoppin
//
//  Created by ischuetz on 07/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import QorumLogs

protocol EditSectionViewControllerDelegate {
    func onSectionUpdated(section: Section)
}

class EditSectionViewController: UIViewController, FlatColorPickerControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var colorButton: UITextField!
    
    private var showingColorPicker: FlatColorPickerController?
    
    var open: Bool = false
    
    private var validator: Validator?
    
    private var keyboardHeight: CGFloat?
    
    var section: Section? {
        didSet {
            if nameTextField != nil {
                nameTextField.text = section?.name
                view.backgroundColor = section?.color
            } else {
                QL3("Outlets not initialised")
            }
        }
    }
    
    private var addButtonHelper: AddButtonHelper?
    
    var delegate: EditSectionViewControllerDelegate?
    
    init() {
        super.init(nibName: "EditSectionViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.attributedPlaceholder = NSAttributedString(string: "Section name", attributes: [NSForegroundColorAttributeName: UIColor.grayColor()])
        
        initValidator()
        
        nameTextField.becomeFirstResponder()
        
        view.clipsToBounds = false
    }
    
    private func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentView = parentViewController?.view else {QL4("No parentController"); return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentView) {[weak self] in
            self?.submit()
        }
        return addButtonHelper
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addButtonHelper = initAddButtonHelper() // parent controller not set yet in earlier lifecycle methods
        addButtonHelper?.addObserver()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(nameTextField, rules: [MinLengthRule(length: 1, message: "validation_section_name_not_empty")])
        self.validator = validator
    }
    
    func textFieldShouldReturn(sender: UITextField) -> Bool {
        if sender == nameTextField {
            submit()
            sender.resignFirstResponder()
        }
        
        return false
    }
    
    func submit() {
        guard let validator = validator else {return}
        guard let section = section else {
            print("Error: EditSectionViewController.submit: no section")
            return
        }
        
        if let errors = validator.validate() {
            for (field, _) in errors {
                field.showValidationError()
                presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            }
            
        } else {
            if let lastErrors = validator.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            
            if let name = nameTextField.text, color = view.backgroundColor {
                let updatedSection = section.copy(name: name, color: color)
                Providers.sectionProvider.update([updatedSection], remote: true, successHandler {[weak self] in
                    self?.delegate?.onSectionUpdated(updatedSection)
                })
                
            } else {
                print("Error: EditSectionViewController.submit: validation was not implemented correctly")
            }
        }
    }
    
    // MARK: - FlatColorPickerControllerDelegate
    
    func onColorPicked(color: UIColor) {
        dismissColorPicker(color)
    }
    
    private func dismissColorPicker(selectedColor: UIColor?) {
        if let showingColorPicker = showingColorPicker {
            
            UIView.animateWithDuration(0.3, animations: {
                showingColorPicker.view.transform = CGAffineTransformMakeScale(0.001, 0.001)
                
                }, completion: {[weak self] finished in
                    self?.showingColorPicker = nil
                    self?.showingColorPicker?.removeFromParentViewControllerWithView()
                    
                    UIView.animateWithDuration(0.3) {
                        if let selectedColor = selectedColor {
                            self?.view.backgroundColor = selectedColor
                        }
                    }
                    UIView.animateWithDuration(0.15) {
                        self?.colorButton.transform = CGAffineTransformMakeScale(2, 2)
                        UIView.animateWithDuration(0.15) {
                            self?.colorButton.transform = CGAffineTransformMakeScale(1, 1)
                        }
                    }
                    
                    self?.nameTextField.becomeFirstResponder()
                }
            )
        }
    }
    
    func onDismiss() {
        //        dismissColorPicker(nil) // not used see FIXME in FlatColorPickerController.viewDidLoad
    }
    
    @IBAction func onColorTap() {
        let picker = UIStoryboard.listColorPicker()
        self.view.layoutIfNeeded() // TODO is this necessary? don't think so check and remove
        
        if let parentViewController = parentViewController {
            
            let topBarHeight: CGFloat = 64
            
            picker.view.frame = CGRectMake(0, topBarHeight, parentViewController.view.frame.width, parentViewController.view.frame.height - topBarHeight)
            
            parentViewController.addChildViewControllerAndView(picker) // add to superview (lists controller) because it has to occupy full space (navbar - tab)
            picker.delegate = self
            showingColorPicker = picker
            
            let buttonPointInParent = parentViewController.view.convertPoint(CGPointMake(colorButton.center.x, colorButton.center.y - topBarHeight), fromView: view)
            let fractionX = buttonPointInParent.x / parentViewController.view.frame.width
            let fractionY = buttonPointInParent.y / (parentViewController.view.frame.height - topBarHeight)
            
            picker.view.layer.anchorPoint = CGPointMake(fractionX, fractionY)
            
            picker.view.frame = CGRectMake(0, topBarHeight, parentViewController.view.frame.width, parentViewController.view.frame.height - topBarHeight)
            
            picker.view.transform = CGAffineTransformMakeScale(0, 0)
            
            UIView.animateWithDuration(0.3) {
                picker.view.transform = CGAffineTransformMakeScale(1, 1)
            }
            
            view.endEditing(true)

        } else {
            print("Warning: AddEditListController.onColorTap: no parentViewController")
        }
    }
    
    func onClose() {
    }
}
