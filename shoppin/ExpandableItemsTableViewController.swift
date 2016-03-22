//
//  ExpandableItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 16/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class ExpandableTableViewModel: NSObject, Identifiable {

    var name: String {
        fatalError("override")
    }
    var bgColor: UIColor {
        fatalError("override")
    }
    var users: [SharedUser] {
        fatalError("override")
    }
    
    func same(rhs: ExpandableTableViewModel) -> Bool {
        fatalError("override")
    }
}

protocol Foo { // TODO rename, put in other file
    func setExpanded(expanded: Bool)
}

enum TopBarState {
    case Normal, NormalFromExpanded, EditTable, EditItem, Add, AddNoAnim
}


class ExpandableItemsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ExpandCellAnimatorDelegate, Foo, ListTopBarViewDelegate {
    
    @IBOutlet weak var topBar: ListTopBarView!
//    @IBOutlet weak var topBarConstraint: NSLayoutConstraint!
    
    private var titleLabel: UILabel?
    
    private weak var editButton: UIBarButtonItem!
    
    @IBOutlet weak var emptyView: UIView!

    private let listItemsProvider = ProviderFactory().listItemProvider
    
    private var addButton: UIButton? = nil

    var models: [ExpandableTableViewModel] = [] {
        didSet {
            emptyView.hidden = !models.isEmpty
            tableView.hidden = !emptyView.hidden
            if models != oldValue {
                tableView.reloadData()
            }
        }
    }
    
    
    private var tableViewController: UITableViewController! // initially there was only a tableview but pull to refresh control seems to work better with table view controller
    
    var tableView: UITableView {
        return tableViewController.tableView
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedTableViewController" {
            tableViewController = segue.destinationViewController as! UITableViewController
            tableViewController.tableView.dataSource = self
            tableViewController.tableView.delegate = self
        }
    }
    
    
    private let expandCellAnimator = ExpandCellAnimator()
    
    private var originalNavBarFrame: CGRect = CGRectZero
    
    private var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true

        let refreshControl = PullToAddHelper.createPullToAdd(self)
        tableViewController.refreshControl = refreshControl
        refreshControl.addTarget(self, action: "onPullRefresh:", forControlEvents: .ValueChanged)
        
        originalNavBarFrame = topBar.frame
        
        topBar.delegate = self
        
        initTopBar()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillAppear:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillDisappear:", name: UIKeyboardWillHideNotification, object: nil)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("onEmptyViewTap:"))
        emptyView.addGestureRecognizer(tapRecognizer)
    }
    
    // MARK: - Keyboard
    
    func keyboardWillAppear(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                keyboardHeight = keyboardSize.height
            } else {
                QL3("Couldn't retrieve keyboard size from user info")
            }
        } else {
            QL3("Notification has no user info")
        }
        
        delay(0.5) {[weak self] in // let the keyboard reach it's final position before showing the button
            self?.addButton?.hidden = false
        }
    }
    
    func keyboardWillDisappear(notification: NSNotification) {
        // when showing validation popup the keyboard disappears so we have to remove the button - otherwise it looks weird
        addButton?.hidden = true
    }

    // MARK: -
    
    func onExpandableClose() {
        delay(0.3) {[weak self] in
            if self?.addButton?.superview != nil {
                self?.addButton?.removeFromSuperview()
            }
            self?.addButton = nil
        }
    }
    
    // MARK: - Pull to add
    
    func onPullRefresh(sender: UIRefreshControl) {
        sender.endRefreshing()
        onPullToAdd()
    }

    func onPullToAdd() {
        // override
    }
    
    private func initTopBar() {
        topBar.delegate = self
        setTopBarState(.NormalFromExpanded)
    }
    
    private func initTitleLabel() {
        let label = UILabel()
        label.font = Fonts.regular
        label.textColor = UIColor.whiteColor()
        topBar.addSubview(label)
        titleLabel = label
    }
    
    
    func setNavTitle(title: String) {
        topBar.title = title
        topBar.positionTitleLabelLeft(true, animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initModels()
    }
    
    func initModels() {
        fatalError("override")
    }

    func setTopBarStateForAddTap(expand: Bool, rotateTopBarButtonOnExpand: Bool = true) {
        if expand {
            setTopBarState(rotateTopBarButtonOnExpand ? .Add : .AddNoAnim)
        } else {
            setTopBarState(.NormalFromExpanded)
        }
    }
    
    func setTopBarState(topBarState: TopBarState) {
        
        func leftEdit() {
            topBar.setLeftButtonIds([.Edit])
        }
        
        func rightSubmitAndClose() { // v x
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .Submit),
                TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
        }
        
        func rightClose() { // x
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
        }

        func rightOpen() { // +
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformIdentity)
            ])
        }
        
        // animated
        func rightOpenFromClosed() { // x -> +
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)
            ])
        }
        
        // animated
        func rightSubmitAndCloseFromOpen(animateToggle: Bool) { // + -> v x
            var models: [TopBarButtonModel] = [
                TopBarButtonModel(buttonId: .Submit)
            ]
            if animateToggle {
                models.append(TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformIdentity, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4))))
            } else {
//                models.append(TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4))))
            }
            
            topBar.setRightButtonModels(models)
