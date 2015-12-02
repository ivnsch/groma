//
//  ListsViewController.swift
//  shoppin
//
//  Created by ischuetz on 20/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol Foo { // TODO is this used?
    func setExpanded(expanded: Bool)
}

class ListsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddEditListControllerDelegate, ExpandCellAnimatorDelegate, Foo {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topBar: UINavigationBar!
    @IBOutlet weak var topBarConstraint: NSLayoutConstraint!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIBarButtonItem!
    private weak var editButton: UIBarButtonItem!
    
    private let listItemsProvider = ProviderFactory().listItemProvider

    private var lists: [List] = []
    
    private let expandCellAnimator = ExpandCellAnimator()
    
    private var originalNavBarFrame: CGRect = CGRectZero
    
    @IBOutlet weak var floatingViews: FloatingViews!

    private var topAddEditListControllerManager: ExpandableTopViewController<AddEditListController>?

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
        
        topAddEditListControllerManager = initTopAddEditListControllerManager()
    }

    private func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditListController> {
        let top = CGRectGetHeight(topBar.frame)
        return ExpandableTopViewController(top: top, height: 250, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditList()
            controller.delegate = self
            controller.currentListsCount = self!.lists.count
            controller.view.clipsToBounds = true
            return controller
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initLists()
    }
    
    private func initLists() {
        Providers.listProvider.lists(successHandler{lists in
            if self.lists != lists { // if current list is nil or the provider list is different
                self.lists = lists
                self.tableView.reloadData()
            }
        })
    }
    
    private func initNavBarRightButtons(actions: [UIBarButtonSystemItem]) {
        navigationItem.title = "Manage products"
        
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
        topAddEditListControllerManager?.controller?.submit()
    }
    
    func onCancelTap(sender: UIBarButtonItem) {
        topAddEditListControllerManager?.expand(false)
        initNavBarRightButtons([.Add])
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lists.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("listCell", forIndexPath: indexPath) as! ListTableViewCell
    
        let list = lists[indexPath.row]
        cell.list = list
        
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
            Providers.listProvider.remove(list, resultHandler(onSuccess: {
                }, onError: {[weak self] result in
                    self?.initLists()
                    self?.defaultErrorHandler()(providerResult: result)
                }
            ))
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
        let list = lists[fromIndexPath.row]
        lists.removeAtIndex(fromIndexPath.row)
        lists.insert(list, atIndex: toIndexPath.row)
        
        let updatedLists = self.lists.mapEnumerate{index, list in list.copy(order: index)}
        
        Providers.listProvider.update(updatedLists, successHandler{[weak self] in
            self?.lists = lists
        })
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let segueName = segue.identifier
        if segueName == "showListItemsController" {
            if let indexPath = self.tableView.indexPathForSelectedRow, listItemsController = segue.destinationViewController as? ViewController {
                let list = lists[indexPath.row] // having this outside of the onViewWillAppear appears to have fixed an inexplicable bad access in the currentList assignement line
                listItemsController.onViewWillAppear = { // FIXME crash here once when tapped on "edit"
                    listItemsController.currentList = list
                }
            }
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let list = self.lists[indexPath.row]

        if self.editing {
            topAddEditListControllerManager?.controller?.listToEdit = list
            topAddEditListControllerManager?.expand(true)
            
        } else {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {

                let listItemsController = UIStoryboard.todoItemsViewController()
                listItemsController.view.frame = view.frame
                addChildViewController(listItemsController)
                listItemsController.expandDelegate = self
                listItemsController.view.clipsToBounds = true
                
                listItemsController.onViewWillAppear = { // FIXME crash here once when tapped on "edit"
                    listItemsController.setThemeColor(cell.backgroundColor!)
                    listItemsController.currentList = list
                    listItemsController.onExpand(true)
                }

                let f = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.width, cell.frame.height)
                
                expandCellAnimator.reset()
                expandCellAnimator.collapsedFrame = f
                expandCellAnimator.delegate = self
                expandCellAnimator.fromView = tableView
                expandCellAnimator.toView = listItemsController.view
                expandCellAnimator.inView = view

                expandCellAnimator.animateTransition(true, topOffsetY: 64)
                
            } else {
                print("Warn: no cell for indexPath: \(indexPath)")
            }
        }
    }

    @IBAction func onAddTap(sender: UIBarButtonItem) {
        topAddEditListControllerManager?.expand(!(topAddEditListControllerManager?.expanded ?? true)) // toggle - if for some reason variable isn't set, set expanded false (!true)
        initNavBarRightButtons([.Save])
    }
    
    @IBAction func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true, tryCloseTopViewController: true)
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
                topAddEditListControllerManager?.expand(false)
            }
        }
        
        tableView.setEditing(editing, animated: animated)
        
        if editing {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }
    
    
    // MARK: - EditListViewController
    
    func onListAdded(list: List) {
        tableView.wrapUpdates {[weak self] in
            if let weakSelf = self {
                self?.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: weakSelf.lists.count, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
                self?.lists.append(list)
                self?.topAddEditListControllerManager?.expand(false)
                self?.initNavBarRightButtons([.Add])
            }
        }
    }
    
    
    func onListUpdated(list: List) {
        lists.update(list)
        tableView.reloadData()
        topAddEditListControllerManager?.expand(false)
    }
    
    // MARK: - ExpandCellAnimatorDelegate
    
    func animationsForCellAnimator(isExpanding: Bool, frontView: UIView) {
        var navBarFrame = topBar.frame
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
}