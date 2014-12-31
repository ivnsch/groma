//
//  ViewController.swift
//  shoppin
//
//  Created by ischuetz on 06.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, ItemsObserver, SideMenuObserver, AddItemViewDelegate, ListItemsEditTableViewDelegate
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
  
    private var listItemsTableViewController:ListItemsTableViewController!
    
    var itemsNotificator:ItemsNotificator!
    var sideMenuManager:SideMenuManager!

    @IBOutlet weak var pricesView:PriceNavigationView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    private var gestureRecognizer:UIGestureRecognizer!
    
    private var updatingListItem:ListItem?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableViewController()
        self.initItems()
        
        self.addItemView.delegate = self
        
        self.setEditing(false, animated: false)
        
        self.updatePrices()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        self.setAddItemViewAnchorPointTopCenter()
    }
    
    //prepare add item view for scale animation, which should be top to bottom
    private func setAddItemViewAnchorPointTopCenter() {
        let frame = self.addItemView.frame
        let topCenter = CGPointMake(CGRectGetMidX(frame), CGRectGetMinY(frame))
        
        self.addItemView.layer.anchorPoint = CGPointMake(0.5, 0)
        
        //        println("constraint height: \(self.addItemView.topConstraint.constant)")
        
        let navbarHeight = self.navigationController!.navigationBar.frame.height
        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
        
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
    
    // MARK: - AddItemViewDelegate

    func onAddTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String) {
        if !name.isEmpty {
            
            let (name_, price, quantity, sectionName_) = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, sectionName: sectionName)
        
            self.addItem(name_, price: price, quantity: quantity, sectionName:sectionName_)
            self.view.endEditing(true)
            self.addItemView.clearInputs()
        }
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String) {
        let (name_, price, quantity, sectionName_) = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, sectionName: sectionName)
        
        self.updateItem(self.updatingListItem!, itemName: name_, price: price, quantity: quantity, sectionName:sectionName_)
        self.view.endEditing(true)
        self.addItemView.clearInputs()
        
        self.updatingListItem = nil
    }
    
    private func processListItemInputs(name: String, priceText: String, quantityText: String, sectionName: String) -> (name:String, price:Float, quantity:Int, sectionName:String) {
        //TODO?
        //        if !price {
        //            price = 0
        //        }
        //        if !quantity {
        //            quantity = 0
        //        }
        
        var price:Float = priceText.floatValue // TODO what happens if not a number? maybe use optional like toInt()?
        
        let quantity = quantityText.toInt() ?? 1
        let sectionName = sectionName ?? defaultSectionIdentifier
        
        return (name, price, quantity, sectionName)
    }

    func onSectionInputChanged(text: String) {
        sectionAutosuggestionsViewController.options = self.listItemsProvider.sections().map{$0.name ?? ""} //TODO make this async or add a memory cache
        sectionAutosuggestionsViewController.searchText(text)
        
        sectionAutosuggestionsViewController.view.hidden = text.isEmpty
    }
    
    @IBAction func onEditTap(sender: AnyObject) {
        let editButton = sender as UIBarButtonItem
        let editing = !self.listItemsTableViewController.editing
        
        self.setEditing(editing, animated: true)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        self.listItemsTableViewController.setEditing(editing, animated: animated)
        self.gestureRecognizer.enabled = !editing //don't block tap on delete button
        self.sideMenuManager!.setGestureRecognizersEnabled(!editing) //don't block reordering rows

        self.addItemView.expanded = editing
        let animationTime:NSTimeInterval = animated ? 0.2 : 0

//        self.addItemView.hidden = false
        
        UIView.animateWithDuration(animationTime, animations: { () -> Void in
            let transform:CGAffineTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1, editing ? 1 : 0.001) //0.001 seems to be necessary for scale down animation to be visible, with 0 the view just disappears
            self.addItemView.transform = transform
            

            let navbarHeight = self.navigationController!.navigationBar.frame.height
            let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)

            self.listItemsTableViewController.tableViewTopInset = navbarHeight + statusBarHeight + CGRectGetHeight(self.addItemView.frame)
            self.listItemsTableViewController.tableViewTopOffset = -self.listItemsTableViewController.tableViewTopInset
            
        }) { p in
//            if !editing {self.addItemView.hidden = true} // without this uitableview doesn't receive touch in read modus. Also seems to be solved using 0.001 for scale down instead of 0...
        }

        
        if editing {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }
    
    func itemsChanged() {
        self.initItems()
    }
    
    func changedSlideOutState(slideOutState: SlideOutState) {
        switch slideOutState {
        case .Collapsed:
            listItemsTableViewController.touchEnabled(true)
        case .RightPanelExpanded, .LeftPanelExpanded:
            listItemsTableViewController.touchEnabled(false)
        }
    }
    
    func startSideMenuDrag() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    private func initItems() {
        let items = listItemsProvider.listItems().filter{!$0.done}
        self.listItemsTableViewController.setListItems(items)
    }
    
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


    func loadItems() -> [String] {
        return self.listItemsProvider.products().map {
//            (p) -> String in
//            return p.name
            
//            p in
//            return p.name
            
            $0.name
        }
    }
    
    func onListItemChangedSection(tableViewListItem: TableViewListItem) {
        self.listItemsProvider.update(tableViewListItem.listItem)
    }
    
    func updatePrices() {

        let listItems = self.listItemsProvider.listItems()

        func calculatePrice(listItems:[ListItem]) -> Float {
            return listItems.reduce(0, combine: {(price:Float, listItem:ListItem) -> Float in
                return price + (listItem.product.price * Float(listItem.quantity))
            })
        }
        
//        let allListItems = self.tableViewSections.map {
//            $0.listItems
//        }.reduce([], combine: +)
        
        let totalPrice:Float = calculatePrice(listItems)
        
        let doneListItems = listItems.filter{$0.done}
        let donePrice:Float = calculatePrice(doneListItems)

        self.pricesView.totalPrice = totalPrice
        self.pricesView.donePrice = donePrice
    }
    
    private func setItemDone(listItem:ListItem) {
        listItem.done = true

        self.listItemsProvider.update(listItem)
        self.listItemsTableViewController.removeListItem(listItem, animation: UITableViewRowAnimation.Bottom)
        
        self.updatePrices()
        
        itemsNotificator?.notifyItemUpdated(listItem, sender: self)
    }
    
    func addItem(itemName:String, price:Float, quantity:Int, sectionName:String) {
        // for now just create a new product and a listitem with it
        let product = Product(id: "dummy", name: itemName, price:price)
        let section = Section(name: sectionName)
        
        // we use for now core data object id as list item id. So before we insert the item there's no id and it's not used -> "dummy"
        let listItem = ListItem(id:"dummy", done: false, quantity: quantity, product: product, section: section)
        
        if let savedListItem = self.listItemsProvider.add(listItem) {
            self.listItemsTableViewController.addListItem(savedListItem)
        }
        
        self.addItemView.resignFirstResponder()
        self.updatePrices()
    }
    
    func updateItem(listItem: ListItem, itemName:String, price:Float, quantity:Int, sectionName:String) {
        let product = Product(id: self.updatingListItem!.product.id, name: itemName, price: price)
        let section = Section(name: sectionName)
        
        let listItem = ListItem(id: self.updatingListItem!.id, done: self.updatingListItem!.done, quantity: quantity, product: product, section: section)
        
        if self.listItemsProvider.update(listItem) {
            self.listItemsTableViewController.updateListItem(listItem)
        }
        
        self.addItemView.resignFirstResponder()
        self.updatePrices()
    }
    
    func onListItemSelected(tableViewListItem: TableViewListItem) {
        if self.editing {
            self.updatingListItem = tableViewListItem.listItem
            self.addItemView.setUpdateItem(tableViewListItem.listItem)
        }
    }
    
    func onListItemDeleted(tableViewListItem: TableViewListItem) {
        self.listItemsProvider.remove(tableViewListItem.listItem)
    }
}

