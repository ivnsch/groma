//
//  ViewController.swift
//  shoppin
//
//  Created by ischuetz on 06.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate
//    , UIBarPositioningDelegate
{
//    @IBOutlet weak var tableView: UITableView!
    
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller

    private var addModus:Bool = true

    
    //TODO put in new view
    @IBOutlet weak var productDetailsContainer: UIView!
    @IBOutlet weak var inputBar: UIView!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var addSectionContainer: UIView!

    
    @IBOutlet weak var plusButton: UIButton!
    
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var quantityInput: UITextField!
    
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var donePriceLabel: UILabel!
    @IBOutlet weak var shopStatusContainer: UIView!

    private var shopStatusContainerTopConstraint:NSLayoutConstraint?
    
    @IBOutlet weak var sectionInput: UITextField!
    lazy var sectionAutosuggestionsViewController:AutosuggestionsTableViewController = {
        
        let sectionFrame = self.sectionInput.frame
        let originAbsolute = self.sectionInput.superview!.convertPoint(sectionFrame.origin, toView: self.view)
        let frame = CGRectMake(originAbsolute.x, originAbsolute.y + sectionFrame.size.height, sectionFrame.size.width, 0)
        
        let viewController = AutosuggestionsTableViewController(frame: frame, onSuggestionSelected: { (suggestion:String) -> () in
            self.onSectionSuggestionSelected(suggestion)
        })
        
        self.addChildViewControllerAndView(viewController)
        
        return viewController
    }()
    
    
    private let listItemsProvider = ProviderFactory().listItemProvider
  
    private var listItemsTableViewController:ListItemsTableViewController!
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let items = listItemsProvider.listItems()
        
        self.initTableViewController()
        self.listItemsTableViewController.setListItems(items)
        
        self.resetProductInputs()
        self.updatePrices()
        
        let menuExpanded = true
        self.setAddModus(menuExpanded)
        //TODO in view controller or table view controller?
//        self.tableView.contentOffset = CGPointMake(0, -getTableViewInset(menuExpanded))
        self.listItemsTableViewController.tableViewTopOffset = -getTableViewInset(menuExpanded)
   
        self.priceInput.keyboardType = UIKeyboardType.DecimalPad
        self.quantityInput.keyboardType = UIKeyboardType.DecimalPad
        
        inputField.placeholder = "Item name"
        sectionInput.placeholder = "Section (optional)"
        
        self.addBlurToView(inputBar)
        self.addBlurToView(productDetailsContainer)
        self.addBlurToView(addSectionContainer)
        self.addBlurToView(shopStatusContainer)
        
        self.sectionInput.delegate = self
        self.sectionInput.addTarget(self, action: "sectionInputFieldChanged:", forControlEvents: UIControlEvents.EditingChanged)
        sectionInput.delegate = self
    }
    
    private func initTableViewController() {
        self.listItemsTableViewController = UIStoryboard.doneItemsViewController()
        
        self.addChildViewControllerAndView(self.listItemsTableViewController, viewIndex: 0)
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "hideKeyboard")
        self.listItemsTableViewController.view.addGestureRecognizer(gestureRecognizer)
        self.listItemsTableViewController.scrollViewDelegate = self
        self.listItemsTableViewController.listItemsTableViewDelegate = self
    }
    
    private func onSectionSuggestionSelected(sectionSuggestion:String) {
        self.sectionInput.text = sectionSuggestion
        self.sectionAutosuggestionsViewController.view.hidden = true
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        hideKeyboard()
    }
    
    func hideKeyboard() {
        inputField.resignFirstResponder()
        priceInput.resignFirstResponder()
        quantityInput.resignFirstResponder()
        sectionInput.resignFirstResponder()
        
        self.sectionAutosuggestionsViewController.view.hidden = true
    }
    
    func handleTapGesture(sender:UITapGestureRecognizer) {
//        let tapLocation = sender.locationInView(self.tableView)
//        let indexPathMaybe:NSIndexPath? = self.tableView.indexPathForRowAtPoint(tapLocation)
//        
//        if let indexPath = indexPathMaybe {
//            self.toggleItemDone(self.tableViewSections[indexPath.section].listItems[indexPath.row])
//        }
    }

    func sectionInputFieldChanged(textField:UITextField) {
        println(textField.text)

        sectionAutosuggestionsViewController.options = self.listItemsProvider.sections().map{$0.name ?? ""} //TODO make this async or add a memory cache
        sectionAutosuggestionsViewController.searchText(textField.text)

        sectionAutosuggestionsViewController.view.hidden = textField.text.isEmpty
    }
    
    //TODO this depends if its for the todo or done tableview change signature/parameters/functionality
    func getTableViewInset(topPanelExpanded:Bool) -> CGFloat {
        var inset:CGFloat = CGRectGetHeight(shopStatusContainer.frame)
        if topPanelExpanded {
            inset += (CGRectGetHeight(inputBar.frame)
                + CGRectGetHeight(productDetailsContainer.frame)
                + CGRectGetHeight(addSectionContainer.frame)
            )
        } else {
            inset += CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
        }
        return inset
    }
    
    func onListItemDoubleTap(listItem: ListItem) {
        self.toggleItemDone(listItem)
    }

    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch: AnyObject? = event.allTouches()?.anyObject()
        if inputField.isFirstResponder() && touch?.view != inputField {
            inputField.resignFirstResponder()
        }
        if priceInput.isFirstResponder() && touch?.view != priceInput {
            priceInput.resignFirstResponder()
        }
        if quantityInput.isFirstResponder() && touch?.view != quantityInput {
            quantityInput.resignFirstResponder()
        }
        super.touchesBegan(touches, withEvent: event)
    }
    
