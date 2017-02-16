//
//  ManageDatabaseController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 16/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs

enum ManageDatabaseTypeSelection {
    case items, brands, baseQuantities, units
}

class ManageDatabaseController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    var selectedOption: ManageDatabaseTypeSelection = .items
    @IBOutlet weak var selectOptionButton: UIButton!
    fileprivate let selectOptions: [(value: ManageDatabaseTypeSelection, key: String)] = [
        (.items, trans("select_items")),
        (.brands, trans("select_brands")),
        (.baseQuantities, trans("select_base_quantities")),
        (.units, ("select_units"))
    ]
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topMenusHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerView: UIView!
    
    fileprivate var selectedOptionController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        

        load(option: .items)
    }

    
    fileprivate func load(option: ManageDatabaseTypeSelection) {
        
        selectedOptionController?.removeFromParentViewControllerWithView()
        
        switch option {
        case .items:
            let controller = UIStoryboard.manageItemsController()
            controller.delegate = self
            addChildViewController(controller)
            containerView.addSubview(controller.view)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            controller.view.fillSuperview()
            
        default: print("TODO")
        }
    }

    
    
    // MARK: - UIPicker
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return selectOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectOption = selectOptions[row]
        selectedOption = selectOption.value
        selectOptionButton.setTitle(selectOption.key, for: UIControlState())
        
        load(option: selectedOption)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = selectOptions[row].key
        return label
    }
    
    @IBAction func onSortByTap(_ sender: UIButton) {
        //        if let popup = self.sortByPopup {
        //            popup.dismissAnimated(true)
        //        } else {
        let popup = MyTipPopup(customView: createPicker())
        popup.presentPointing(at: selectOptionButton, in: view, animated: true)
        //        }
    }
    
    fileprivate func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
}

// MARK: - ManageItemsControllerDelegate

extension ManageDatabaseController: ManageItemsControllerDelegate {
    
    var topControllerConfig: ManageDatabaseTopControllerConfig {
        return ManageDatabaseTopControllerConfig(
            top: 0, // we currently use the system's nav bar so there's no offset (view controller starts below it)
            animateInset: false,
            parentController: self,
            delegate: self
        )
    }
    
}

// MARK: - ExpandableTopViewControllerDelegate

extension ManageDatabaseController: ExpandableTopViewControllerDelegate {
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
        // Fix top line looks slightly thicker after animation. Problem: We have to animate to min scale of 0.0001 because 0 doesn't work correctly (iOS bug) so the frame height passed here is not exactly 0, which leaves a little gap when we set it in the constraint
        topControlTopConstraint.constant = view.frame.height
        topMenusHeightConstraint.constant = expand ? 0 : DimensionsManager.topMenuBarHeight
        view.layoutIfNeeded()
    }
    
    func onExpandableClose() {
//        topBarOnCloseExpandable()
//        toggleButtonRotator.enabled = true
//        topQuickAddControllerManager?.controller?.onClose()
    }
}
