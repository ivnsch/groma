//
//  InventoryItemsViewController.swift
//  shoppin
//
//  Created by ischuetz on 01/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView

class InventoryItemsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, AddEditInventoryControllerDelegate, BottonPanelViewDelegate {

    @IBOutlet weak var sortByButton: UIButton!
    @IBOutlet weak var settingsView: UIView!
    
    private var sortByPopup: CMPopTipView?
    
    private var tableViewController: InventoryItemsTableViewController?

    @IBOutlet weak var floatingViews: FloatingViews!

    private let sortByOptions: [(value: InventorySortBy, key: String)] = [
        (.Count, "Count"), (.Alphabetic, "Alphabetic")
    ]
    
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    // Warn: Setting this before prepareForSegue for tableViewController has no effect
    private var inventory: Inventory? {
        didSet {
            tableViewController?.sortBy = .Count
            tableViewController?.inventory = inventory
            if let inventory = inventory {
                navigationItem.title = inventory.name
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navSingleTap = UITapGestureRecognizer(target: self, action: "navSingleTap")
        navSingleTap.numberOfTapsRequired = 1
        navigationController?.navigationBar.subviews.first?.userInteractionEnabled = true
        navigationController?.navigationBar.subviews.first?.addGestureRecognizer(navSingleTap)
    }
    
    func navSingleTap() {
        addEditInventoryController.inventoryToEdit = inventory
        setAddEditInventoryControllerOpen(!addEditInventoryController.open)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        initFloatingViews()
        
        Providers.inventoryProvider.firstInventory(successHandler {[weak self] inventory in
            self?.navigationItem.title = inventory.name
            self?.inventory = inventory
        })
    }
    
    private func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
    
    // MARK: - UIPicker
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortByOptions.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let sortByOption = sortByOptions[row]
        sortBy(sortByOption.value)
        sortByButton.setTitle(sortByOption.key, forState: .Normal)
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = sortByOptions[row].key
        return label
    }
    
    private func sortBy(sortBy: InventorySortBy) {
        tableViewController?.sortBy = sortBy
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedInventoryItemsTableViewSegue" {
            tableViewController = segue.destinationViewController as? InventoryItemsTableViewController
        }
    }
    
    @IBAction func onSortByTap(sender: UIButton) {
        if let popup = self.sortByPopup {
            popup.dismissAnimated(true)
        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointingAtView(sortByButton, inView: view, animated: true)
        }
    }
    
    private func initFloatingViews() {
        floatingViews.setActions(Array<FLoatingButtonAction>())
        floatingViews.delegate = self
    }
    
    // MARK: - AddEditInventoryViewController
    
    func onInventoryUpdated(inventory: Inventory) {
        self.inventory = inventory
        setAddEditInventoryControllerOpen(false)
    }
    
    // MARK: - Edit Inventory
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    private var currentTopController: UIViewController?
    
    
    private func initTopController(controller: UIViewController, height: CGFloat) {
        let view = controller.view
        
        view.frame = CGRectMake(0, navigationController!.navigationBar.frame.maxY, self.view.frame.width, height)
        
        // swift anchor
        view.layer.anchorPoint = CGPointMake(0.5, 0)
        view.frame.origin = CGPointMake(0, view.frame.origin.y - height / 2)
        
        let transform: CGAffineTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 0.001) //0.001 seems to be necessary for scale down animation to be visible, with 0 the view just disappears
        view.transform = transform
    }
    
    private lazy var addEditInventoryController: AddEditInventoryController = {
        let controller = UIStoryboard.addEditInventory()
        controller.delegate = self
        controller.view.clipsToBounds = true
        
        self.initTopController(controller, height: 90)
        return controller
    }()
    
    private func setAddEditInventoryControllerOpen(open: Bool) {
        addEditInventoryController.open = open
        
        if open {
            floatingViews.setActions([FLoatingButtonAttributedAction(action: .Submit)])
        } else {
            floatingViews.setActions(Array<FLoatingButtonAction>())
            addEditInventoryController.clear()
        }
        
        if let tableView = tableViewController?.tableView {
            animateTopView(addEditInventoryController, open: open, tableView: tableView)
        }
    }
    
    
    // parameter: tableView: This is normally the listitem's table view, except when we are in section-only mode, which needs a different table view
    private func animateTopView(controller: UIViewController, open: Bool, tableView: UITableView) {
        let view = controller.view
        if open {
            self.addChildViewControllerAndView(controller)

            tableViewOverlay.frame = self.view.frame
            self.view.insertSubview(tableViewOverlay, aboveSubview: tableView)
            self.view.bringSubviewToFront(floatingViews)
            self.view.bringSubviewToFront(controller.view)
        } else {
            tableViewOverlay.removeFromSuperview()
        }

        UIView.animateWithDuration(0.3, animations: {
            if open {
                self.tableViewOverlay.alpha = 0.2
            } else {
                self.tableViewOverlay.alpha = 0
            }
            view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, open ? 1 : 0.001)

            self.topControlTopConstraint.constant = view.frame.height
            self.view.layoutIfNeeded()
            
            }) { finished in
                
                if !open {
                    controller.removeFromParentViewControllerWithView()
                }
        }
    }
    
    private lazy var tableViewOverlay: UIView = {
        let view = UIButton()
        view.backgroundColor = UIColor.blackColor()
        view.userInteractionEnabled = true
        view.alpha = 0
        view.addTarget(self, action: "onTableViewOverlayTap:", forControlEvents: .TouchUpInside)
        return view
    }()
    
    // closes top controller (whichever it may be)
    func onTableViewOverlayTap(sender: UIButton) {
        if addEditInventoryController.open {
            setAddEditInventoryControllerOpen(false)
        }
    }
    
    // MARK: - BottonPanelViewDelegate
    
    func onSubmitAction(action: FLoatingButtonAction) {
        handleFloatingViewAction(action)
    }
    
    private func handleFloatingViewAction(action: FLoatingButtonAction) {
        switch action {
        case .Submit:
            addEditInventoryController.submit()
        default: break
        }
    }
}