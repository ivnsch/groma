//
//  ListsViewController.swift
//  shoppin
//
//  Created by ischuetz on 20/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol Foo {
    func setExpanded(expanded: Bool)
}

class ListsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, EditListViewControllerDelegate, ExpandCellAnimatorDelegate, Foo {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var topBarConstraint: NSLayoutConstraint!

    
    private let listItemsProvider = ProviderFactory().listItemProvider

    private var lists: [List] = []
    
    private let expandCellAnimator = ExpandCellAnimator()
    
    private var originalNavBarFrame: CGRect = CGRectZero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelectionDuringEditing = true
        
        originalNavBarFrame = topBar.frame
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.listItemsProvider.lists(successHandler{lists in
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
        cell.listName.text = list.name
        
        let c = list.bgColor
        cell.contentView.backgroundColor = c
        cell.backgroundColor = c
        let v = UIView()
        v.backgroundColor = c
        cell.selectedBackgroundView = v
        
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
        // Delete the row from the data source
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

    // Override to support rearranging the table view.
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
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
        if self.editing {            
//            if let indexPath = self.tableView.indexPathForSelectedRow, lists = self.lists {
            self.showAddOrEditListViewController(true, listToEdit: lists[indexPath.row])
            
        } else {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {


//                let listItemsController = UIStoryboard.hiho()
                
                let listItemsController = UIStoryboard.todoItemsViewController()
                listItemsController.view.frame = view.frame
                addChildViewController(listItemsController)
                listItemsController.expandDelegate = self
                listItemsController.view.clipsToBounds = true
                
                listItemsController.onViewWillAppear = { // FIXME crash here once when tapped on "edit"
                    listItemsController.setThemeColor(cell.backgroundColor!)
                    if let indexPath = self.tableView.indexPathForSelectedRow {
                        let list = self.lists[indexPath.row] // having this outside of the onViewWillAppear appears to have fixed an inexplicable bad access in the currentList assignement line
                        listItemsController.currentList = list
                        listItemsController.onExpand(true)
                    }
                }

                let f = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.width, cell.frame.height)
                
                expandCellAnimator.reset()
                expandCellAnimator.collapsedFrame = f
                expandCellAnimator.delegate = self
                expandCellAnimator.fromView = tableView
                expandCellAnimator.toView = listItemsController.view
                expandCellAnimator.inView = view
                
                
//                expandCellAnimator.animateTransition(true, fromViewYOffset: 60, expandedViewFrame: nil)
                expandCellAnimator.animateTransition(true, topOffsetY: 60)
                
            } else {
                print("Warn: no cell for indexPath: \(indexPath)")
            }
        }
    }
    
    private func createAddOrEditListViewController(isEdit: Bool, listToEdit: List? = nil) -> EditListViewController {
        let editListViewController = UIStoryboard.editListsViewController()
        editListViewController.isEdit = isEdit
        if let listToEdit = listToEdit {
            editListViewController.listToEdit = listToEdit
        }
        editListViewController.delegate = self
        return editListViewController
    }
    
    private func showAddOrEditListViewController(isEdit: Bool, listToEdit: List? = nil) {
        let editListViewController = createAddOrEditListViewController(isEdit, listToEdit: listToEdit)
        presentViewController(editListViewController, animated: true, completion: nil)
    }

    @IBAction func onAddTap(sender: UIBarButtonItem) {
        self.showAddOrEditListViewController(false)
    }
    
    @IBAction func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true) 
    }
    
    
    // MARK: - EditListViewController
    
    func onListAdded(list: List) {
        tableView.wrapUpdates {[weak self] in
            
            if let weakSelf = self {
                self?.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: weakSelf.lists.count, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
                self?.lists.append(list)
                
                self?.dismissViewControllerAnimated(true) {
                }
            }
        }
    }
    
    
    func onListUpdated(list: List) {
        lists.update(list)
        tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - ExpandCellAnimatorDelegate
    
    func animationsForCellAnimator(isExpanding: Bool, frontView: UIView) {
//        if isExpanding {
//            var navBarFrame = self.navigationController!.navigationBar.frame
//            
//            
////            let newFrame = CGRectMake(0, -(navBarFrame.height), navBarFrame.width, navBarFrame.height)
//            let newFrame = CGRectMake(0, -(self.originalNavBarFrame.origin.y + navBarFrame.height), navBarFrame.width, navBarFrame.height)
//            
//            self.navigationController!.navigationBar.frame = newFrame
//            
//            // TODO
//            //                    c.myLab.center = CGPointMake(frontView.center.x, c.myLab.center.y)
//            
//            
//        } else {
//            var navBarFrame = self.navigationController!.navigationBar.frame
//            let newFrame = CGRectMake(0, self.originalNavBarFrame.origin.y, navBarFrame.width, navBarFrame.height)
//            self.navigationController!.navigationBar.frame = newFrame
//            
//            // delegate?.onExpandingAnim(false)
//            // self.toViewAnimationsAdapter?.animationsForCollapsingView?(frontView)
//        }
        
//        if isExpanding {
//            
//            var navBarFrame = topBar.frame
//
////            //            let newFrame = CGRectMake(0, -(navBarFrame.height), navBarFrame.width, navBarFrame.height)
////            let newFrame = CGRectMake(0, -(self.originalNavBarFrame.origin.y + navBarFrame.height), navBarFrame.width, navBarFrame.height)
////            
////            topBar.frame = newFrame
//            
//            topBarConstraint.constant = -navBarFrame.height
//            
//            // TODO
//            //                    c.myLab.center = CGPointMake(frontView.center.x, c.myLab.center.y)
//            
//            
//        } else {
////            var navBarFrame = topBar.frame
////            let newFrame = CGRectMake(0, self.originalNavBarFrame.origin.y, navBarFrame.width, navBarFrame.height)
////            topBar.frame = newFrame
//            
//            topBarConstraint.constant = 0
//
//            
//            // delegate?.onExpandingAnim(false)
//            // self.toViewAnimationsAdapter?.animationsForCollapsingView?(frontView)
//        }
        
        var navBarFrame = topBar.frame
        if isExpanding {
            topBar.transform = CGAffineTransformMakeTranslation(0, -navBarFrame.height)
        } else {
            topBar.transform = CGAffineTransformMakeTranslation(0, 0)
        }
    }
    
    
    func setExpanded(expanded: Bool) {
        expandCellAnimator.animateTransition(false, topOffsetY: 60)
    }
    
    func animationsComplete(wasExpanding: Bool, frontView: UIView) {


//        if wasExpanding {
//            navigationController?.setNavigationBarHidden(true, animated: false)
//        } else {
//            navigationController?.setNavigationBarHidden(false, animated: false)
//        }
    }
    
    func prepareAnimations(willExpand: Bool, frontView: UIView) {
//                    var navBarFrame = topBar.frame
//        if willExpand {
//            
//
//
//            topBar.transform = CGAffineTransformMakeTranslation(0, -navBarFrame.height)
//            
//            
////            topBarConstraint.constant = -navBarFrame.height
//            
//        } else {
////            topBarConstraint.constant = 0
//            topBar.transform = CGAffineTransformMakeTranslation(0, navBarFrame.height)
//            
//        }
//        view.updateConstraints()
//        view.layoutIfNeeded()
        
    }
}
