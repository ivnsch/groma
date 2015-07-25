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

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, AddItemViewDelegate, ListItemsEditTableViewDelegate
//    , UIBarPositioningDelegate
{
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller
    
    @IBOutlet weak var addItemView: AddItemView!
    
    lazy var sectionAutosuggestionsViewController:AutosuggestionsTableViewController = {
        
        let frame = self.addItemView.sectionAutosuggestionsFrame(self.view)

        let viewController = AutosuggestionsTableViewController(frame: frame, onSuggestionSelected: { (suggestion:String) -> () in
            self.onSectionSuggestionSelected(suggestion)
        })
        
        self.addChildViewControllerAndView(viewController)
        
        return viewController
    }()
    
    private let listItemsProvider = ProviderFactory().listItemProvider
    private let listProvider = ProviderFactory().listProvider
    
    private var listItemsTableViewController:ListItemsTableViewController!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    private var gestureRecognizer:UIGestureRecognizer!
    
    private var updatingListItem:ListItem?
    
    @IBOutlet weak var pricesView: PricesView!
    
    @IBOutlet weak var listNameView: UILabel!

    var currentList: List?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initTableViewController()

        self.addItemView.delegate = self
        self.setEditing(false, animated: false)
        self.updatePrices()
        FrozenEffect.apply(self.pricesView)
        
        if let list = self.currentList {
            self.navigationItem.title = list.name
        }
    }
   
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let list = self.currentList {
            self.listItemsProvider.listItems(list, successHandler{listItems in
                self.listItemsTableViewController.setListItems(listItems.filter{!$0.done})
            })
        }
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        self.setAddItemViewAnchorPointTopCenter()
    }
    
    //prepare add item view for scale animation, which should be top to bottom
    private func setAddItemViewAnchorPointTopCenter() {
        
        if let _ = self.navigationController {
//            let frame = self.addItemView.frame
//            let topCenter = CGPointMake(CGRectGetMidX(frame), CGRectGetMinY(frame))
            
            self.addItemView.layer.anchorPoint = CGPointMake(0.5, 0)
            
            //        println("constraint height: \(self.addItemView.topConstraint.constant)")
            
//            let navbarHeight = navigationController.navigationBar.frame.height
//            let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
            
            //////////////////////////////////////////////////////////////////////
            //FIXME
            //        self.addItemView.layer.position = topCenter
            
            //for some reason we get -64 or alternate between -66.5 and -64 (depending where we call this) if we use this. It should be always -66.5
            //                self.addItemView.topConstraint.constant = -topCenter.y
            
            //and if we use this, we get always -64. why is extra offset? our view should start exactly after status and navigation bar
            //                let navbarHeight = self.navigationController!.navigationBar.frame.height
            //                let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
            //                let offset = navbarHeight + statusBarHeight
            //                self.addItemView.topConstraint.constant = -offset
            
            self.addItemView.topConstraint.constant = -66.5
            //////////////////////////////////////////////////////////////////////
        }
    }
    
    // MARK: - AddItemViewDelegate

    func onValidationErrors(errors: [UITextField: ValidationError]) {
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    // TODO rename )After validation)
    func onAddTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String) {
        
        if !name.isEmpty {
            
            if let listItemInput = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, sectionName: sectionName) {
                self.addItem(listItemInput)
                self.view.endEditing(true)
                self.addItemView.clearInputs()
            }
        }
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String) {
        if let listItemInput = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, sectionName: sectionName) {
            self.updateItem(self.updatingListItem!, listItemInput: listItemInput)
            self.view.endEditing(true)
            self.addItemView.clearInputs()
            
            self.updatingListItem = nil
        }
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

    func onSectionInputChanged(text: String) {
        
        self.listItemsProvider.sections(successHandler{[weak self] sections in
            
            self?.sectionAutosuggestionsViewController.options = sections.map{$0.name ?? ""} //TODO make this async or add a memory cache
            self?.sectionAutosuggestionsViewController.searchText(text)
            
            self?.sectionAutosuggestionsViewController.view.hidden = text.isEmpty
        })
    }
    
    @IBAction func onEditTap(sender: AnyObject) {
        let editing = !self.listItemsTableViewController.editing
        
        self.setEditing(editing, animated: true)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        self.listItemsTableViewController.setEditing(editing, animated: animated)
        self.gestureRecognizer.enabled = !editing //don't block tap on delete button

        self.addItemView.expanded = editing
        let animationTime:NSTimeInterval = animated ? 0.2 : 0

//        self.addItemView.hidden = false
        
        UIView.animateWithDuration(animationTime, animations: { () -> Void in
            let transform:CGAffineTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1, editing ? 1 : 0.001) //0.001 seems to be necessary for scale down animation to be visible, with 0 the view just disappears
            self.addItemView.transform = transform
            

            let navbarHeight = self.navigationController!.navigationBar.frame.height
            let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)

            let topInset = navbarHeight + statusBarHeight + CGRectGetHeight(self.addItemView.frame) + CGRectGetHeight(self.pricesView.frame)
            let bottomInset = self.navigationController?.tabBarController?.tabBar.frame.height
            self.listItemsTableViewController.tableViewInset = UIEdgeInsetsMake(topInset, 0, bottomInset!, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
            self.listItemsTableViewController.tableViewTopOffset = -self.listItemsTableViewController.tableViewInset.top
            
        }) { p in
//            if !editing {self.addItemView.hidden = true} // without this uitableview doesn't receive touch in read modus. Also seems to be solved using 0.001 for scale down instead of 0...
        }

        
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
    
    private func onSectionSuggestionSelected(sectionSuggestion:String) {
        self.addItemView.sectionText = sectionSuggestion
        self.sectionAutosuggestionsViewController.view.hidden = true
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        clearThings()
    }

    
    private func hideKeyboard() {
        self.addItemView.resignFirstResponder()
    }
    
    func clearThings() {
        self.hideKeyboard()
        
        self.sectionAutosuggestionsViewController.view.hidden = true
        
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    func onListItemClear(tableViewListItem:TableViewListItem) {
        self.setItemDone(tableViewListItem.listItem)
    }

//    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
//        return UIBarPosition.TopAttached
//    }
    
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return UIStatusBarStyle.LightContent
//    }

    private func getTableViewInset() -> CGFloat {
        let addItemViewHeight = CGRectGetHeight(self.addItemView.frame)
        let navbarHeight = self.navigationController!.navigationBar.frame.height
        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)

        return addItemViewHeight + navbarHeight + statusBarHeight
    }
    
