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

class ListsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddEditListControllerDelegate, ExpandCellAnimatorDelegate, Foo, BottonPanelViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var topBarConstraint: NSLayoutConstraint!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    private let listItemsProvider = ProviderFactory().listItemProvider

    private var lists: [List] = []
    
    private let expandCellAnimator = ExpandCellAnimator()
    
    private var originalNavBarFrame: CGRect = CGRectZero
    
    @IBOutlet weak var floatingViews: FloatingViews!

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
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initFloatingViews()
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
            addEditListController.listToEdit = list
            setAddEditListControllerOpen(true)
            
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
    
//    private func createAddOrEditListViewController(isEdit: Bool, listToEdit: List? = nil) -> EditListViewController {
//        let editListViewController = UIStoryboard.editListsViewController()
//        editListViewController.isEdit = isEdit
//        if let listToEdit = listToEdit {
//            editListViewController.listToEdit = listToEdit
//        }
//        editListViewController.delegate = self
//        return editListViewController
//    }
    
//    private func showAddOrEditListViewController(isEdit: Bool, listToEdit: List? = nil) {
//        let editListViewController = createAddOrEditListViewController(isEdit, listToEdit: listToEdit)
//        presentViewController(editListViewController, animated: true, completion: nil)
//    }

    @IBAction func onAddTap(sender: UIBarButtonItem) {
        setAddEditListControllerOpen(!addEditListController.open)
    }
    
    @IBAction func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true, tryCloseTopViewController: true)
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing == false {
            view.endEditing(true)
        }
        
        if tryCloseTopViewController {
            if !editing {
                if addEditListController.open {
                    setAddEditListControllerOpen(false)
                }
            }
        }
        
//        floatingViews.setActions([editing ? toggleButtonAvailableAction : toggleButtonInactiveAction]) // remove possible top controller specific action buttons (e.g. on list item update we have a submit button), and set appropiate alpha
        
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
                self?.setAddEditListControllerOpen(false)
            }
        }
    }
    
    
    func onListUpdated(list: List) {
        lists.update(list)
        tableView.reloadData()
        setAddEditListControllerOpen(false)
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
    
    
    private func initFloatingViews() {
        floatingViews.setActions(Array<FLoatingButtonAction>())
        floatingViews.delegate = self
    }
    
    // MARK: - Add edit list 
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    private var currentTopController: UIViewController?

    
    private func initTopController(controller: UIViewController, height: CGFloat) {
        let view = controller.view
        
        view.frame = CGRectMake(0, CGRectGetHeight(topBar.frame), self.view.frame.width, height)
        
        // swift anchor
        view.layer.anchorPoint = CGPointMake(0.5, 0)
        view.frame.origin = CGPointMake(0, view.frame.origin.y - height / 2)
        
        let transform: CGAffineTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 0.001) //0.001 seems to be necessary for scale down animation to be visible, with 0 the view just disappears
        view.transform = transform
    }
    
    private lazy var addEditListController: AddEditListController = {
        let controller = UIStoryboard.addEditList()
        controller.delegate = self
        controller.currentListsCount = self.lists.count
        controller.view.clipsToBounds = true
        self.initTopController(controller, height: 90)
        return controller
    }()
    
    private func setAddEditListControllerOpen(open: Bool) {
        addEditListController.open = open
        
        if open {
            floatingViews.setActions([FLoatingButtonAttributedAction(action: .Submit)])
        } else {
            floatingViews.setActions(Array<FLoatingButtonAction>())
            addEditListController.clear()
        }
        
        animateTopView(addEditListController, open: open, tableView: tableView)
    }
    
    
    // parameter: tableView: This is normally the listitem's table view, except when we are in section-only mode, which needs a different table view
    private func animateTopView(controller: UIViewController, open: Bool, tableView: UITableView) {
        let view = controller.view
        if open {
            self.addChildViewControllerAndView(controller)
            let topInset = CGRectGetHeight(view.bounds)
            tableViewOverlay.frame = CGRectMake(tableView.frame.origin.x, tableView.frame.origin.y + topInset, tableView.frame.width, tableView.frame.height - tableView.topInset)
            self.view.insertSubview(tableViewOverlay, aboveSubview: tableView)
//            self.view.bringSubviewToFront(floatingViews)
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
            
            let topInset = CGRectGetHeight(view.frame)
            
            let bottomInset = self.navigationController?.tabBarController?.tabBar.frame.height
            tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset!, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
            tableView.topOffset = -tableView.inset.top
            
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
        if addEditListController.open {
            setAddEditListControllerOpen(false)
        }
    }
    
    // MARK: - BottonPanelViewDelegate
    
    func onSubmitAction(action: FLoatingButtonAction) {
        handleFloatingViewAction(action)
    }
    
    private func handleFloatingViewAction(action: FLoatingButtonAction) {
        switch action {
        case .Submit:
            addEditListController.submit()
        default: break
        }
    }
}