//    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
//        return UIBarPosition.TopAttached
//    }
    
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return UIStatusBarStyle.LightContent
//    }

    func createBlurView() -> UIView {
        var blurView:UIView
        
        if NSClassFromString("UIBlurEffect") != nil {
            let blurEffect:UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)
            blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = view.frame
        } else {
            blurView = UIToolbar(frame: self.inputBar.bounds)
        }
        
        return blurView
    }
    
    func addBlurToView(view:UIView) {
        let blurView = createBlurView()
        
        blurView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let views:Dictionary = ["blurView": blurView]
        
        view.insertSubview(blurView, atIndex: 0)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[blurView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[blurView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: views))
    }

    
    @IBAction func quantityEditBegin(sender: AnyObject) {
        self.quantityInput.text = ""
    }
    

    
    @IBAction func onPlusTap(sender: AnyObject) {
        setAddModus(!self.addModus)
    }

    
    func setAddModus(addModus:Bool) {
        self.addModus = addModus
        
        self.inputBar.hidden = !addModus
        self.productDetailsContainer.hidden = !addModus
        self.addSectionContainer.hidden = !addModus
        
        self.plusButton.setTitle(self.addModus ? "-" : "+", forState: UIControlState.Normal)
        
        if let topConstraint = shopStatusContainerTopConstraint {
            self.view.removeConstraint(topConstraint)
        }
        
        if (self.addModus) {
            
            // FIXME hack... why not at bottom
            let constant =
                CGRectGetHeight(self.inputBar.frame)
                + CGRectGetHeight(self.productDetailsContainer.frame)
                + CGRectGetHeight(self.addSectionContainer.frame)
            
//            self.shopStatusContainerTopConstraint = NSLayoutConstraint(
//                item: self.shopStatusContainer,
//                attribute: NSLayoutAttribute.Top,
//                relatedBy: NSLayoutRelation.Equal,
//                toItem: self.productDetailsContainer,
//                attribute: NSLayoutAttribute.Bottom,
//                multiplier: 0,
//                constant: 0)
            self.shopStatusContainerTopConstraint = NSLayoutConstraint(
                item: self.shopStatusContainer,
                attribute: NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.view,
                attribute: NSLayoutAttribute.Top,
                multiplier: 0,
                constant: constant)
            
            
        } else {
            
//            let frame = self.shopStatusContainer.frame
//            let newH = frame.size.height * 1.4
//            self.shopStatusContainer.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, newH)
//            
//            self.shopStatusContainer.addConstraint(NSLayoutConstraint(
//                item: self.shopStatusContainer,
//                attribute: NSLayoutAttribute.Height,
//                relatedBy: NSLayoutRelation.Equal,
//                toItem: nil,
//                attribute: NSLayoutAttribute.NotAnAttribute,
//                multiplier: 0,
//                constant: newH))
  
            
            let constant:CGFloat =
                CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
            
            self.shopStatusContainerTopConstraint = NSLayoutConstraint(
                item: self.shopStatusContainer,
                attribute: NSLayoutAttribute.Top,
                relatedBy: NSLayoutRelation.Equal,
                toItem: self.view,
                attribute: NSLayoutAttribute.Top,
                multiplier: 0,
                constant: constant)
            
        }
        self.view.addConstraint(self.shopStatusContainerTopConstraint!)
        
        self.listItemsTableViewController.tableViewTopInset = getTableViewInset(self.addModus)
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
    
    
    @IBAction func onAddTap(sender: AnyObject) {
        let text = inputField.text
        let priceText = priceInput.text
        let quantityText = quantityInput.text
        let sectionText = sectionInput.text
        
        var price:Float = priceText.floatValue // TODO what happens if not a number? maybe use optional like toInt()?
        
        let quantity = quantityText.toInt() ?? 1
        let sectionName = sectionText ?? defaultSectionIdentifier
        
        if !text.isEmpty {
            self.addItem(text, price: price, quantity: quantity, sectionName:sectionName)
            self.view.endEditing(true)
            self.inputField.text = ""
            self.resetProductInputs()
        }
    }
    
    func resetProductInputs() {
        self.inputField.text = ""
        self.quantityInput.text = "1"
        self.priceInput.text = ""
    }

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

        let listItems = self.listItemsTableViewController.items
        
//        let allListItems = self.tableViewSections.map {
//            $0.listItems
//        }.reduce([], combine: +)
        
        let totalPrice:Float = listItems.reduce(0, combine: {(price:Float, listItem:ListItem) -> Float in
            return price + (listItem.product.price * Float(listItem.product.quantity))
        })
        
//        let totalPrice:Float = (doneSection.listItems + todoSection.listItems).reduce(0, combine: {(price:Float, listItem:ListItem) -> Float in
//            return price + (listItem.product.price * Float(listItem.product.quantity))
//        })
//        let donePrice:Float = doneSection.listItems.reduce(0, combine: {(price:Float, listItem:ListItem) -> Float in
//            return price + (listItem.product.price * Float(listItem.product.quantity))
//        })

        self.totalPriceLabel.text = NSNumber(float: totalPrice).stringValue + " €"
//        self.donePriceLabel.text = NSNumber(float: donePrice).stringValue + " €"
    }
    
    func toggleItemDone(listItem:ListItem) {
        //TODO... again
//        let (srcSection, dstSection) = listItem.done ? (self.doneSection, self.todoSection) : (self.todoSection, self.doneSection)
//        
//        listItem.done = !listItem.done
//        
//        var index = -1
//        for i in 0...srcSection.listItems.count {
//            if srcSection.listItems[i] == listItem {
//                index = i
//                break
//            }
//        }
//        srcSection.listItems.removeAtIndex(index)
//        dstSection.addItem(listItem)
//        self.tableView.reloadData()
//        
//        self.updatePrices()
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
        let listItem = ListItem(done: false, product: product, section: section)
        
        if self.listItemsProvider.add(listItem) {
            self.listItemsTableViewController.addListItem(listItem)
        }
        
        self.sectionInput.resignFirstResponder()
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

