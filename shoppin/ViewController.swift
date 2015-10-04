//
//  ViewController.swift
//  shoppin
//
//  Created by ischuetz on 06.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData
import SwiftValidator
import KLCPopup

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, EditListItemContentViewDelegate, ListItemsEditTableViewDelegate
//    , UIBarPositioningDelegate
{
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller

    private var addEditItemPopup: KLCPopup?
    private var addEditItemView: EditListItemContentView?
    
    @IBOutlet weak var addButtonContainer: UIView!
    @IBOutlet weak var addButtonContainerBottomConstraint: NSLayoutConstraint!

    private var listItemsTableViewController: ListItemsTableViewController!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    private var gestureRecognizer: UIGestureRecognizer!
    
    private var updatingListItem: ListItem?
    
    @IBOutlet weak var pricesView: PricesView!
    
    @IBOutlet weak var listNameView: UILabel!

    var currentList: List? {
        didSet {
            print("huhu, currentList: \(currentList)")
            
            if let list = self.currentList {
                self.navigationItem.title = list.name
                self.initWithList(list)
            }
        }
    }
    var onViewWillAppear: VoidFunction?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableViewController()
        
        setEditing(false, animated: false)
        updatePrices()
        FrozenEffect.apply(self.pricesView)
    }
   
    private func setAddButtonVisible(visible: Bool, animated: Bool = false) {
        addButtonContainerBottomConstraint.constant = visible ? 0 : -100
        if animated {
            UIView.animateWithDuration(0.2) {[weak self] () -> Void in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        onViewWillAppear?()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    private func initWithList(list: List) {
        Providers.listItemsProvider.listItems(list, fetchMode: .MemOnly, successHandler{listItems in
            self.listItemsTableViewController.setListItems(listItems.filter{!$0.done})
        })
    }
    
    // MARK: - EditListItemContentViewDelegate

    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
//        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String) {
        submitInputs(name, price: priceText, quantity: quantityText, sectionName: sectionName) {
            addEditItemPopup?.dismiss(true)
        }
    }
    
    private func submitInputs(name: String, price priceText: String, quantity quantityText: String, sectionName: String, successHandler: VoidFunction? = nil) {
        
        if !name.isEmpty {
            if let listItemInput = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, sectionName: sectionName) {
                self.addItem(listItemInput, successHandler: successHandler)
                // self.view.endEditing(true)
            }
        }
    }
    
    func onOkAndAddAnotherTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String) {
        submitInputs(name, price: priceText, quantity: quantityText, sectionName: sectionName) {[weak self] in
            self?.addEditItemView?.clearInputs()
        }
    }

    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String) {
        if let listItemInput = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, sectionName: sectionName) {
            self.updateItem(self.updatingListItem!, listItemInput: listItemInput) {[weak self] in
                self?.view.endEditing(true)
                self?.updatingListItem = nil
                self?.addEditItemPopup?.dismiss(true)
            }
        }
    }
    
    func productNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.listItemsProvider.productSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    func sectionNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.listItemsProvider.sectionSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    private func processListItemInputs(name: String, priceText: String, quantityText: String, sectionName: String) -> ListItemInput? {
        //TODO?
        //        if !price {
        //            price = 0
        //        }
        //        if !quantity {
        //            quantity = 0
        //        }
        
        if let price = priceText.floatValue {
            let quantity = Int(quantityText) ?? 1
            let sectionName = sectionName ?? defaultSectionIdentifier
            
            return ListItemInput(name: name, quantity: quantity, price: price, section: sectionName)
            
        } else {
            print("TODO validation in processListItemInputs")
            return nil
        }
    }
    
    @IBAction func onEditTap(sender: AnyObject) {
        let editing = !self.listItemsTableViewController.editing
        
        self.setEditing(editing, animated: true)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        setAddButtonVisible(editing, animated: animated)

        listItemsTableViewController.setEditing(editing, animated: animated)
//        self.gestureRecognizer.enabled = !editing //don't block tap on delete button
        gestureRecognizer.enabled = false //don't block tap on delete button

        let navbarHeight = navigationController!.navigationBar.frame.height
        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)

        let topInset = navbarHeight + statusBarHeight + CGRectGetHeight(pricesView.frame)
        
        // TODO this makes a very big bottom inset why?
