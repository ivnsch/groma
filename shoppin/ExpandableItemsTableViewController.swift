//
//  ExpandableItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 16/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

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


class ExpandableItemsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ExpandCellAnimatorDelegate, Foo {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topBar: UINavigationBar!
    @IBOutlet weak var topBarConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIBarButtonItem!
    private weak var editButton: UIBarButtonItem!
    
    private let listItemsProvider = ProviderFactory().listItemProvider
    
    private var lists: [List] = []
    var models: [ExpandableTableViewModel] = []
    
    private let expandCellAnimator = ExpandCellAnimator()
    
    private var originalNavBarFrame: CGRect = CGRectZero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelectionDuringEditing = true
        
        originalNavBarFrame = topBar.frame
        
        topBar.backgroundColor = Theme.navigationBarBackgroundColor
        //        titleLabel.textColor = Theme.navigationBarTextColor
        //        addButton.setTitleColor(Theme.navigationBarTextColor, forState: .Normal)
        //        editButton.setTitleColor(Theme.navigationBarTextColor, forState: .Normal)
        view.backgroundColor = Theme.mainViewsBGColor
        tableView.backgroundColor = Theme.mainViewsBGColor
        
        // adding a new nav item, because code was written when topbar was a custom view, after adding nav controller and using it's item expanding list once makes navbar disappear, don't have time to investigate now
        let navItem = UINavigationItem(title: "Test")
        topBar.items = [navItem]
        let editButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "onEditTap:")
        topBar.items?.first?.leftBarButtonItems = [editButton]
        self.editButton = editButton
        
        initNavBarRightButtons([.Add])
    }
    
    private func initTopAddEditListControllerManager() -> ExpandableTopViewController<UIViewController> {
        fatalError("override")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initModels()
    }
    
    func initModels() {
        fatalError("override")
    }
    
    private func initNavBarRightButtons(actions: [UIBarButtonSystemItem]) {
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .Add:
                let button = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "onAddTap:")
                self.addButton = button
                buttons.append(button)
            case .Save:
                let button = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "onSubmitTap:")
                buttons.append(button)
            case .Cancel:
                let button = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "onCancelTap:")
                buttons.append(button)
            default: break
            }
        }
        
        topBar.items?.first?.rightBarButtonItems = buttons
    }
    
    func onSubmitTap(sender: UIBarButtonItem) {
        fatalError("override")
    }
    
    func onCancelTap(sender: UIBarButtonItem) {

        initNavBarRightButtons([.Add])
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
            
            let list = lists[indexPath.row]
            
            // update the table view in advance, so delete animation is quick. If something goes wrong we reload the content in onError and do default error handling
            tableView.wrapUpdates {[weak self] in
                self?.lists.remove(list)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
            }
            Providers.listProvider.remove(list, remote: true, resultHandler(onSuccess: {
                }, onError: {[weak self] result in
                    self?.initModels()
                    self?.defaultErrorHandler()(providerResult: result)
                }
            ))
        }
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
        fatalError("override")
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
    
    func onAddTap() {
        fatalError("Override")
    }
    
    @IBAction func onAddTap(sender: UIBarButtonItem) {
        initNavBarRightButtons([.Save])
        onAddTap()
    }
    
    @IBAction func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true, tryCloseTopViewController: true)
    }
    
    func closeTopViewController() {
        fatalError("override")
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            initNavBarRightButtons([.Save, .Cancel])
            
        } else {
            initNavBarRightButtons([.Add])
            view.endEditing(true)
        }
        
        if tryCloseTopViewController {
            if !editing {
                closeTopViewController()
            }
        }
        
        tableView.setEditing(editing, animated: animated)
        
        if editing {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
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
        if let index = models.remove(model) {
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Top)
        } else {
            print("Warn: ViewController.onWebsocketList: Removed list item was not found in tableView")
        }
    }
}