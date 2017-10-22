//
//  EditSectionViewController.swift
//  shoppin
//
//  Created by ischuetz on 07/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

import Providers

protocol EditSectionViewControllerDelegate: class {
    func onSectionUpdated(_ section: Section)
}

class EditSectionViewController: UIViewController, FlatColorPickerControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var colorButton: UITextField!
    
    fileprivate var showingColorPicker: FlatColorPickerController?
    
    var open: Bool = false
    
    fileprivate var validator: Validator?
    
    fileprivate var keyboardHeight: CGFloat?
    
    var section: Section? {
        didSet {
            if nameTextField != nil {
                nameTextField.text = section?.name
                view.backgroundColor = section?.color
            } else {
                logger.w("Outlets not initialised")
            }
        }
    }
    
    fileprivate var addButtonHelper: AddButtonHelper?
    
    weak var delegate: EditSectionViewControllerDelegate?
    
    init() {
        super.init(nibName: "EditSectionViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.attributedPlaceholder = NSAttributedString(string: trans("placeholder_section_name"), attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
        
        initValidator()
        
        nameTextField.becomeFirstResponder()
        
        view.clipsToBounds = false
    }
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentView = parent?.view else {logger.e("No parentController"); return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentView) {[weak self] in
            self?.submit()
        }
        return addButtonHelper
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addButtonHelper = initAddButtonHelper() // parent controller not set yet in earlier lifecycle methods
        addButtonHelper?.addObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
    }
    
    fileprivate func initValidator() {
        let validator = Validator()
        validator.registerField(nameTextField, rules: [MinLengthRule(length: 1, message: trans("validation_section_name_not_empty"))])
        self.validator = validator
    }
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
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
            for (_, error) in errors {
                error.field.showValidationError()
                present(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            }
            
        } else {
            for (_, error) in validator.errors {
                error.field.clearValidationError()
            }
            
            if let name = nameTextField.text, let color = view.backgroundColor {
                let sectionInput = SectionInput(name: name, color: color)
                Prov.sectionProvider.update(section, input: sectionInput, successHandler {[weak self] updatedSection in
                    self?.delegate?.onSectionUpdated(updatedSection)
                })
                
            } else {
                print("Error: EditSectionViewController.submit: validation was not implemented correctly")
            }
        }
    }
    
    // MARK: - FlatColorPickerControllerDelegate
    
    func onColorPicked(_ color: UIColor) {
        dismissColorPicker(color)
    }
    
    fileprivate func dismissColorPicker(_ selectedColor: UIColor?) {
        if let showingColorPicker = showingColorPicker {
            
            UIView.animate(withDuration: 0.3, animations: {
                showingColorPicker.view.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                
                }, completion: {[weak self] finished in
                    self?.showingColorPicker = nil
                    self?.showingColorPicker?.removeFromParentViewControllerWithView()
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        if let selectedColor = selectedColor {
                            self?.view.backgroundColor = selectedColor
                        }
                    }) 
                    UIView.animate(withDuration: 0.15, animations: {
                        self?.colorButton.transform = CGAffineTransform(scaleX: 2, y: 2)
                        UIView.animate(withDuration: 0.15, animations: {
                            self?.colorButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                        }) 
                    }) 
                    
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
        
        if let parentViewController = parent {
            
            let topBarHeight: CGFloat = 64
            
            picker.view.frame = CGRect(x: 0, y: topBarHeight, width: parentViewController.view.frame.width, height: parentViewController.view.frame.height - topBarHeight)
            
            parentViewController.addChildViewControllerAndView(picker) // add to superview (lists controller) because it has to occupy full space (navbar - tab)
            picker.delegate = self
            showingColorPicker = picker
            
            let buttonPointInParent = parentViewController.view.convert(CGPoint(x: colorButton.center.x, y: colorButton.center.y - topBarHeight), from: view)
            let fractionX = buttonPointInParent.x / parentViewController.view.frame.width
            let fractionY = buttonPointInParent.y / (parentViewController.view.frame.height - topBarHeight)
            
            picker.view.layer.anchorPoint = CGPoint(x: fractionX, y: fractionY)
            
            picker.view.frame = CGRect(x: 0, y: topBarHeight, width: parentViewController.view.frame.width, height: parentViewController.view.frame.height - topBarHeight)
            
            picker.view.transform = CGAffineTransform(scaleX: 0, y: 0)
            
            UIView.animate(withDuration: 0.3, animations: {
                picker.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            }) 
            
            view.endEditing(true)

        } else {
            print("Warning: AddEditListController.onColorTap: no parentViewController")
        }
    }
    
    func onClose() {
    }
}
