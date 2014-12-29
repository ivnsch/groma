//
//  ViewController.swift
//  shoppin
//
//  Created by ischuetz on 06.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, ItemsObserver, SideMenuObserver, AddItemViewDelegate
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
    
    var itemsNotificator:ItemsNotificator?
    var sideMenuManager:SideMenuManager?

    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableViewController()
        self.initItems()
        
        let inset = self.getTableViewInset()
        self.listItemsTableViewController.tableViewTopInset = inset
        self.listItemsTableViewController.tableViewTopOffset = -inset
        
        self.updatePrices()
        
        self.addItemView.delegate = self
    }
    
    // MARK: - AddItemViewDelegate

    func onAddTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String) {
        if !name.isEmpty {
            var price:Float = priceText.floatValue // TODO what happens if not a number? maybe use optional like toInt()?
            
            let quantity = quantityText.toInt() ?? 1
            let sectionName = sectionName ?? defaultSectionIdentifier
        
            self.addItem(name, price: price, quantity: quantity, sectionName:sectionName)
            self.view.endEditing(true)
            self.addItemView.clearInputs()
        }
    }

    func onSectionInputChanged(text: String) {
        sectionAutosuggestionsViewController.options = self.listItemsProvider.sections().map{$0.name ?? ""} //TODO make this async or add a memory cache
        sectionAutosuggestionsViewController.searchText(text)
        
        sectionAutosuggestionsViewController.view.hidden = text.isEmpty
    }
    
    func onDonePriceTap() {
        sideMenuManager?.setDoneItemsOpen(true)
    }
    
    
  
    func itemsChanged() {
        self.initItems()
    }
    
    func changedSlideOutState(slideOutState: SlideOutState) {
        switch slideOutState {
        case .Collapsed:
            listItemsTableViewController.touchEnabled(true)
        case .RightPanelExpanded:
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
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
    
    private func initTableViewController() {
        self.listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        
        self.addChildViewControllerAndView(self.listItemsTableViewController, viewIndex: 0)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "clearThings")
        self.listItemsTableViewController.view.addGestureRecognizer(gestureRecognizer)
        self.listItemsTableViewController.scrollViewDelegate = self
        self.listItemsTableViewController.listItemsTableViewDelegate = self
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
        return CGRectGetHeight(self.addItemView.frame)
    }
    
    func onAddItemViewExpanded(expanded: Bool) {
        self.listItemsTableViewController.tableViewTopInset = self.getTableViewInset()
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
    
    
    func updatePrices() {

        let listItems = self.listItemsProvider.listItems()

        func calculatePrice(listItems:[ListItem]) -> Float {
            return listItems.reduce(0, combine: {(price:Float, listItem:ListItem) -> Float in
                return price + (listItem.product.price * Float(listItem.product.quantity))
            })
        }
        
//        let allListItems = self.tableViewSections.map {
//            $0.listItems
//        }.reduce([], combine: +)
        
        let totalPrice:Float = calculatePrice(listItems)
        
        let doneListItems = listItems.filter{$0.done}
        let donePrice:Float = calculatePrice(doneListItems)

        self.addItemView.totalPrice = totalPrice
        self.addItemView.donePrice = donePrice
    }
    
    private func setItemDone(listItem:ListItem) {
        listItem.done = true

        self.listItemsProvider.update(listItem)
        self.listItemsTableViewController.removeListItem(listItem, animation: UITableViewRowAnimation.Bottom)
        
        self.updatePrices()
        
        itemsNotificator?.notifyItemUpdated(listItem, sender: self)
    }
    
    func addItem(itemName:String, price:Float, quantity:Int, sectionName:String) {
//TODO?
//        if !price {
//            price = 0
//        }
//        if !quantity {
//            quantity = 0
//        }
        
        // for now just create a new product and a listitem with it
        let product = Product(name: itemName, price:price, quantity:quantity)
        let section = Section(name: sectionName)
        
        // we use for now core data object id as list item id. So before we insert the item there's no id and it's not used -> "dummy"
        let listItem = ListItem(id:"dummy", done: false, product: product, section: section)
        
        if let savedListItem = self.listItemsProvider.add(listItem) {
            self.listItemsTableViewController.addListItem(savedListItem)
        }
        
        self.addItemView.resignFirstResponder()
        self.updatePrices()
    }

    
//    func removeItem(indexPath:NSIndexPath) {
//        let listItem:ListItem = self.items[indexPath.row]
//        let product:Product = listItem.product
//        
//        let removedPersisted = self.listItemsProvider.remove(listItem)
//        if (removedPersisted) {
//            self.items.removeAtIndex(indexPath.row)
//            
//            self.productsTableView.beginUpdates()
//            self.productsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
//            self.productsTableView.endUpdates()
//        }
//    }
}