//            let bottomInset = (navigationController?.tabBarController?.tabBar.frame.height)! + addButtonContainer.frame.height
        let bottomInset = (navigationController?.tabBarController?.tabBar.frame.height)! + 20
    
        listItemsTableViewController.tableViewInset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
        listItemsTableViewController.tableViewTopOffset = -listItemsTableViewController.tableViewInset.top
        
        if editing {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }
    
    // TODO do we still need this? This was prob used by done view controller to update our list
//    func itemsChanged() {
//        self.initList()
//    }
    
    private func initTableViewController() {
        self.listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        
        self.addChildViewControllerAndView(self.listItemsTableViewController, viewIndex: 0)
        
        self.gestureRecognizer = UITapGestureRecognizer(target: self, action: "clearThings")
        self.listItemsTableViewController.view.addGestureRecognizer(gestureRecognizer)
        self.listItemsTableViewController.scrollViewDelegate = self
        self.listItemsTableViewController.listItemsTableViewDelegate = self
        self.listItemsTableViewController.listItemsEditTableViewDelegate = self
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        clearThings()
    }
    
    func clearThings() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    func onListItemClear(tableViewListItem: TableViewListItem, onFinish: VoidFunction) {
        tableViewListItem.listItem.done = true
        
        if let list = self.currentList {
            
            Providers.listItemsProvider.switchDone([tableViewListItem.listItem], list: list, done: true) {[weak self] result in
                if result.success {
                    self!.listItemsTableViewController.removeListItem(tableViewListItem.listItem, animation: .Bottom)
                    self!.updatePrices(.MemOnly)
                }
                onFinish()
            }
        } else {
            onFinish()
        }
    }