//            
//            topBar.setRightButtonModels([
//                TopBarButtonModel(buttonId: .Submit),
//                TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformIdentity, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
//            ])
        }

        switch topBarState {
        case .Normal:
            leftEdit()
            rightOpen()
            
        case .NormalFromExpanded:
            leftEdit()
            rightOpenFromClosed()
            
        case .EditTable:
            leftEdit()
            rightOpen()
            
        case .EditItem:
            leftEdit()
            rightSubmitAndCloseFromOpen(true)

        case .Add:
            leftEdit()
            rightSubmitAndCloseFromOpen(true)
            
        case .AddNoAnim:
            leftEdit()
            rightSubmitAndCloseFromOpen(false)
        }
    }
    
    func onEmptyViewTap(sender: UITapGestureRecognizer) {
        onAddTap()
    }

    func onSubmitTap() {
        fatalError("override")
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.models.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("itemCell", forIndexPath: indexPath) as! ExpandableItemsTableViewCell
        
        let model = models[indexPath.row]
        cell.model = model
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            let model = models[indexPath.row]
            
            // update the table view in advance, so delete animation is quick. If something goes wrong we reload the content in onError and do default error handling
            tableView.wrapUpdates {[weak self] in
                self?.models.remove(model)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
            }
            
            onRemoveModel(model)
        }
    }
    
    func onRemoveModel(model: ExpandableTableViewModel) {
        fatalError("override")
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
        let list = models[fromIndexPath.row]
        models.removeAtIndex(fromIndexPath.row)
        models.insert(list, atIndex: toIndexPath.row)
        
        onReorderedModels()
    }

    func onReorderedModels() {
        fatalError("override")
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func initDetailController(cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        fatalError("override")
    }
    
    func onSelectCellInEditMode(model: ExpandableTableViewModel) {
        setTopBarState(.EditItem)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let model = self.models[indexPath.row]
        
        if self.editing {
            onSelectCellInEditMode(model)
            
        } else {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                
                let detailController = initDetailController(cell, model: model)
                
                let f = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.width, cell.frame.height)
                
                expandCellAnimator.reset()
                expandCellAnimator.collapsedFrame = f
                expandCellAnimator.delegate = self
                expandCellAnimator.fromView = tableView
                expandCellAnimator.toView = detailController.view
                expandCellAnimator.inView = view
                
                expandCellAnimator.animateTransition(true, topOffsetY: 64)
                
            } else {
                print("Warn: no cell for indexPath: \(indexPath)")
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(0, topBar: topBar, scrollView: scrollView)
    }
    
    private var keyboardHeight: CGFloat?
    func onAddTap(rotateTopBarButton: Bool = true) {
        
        if let addButton = addButton {
            self.addButton = nil
            delay(0.3) {
                addButton.removeFromSuperview()
            }
        } else {
            if let window = view.window {
                
                let keyboardHeight = self.keyboardHeight ?? {
                    QL4("Couldn't get keyboard height dynamically, returning hardcoded value")
                    return 216
                    }()
                let buttonHeight: CGFloat = 40
                
                delay(0.3) {[weak self] in
                    guard let weakSelf = self else {return}
                    
                    let addButton = AddItemButton(frame: CGRectMake(0, window.frame.height - keyboardHeight - buttonHeight, window.frame.width, buttonHeight))
                    weakSelf.addButton = addButton
                    weakSelf.view.addSubview(addButton)
                    weakSelf.view.bringSubviewToFront(addButton)
                    addButton.tapHandler = {[weak self] in
                        self?.onSubmitTap()
                    }
                }
                
            } else {
                QL3("No parent view for add button")
            }
        }

        
        
//        let addButton = AddItemButton(frame: CGRectMake(0, view.frame.height - keyboardHeight - buttonHeight, parentView.frame.width, buttonHeight))
//        self.addButton = addButton
//        view.addSubview(addButton)
//        view.bringSubviewToFront(addButton)
//        addButton.tapHandler = {[weak self] in guard let weakSelf = self else {return}
//            
//            if let addEditListItemViewController = weakSelf.showingController as? AddEditListItemViewController {
//                addEditListItemViewController.submit()
//            } else {
//                QL3("Tapped add button but showing controller is not add edit controller")
//            }
//        }
        
        
    }
    
    @IBAction func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true, tryCloseTopViewController: true)
    }
    
    func topControllerIsExpanded() -> Bool {
        fatalError("Override")
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        if !editing {
            view.endEditing(true)
        }
        
//        if tryCloseTopViewController {
//            if !editing && topControllerIsExpanded() {
////                setTopBarState(.NormalFromExpanded)
////                closeTopViewController()
//            }
//        }
        
        tableView.setEditing(editing, animated: animated)
    }
    
    // MARK: - ExpandCellAnimatorDelegate
    
    func animationsForCellAnimator(isExpanding: Bool, frontView: UIView) {
        let navBarFrame = topBar.frame
        if isExpanding {
            topBar.transform = CGAffineTransformMakeTranslation(0, -navBarFrame.height)
        } else {
            topBar.transform = CGAffineTransformMakeTranslation(0, 0)
        }
    }
    
    func setExpanded(expanded: Bool) {
        expandCellAnimator.animateTransition(false, topOffsetY: 64)
    }
    
    func animationsComplete(wasExpanding: Bool, frontView: UIView) {
    }
    
    func prepareAnimations(willExpand: Bool, frontView: UIView) {
    }
    
    func removeModel(model: ExpandableTableViewModel) {
        
        func remove() {
            if let index = models.remove(model) {
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Top)
            } else {
                print("Warn: ViewController.onWebsocketList: Removed list item was not found in tableView")
            }
        }
        
        tableView.wrapUpdates {
            remove()
        }
    }
    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
    }
    
    func onTopBarTitleTap() {
    }
    
    func onTopBarButtonTap(buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .Submit:
            onSubmitTap()
        case .ToggleOpen:
            onAddTap()
        case .Edit:
            let editing = !self.tableView.editing
            self.setEditing(editing, animated: true, tryCloseTopViewController: true)
        default:
            print("Warn: ExpandableItemsTableViewController.onTopBarButtonTap: Not handled buttonId: \(buttonId)")
            break;
        }
    }
    
    func onCenterTitleAnimComplete(center: Bool) {
        if center {
            setTopBarState(.Normal)
        }
    }
    
    func onExpand(expanding: Bool) {
    }
}