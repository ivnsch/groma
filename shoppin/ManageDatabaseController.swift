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
    case items, brands, bases, units
}

typealias ManageDatabaseControllerOption = (value: ManageDatabaseTypeSelection, key: String)

class ManageDatabaseController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    var selectedOption: ManageDatabaseControllerOption?
    @IBOutlet weak var selectOptionButton: UIButton!
    fileprivate let selectOptions: [ManageDatabaseControllerOption] = [
        (.items, trans("select_items")),
        (.brands, trans("select_brands")),
        (.bases, trans("select_base_quantities")),
        (.units, trans("select_units"))
    ]
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topMenusHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var searchBoxHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBar: UITextField!

    var currentFilter: String = "" {
        didSet {
            selectedOptionController?.filterItems(str: currentFilter)
        }
    }
    
    fileprivate var selectedOptionController: SearchableTextController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = trans("title_manage_database")
        
        searchBar.addTarget(self, action: #selector(searchFieldDidChange(_:)), for: .editingChanged)

        layout()

        if let first = selectOptions.first {
            load(option: first)
        } else {
            QL4("No options")
        }
    }
    
    
    fileprivate func layout() {
        searchBoxHeightConstraint.constant = DimensionsManager.searchBarHeight
    }

    // MARK: - Filter
    
    func searchFieldDidChange(_ textField: UITextField) {
        filter(textField.text ?? "")
    }
    
    fileprivate func filter(_ searchText: String) {
        self.currentFilter = searchText
    }
    
    // MARK: -
    
    fileprivate func load(option: ManageDatabaseControllerOption) {
        
        selectOptionButton.setTitle(option.key, for: UIControlState())
        
        (selectedOptionController as? UIViewController)?.removeFromParentViewControllerWithView()
        
        let searchableTextController: SearchableTextController = {
            switch option.value {
            case .items:
                let controller = UIStoryboard.manageItemsController()
                controller.delegate = self
                return controller
                
            case .brands:
                let controller = UIStoryboard.manageBrandsController()
                controller.delegate = self
                return controller
                
            case .bases:
                let controller = UIStoryboard.manageBasesController()
                controller.delegate = self
                return controller
                
            case .units:
                let controller = UIStoryboard.manageUnitsController()
                controller.delegate = self
                return controller
            }
        }()
        
        self.selectedOptionController = searchableTextController
        
        let controller = searchableTextController as! UIViewController // Swift doesn't allow yet to declare as subclass & conforming to protocol so for now this
        
        addChildViewController(controller)
        containerView.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.fillSuperview()
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
        selectedOption = selectOption
        
        load(option: selectOption)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = selectOptions[row].key
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return DimensionsManager.pickerRowHeight
    }
    
    @IBAction func onSelectTypeTap(_ sender: UIButton) {
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

protocol SearchableItemsControllersDelegate: class {
    var currentFilter: String {get}
}

// MARK: - ManageItemsControllerDelegate

extension ManageDatabaseController: ManageItemsControllerDelegate, ManageItemsBrandsControllerDelegate {
    
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
        topControlTopConstraint.constant = expand ? view.frame.height - 10 : 10 // 10: top constraint constant of search bar
        searchBoxHeightConstraint.constant = expand ? 0 : DimensionsManager.searchBarHeight
        topMenusHeightConstraint.constant = expand ? 0 : DimensionsManager.topMenuBarHeight
        view.layoutIfNeeded()
    }
    
    func onExpandableClose() {
//        topBarOnCloseExpandable()
//        toggleButtonRotator.enabled = true
//        topQuickAddControllerManager?.controller?.onClose()
    }
}