//    func scrollViewDidScroll(scrollView: UIScrollView) {
//        println(scrollView.contentOffset.y)
//
//        var frame1 = self.inputBar.frame
//        frame1.origin = CGPointMake(frame1.origin.x, -scrollView.contentOffset.y)
//        self.inputBar.frame = frame1;
//
//        var frame2 = self.productDetailsContainer.frame
//        frame2.origin = CGPointMake(frame2.origin.x, -scrollView.contentOffset.y + frame2.size.height)
//        self.productDetailsContainer.frame = frame2;
//        
////        var frame3 = self.shopStatusContainer.frame
////        frame3.origin = CGPointMake(frame3.origin.x, -scrollView.contentOffset.y + frame3.size.height)
////        self.shopStatusContainer.frame = frame3;
//        
//        if self.lastContentOffset < scrollView.contentOffset.y {
//            println(scrollView.contentOffset.y)
//
//        }
//
//        self.lastContentOffset = scrollView.contentOffset.y
//
//    }


    func loadItems(handler: Try<[String]> -> ()) {
        
        self.listItemsProvider.products(successHandler{products in
            let names = products.map{$0.name}
            handler(Try(names))
        })
    }
    
    func onListItemsChangedSection(tableViewListItems: [TableViewListItem]) {
        self.listItemsProvider.update(tableViewListItems.map{$0.listItem}, successHandler{result in
        })
    }
    
    func updatePrices() {

        func calculatePrice(listItems:[ListItem]) -> Float {
            return listItems.reduce(0, combine: {(price:Float, listItem:ListItem) -> Float in
                return price + (listItem.product.price * Float(listItem.quantity))
            })
        }
        
        if let currentList = self.currentList {
            self.listItemsProvider.listItems(currentList, successHandler{listItems in
                    
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
    
    private func setItemDone(listItem: ListItem) {
        listItem.done = true

        self.listItemsProvider.update(listItem, {[weak self] `try` in
            
            if `try`.success ?? false {
                self!.listItemsTableViewController.removeListItem(listItem, animation: UITableViewRowAnimation.Bottom)
                
                self!.updatePrices()
            }
        })
    }
    
    private func addItem(listItemInput: ListItemInput) {

        if let currentList = self.currentList {
            
            self.progressVisible(true)
            self.listItemsProvider.add(listItemInput, list: currentList, order: nil, successHandler {savedListItem in
                    
                self.listItemsTableViewController.addListItem(savedListItem)
                
                self.addItemView.resignFirstResponder()
                self.updatePrices()
            })
            
        } else {
            print("Error: Invalid state: trying to add item without current list")
        }

    }
    
    func updateItem(listItem: ListItem, listItemInput:ListItemInput) {
        if let currentList = self.currentList {
            
            let product = Product(uuid: self.updatingListItem!.product.uuid, name: listItemInput.name, price: listItemInput.price)
            let section = Section(uuid: NSUUID().UUIDString, name: listItemInput.section)
        
            let listItem = ListItem(uuid: self.updatingListItem!.uuid, done: self.updatingListItem!.done, quantity: listItemInput.quantity, product: product, section: section, list: currentList, order: self.updatingListItem!.order)
            
            self.listItemsProvider.update(listItem, successHandler{
                    
                self.listItemsTableViewController.updateListItem(listItem)
                
                self.addItemView.resignFirstResponder()
                self.updatePrices()
            })
            
        } else {
            print("Error: Invalid state: trying to update list item without current list")
        }

    }
    
    func onListItemSelected(tableViewListItem: TableViewListItem) {
        if self.editing {
            self.updatingListItem = tableViewListItem.listItem
            self.addItemView.setUpdateItem(tableViewListItem.listItem)
        }
    }
    
    func onListItemDeleted(tableViewListItem: TableViewListItem) {
        self.listItemsProvider.remove(tableViewListItem.listItem, successHandler{
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "doneViewControllerSegue" {
            if let doneViewController = segue.destinationViewController as? DoneViewController {
                doneViewController.list = self.currentList
            }
        }
    }
}