//    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
//        return UIBarPosition.TopAttached
//    }
    
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return UIStatusBarStyle.LightContent
//    }

    private func getTableViewInset() -> CGFloat {
        let navbarHeight = self.navigationController!.navigationBar.frame.height
        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
        return navbarHeight + statusBarHeight
    }

    func loadItems(handler: Try<[String]> -> ()) {
        Providers.listItemsProvider.products(successHandler{products in
            let names = products.map{$0.name}
            handler(Try(names))
        })
    }
    
    func onListItemsChangedSection(tableViewListItems: [TableViewListItem]) {
        Providers.listItemsProvider.update(tableViewListItems.map{$0.listItem}, successHandler{result in
        })
    }
    
    /**
    
    */
    func updatePrices(listItemsFetchMode: ProviderFetchModus = .Both) {

        func calculatePrice(listItems:[ListItem]) -> Float {
            return listItems.reduce(0, combine: {(price:Float, listItem:ListItem) -> Float in
                return price + (listItem.product.price * Float(listItem.quantity))
            })
        }
        
        if let currentList = self.currentList {
            Providers.listItemsProvider.listItems(currentList, fetchMode: listItemsFetchMode, successHandler{listItems in
                    
                //        let allListItems = self.tableViewSections.map {
                //            $0.listItems
                //        }.reduce([], combine: +)
                
                let totalPrice:Float = calculatePrice(listItems)
                
                let doneListItems = listItems.filter{$0.done}
                let donePrice:Float = calculatePrice(doneListItems)
                
                self.pricesView.totalPrice = totalPrice
                self.pricesView.donePrice = donePrice
            })
        }
    }

    private func addItem(listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {

        if let currentList = self.currentList {
            
            self.progressVisible(true)
            
            Providers.listItemsProvider.add(listItemInput, list: currentList, order: nil, possibleNewSectionOrder: self.listItemsTableViewController.sections.count, successHandler {savedListItem in
                self.listItemsTableViewController.addListItem(savedListItem)
                self.updatePrices(.MemOnly)
                
                handler?()
            })
            
        } else {
            print("Error: Invalid state: trying to add item without current list")
        }

    }
    
    func updateItem(listItem: ListItem, listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {
        if let currentList = self.currentList {
            
            if let updatingListItem = self.updatingListItem {
                
                let product = Product(uuid: updatingListItem.product.uuid, name: listItemInput.name, price: listItemInput.price) // possible product update
                let section = Section(uuid: updatingListItem.section.uuid, name: listItemInput.section, order: listItem.section.order) // possible section update
                
                let listItem = ListItem(uuid: updatingListItem.uuid, done: updatingListItem.done, quantity: listItemInput.quantity, product: product, section: section, list: currentList, order: updatingListItem.order)
                
                Providers.listItemsProvider.update([listItem], successHandler {
                    self.listItemsTableViewController.updateListItem(listItem)
                    self.updatePrices(.MemOnly)
                    
                    handler?()
                })
                
            } else {
                print("Error: Invalid state: trying to update list item without updatingListItem")
            }

        } else {
            print("Error: Invalid state: trying to update list item without current list")
        }

    }
    

    func onListItemSelected(tableViewListItem: TableViewListItem, indexPath: NSIndexPath) {
        if self.editing {
            let addEditItemView = createAndInitAddEditView()
            self.updatingListItem = tableViewListItem.listItem
            addEditItemView.setUpdateItem(tableViewListItem.listItem)
            addEditItemPopup = createAddEditPopup(addEditItemView)
            addEditItemPopup?.show()
            
        } else {
            listItemsTableViewController.markOpen(true, indexPath: indexPath)
        }
    }
    
    private func createAndInitAddEditView() -> EditListItemContentView {
        let addEditItemView = NSBundle.loadView("EditListItemContentView", owner: self) as! EditListItemContentView
        addEditItemView.frame = CGRectMake(0, 0, 300, 400)
        addEditItemView.delegate = self
        self.addEditItemView = addEditItemView
        return addEditItemView
    }
    
    private func createAddEditPopup(contentView: EditListItemContentView) -> KLCPopup {
        return KLCPopup(contentView: contentView, showType: KLCPopupShowType.ShrinkIn, dismissType: KLCPopupDismissType.ShrinkOut, maskType: KLCPopupMaskType.Dimmed, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
    }
    
    func onListItemDeleted(tableViewListItem: TableViewListItem) {
        Providers.listItemsProvider.remove(tableViewListItem.listItem, successHandler{
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "doneViewControllerSegue" {
            if let doneViewController = segue.destinationViewController as? DoneViewController {
                listItemsTableViewController.clearPendingSwipeItemIfAny {
                    doneViewController.onUIReady = {
                        doneViewController.list = self.currentList
                    }
                }
            }
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        // Move popup up such that all text fields are reachable
        UIView.animateWithDuration(0.2, animations: {[weak self]() -> Void in
            if let addEditItemPopup = self?.addEditItemPopup {
                // only move popup up if keyboard was down before
                // the problem here is that jump from alpha to numbers keypad (or the other way) triggers keyboardWillShow and not keyboardWillHide
                // so we have to avoid that popup goes up when user jumps from one field to another
                if addEditItemPopup.tag == 0 { // note 0 is also default for "no tag"
                    let center = CGPointMake(addEditItemPopup.center.x, addEditItemPopup.center.y - 30)
                    addEditItemPopup.center = center
                    addEditItemPopup.tag = 1 // 1 -> "up"
                }
            }
        })
    }

    func keyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(0.2, animations: {[weak self] () -> Void in
            if let popup = self?.addEditItemPopup {
                let center = CGPointMake(popup.center.x, popup.center.y + 30)
                popup.center = center
                popup.tag = 0 // 0 -> "normal/center"
            }
        })
    }
    
    @IBAction func onAddTap(sender: UIButton) {
        addEditItemPopup = createAddEditPopup(createAndInitAddEditView())
        addEditItemPopup?.show()
    }
}