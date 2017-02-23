//
//  ListItemsTableViewControllerNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 30/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs
import RealmSwift

protocol ListItemsTableViewDelegateNew: class {
    func onListItemClear(_ tableViewListItem: ListItem, notifyRemote: Bool, onFinish: VoidFunction) // submit item marked as undo
    func onListItemSelected(_ tableViewListItem: ListItem, indexPath: IndexPath) // mark as undo
    func onListItemReset(_ tableViewListItem: ListItem) // revert undo
    func onSectionHeaderTap(_ header: ListItemsSectionHeaderView, section: ListItemsViewSection)
    func onIncrementItem(_ model: ListItem, delta: Float)
    func onTableViewScroll(_ scrollView: UIScrollView)
    func onPullToAdd()
    func showPopup(text: String, cell: UITableViewCell, button: UIView)
}

protocol ListItemsEditTableViewDelegateNew: class {
    func onListItemsOrderChangedSection(_ tableViewListItems: [ListItem])
    func onListItemDeleted(indexPath: IndexPath, tableViewListItem: ListItem)
    func onListItemMoved(from: IndexPath, to: IndexPath)
}

//protocol ItemActionsDelegateNew: class {
//    func startItemSwipe(_ tableViewListItem: ListItem)
//    func endItemSwipe(_ tableViewListItem: ListItem)
//    func undoSwipe(_ tableViewListItem: ListItem)
//    func onNoteTap(_ cell: ListItemCellNew, tableViewListItem: ListItem)
//    func onHeaderTap(_ header: ListItemsSectionHeaderView, section: Section)
//    func onMinusTap(_ tableViewListItem: ListItem)
//    func onPlusTap(_ tableViewListItem: ListItem)
//    func onPanQuantityUpdate(_ tableViewListItem: ListItem, newQuantity: Int)
//}

class ListItemsTableViewControllerNew: UITableViewController, ListItemCellDelegateNew {

    var sections: RealmSwift.List<Section>? {
        didSet {
            tableView.reloadData()
        }
    }
    
    weak var scrollViewDelegate: UIScrollViewDelegate?
    weak var listItemsTableViewDelegate: ListItemsTableViewDelegateNew?
    weak var listItemsEditTableViewDelegate: ListItemsEditTableViewDelegateNew?

    var status: ListItemStatus = .todo
    
    var sectionsExpanded: Bool = true

    var cellMode: ListItemCellMode = .note {
        didSet {

            if let cells = tableView.visibleCells as? [ListItemCellNew] {
                for cell in cells {
                    cell.mode = cellMode
                }
            } else {
                QL4("Invalid state, couldn't cast: \(tableView.visibleCells)")
            }
            
        }
    }
    
    var cellSwipeDirection: SwipeableCellDirection = .right

    fileprivate let cellIdentifier = ItemsListTableViewConstants.listItemCellIdentifier

    fileprivate var pullToAddView: MyRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initTableView()
    }
    
    fileprivate func initTableView() {
        // TODO!!!!!!!!!!!! still necessary?
//        self.tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        self.tableView.allowsSelectionDuringEditing = true
        
        tableView.backgroundColor = Theme.defaultTableViewBGColor
    }
    
    func enablePullToAdd() {
        let refreshControl = PullToAddHelper.createPullToAdd(self)
        refreshControl.addTarget(self, action: #selector(onPullRefresh(_:)), for: .valueChanged)
        self.refreshControl = refreshControl
        
        pullToAddView = refreshControl
    }
    
    func onPullRefresh(_ sender: UIRefreshControl) {
        sender.endRefreshing()
        listItemsTableViewDelegate?.onPullToAdd()
    }
    
    
    /**
     Sets pending item (mark as undo" if open and shows cell open state. Submits currently pending item if existent.
     parameter onFinish: After cell marked open and automatic update of possible second "undo" item (to "done").
     // TODO!!!! remove notify remote parameter, this is necessary anymore
     */
    func markOpen(_ open: Bool, indexPath: IndexPath, notifyRemote: Bool, onFinish: VoidFunction? = nil) {
        //TODO!!!!!!!!!!!!!!!!! new animation with green background and direct removal from table view. No undo. Rename method and adjust parameters
        
        // if let section = self.tableViewSections[safe: (indexPath as NSIndexPath).section], let tableViewListItem = section.tableViewListItems[safe: (indexPath as NSIndexPath).row] {
        //     // Note: order is important here! first show open at current index path, then remove possible pending (which can make indexPath invalid, thus later), then update pending variable with new item
        //     self.showCellOpen(open, indexPath: indexPath)
        //     self.clearPendingSwipeItemIfAny(notifyRemote) {
        //         self.swipedTableViewListItem = tableViewListItem
                 onFinish?()
        //     }
            
        // } else {
        //     QL3("markOpen: \(open), self not set or indexPath not found: \(indexPath)")
        // }
    }
    
    // MARK: - Scrolling

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
        
        //        let velocity = scrollView.panGestureRecognizer.velocityInView(scrollView.superview)
        //        let scrollingUp = (velocity.y < 0)
        
//        clearPendingSwipeItemIfAny(true) TODO!!!!!!!!!!!!!!!! necessary?
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pullToAddView?.updateForScrollOffset(offset: scrollView.contentOffset.y, startOffset: -130)
    }
    
//    TODO!!!!!!!!!!!!!!!! ?
//    func scrollToListItem(_ litsItem: ListItem) {
//        if let indexPath = getIndexPath(litsItem) {
//            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
//        } else {
//            QL2("Didn't find list item to scroll to")
//        }
//    }
    
    
    // MARK: - Table view data source / delegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isEditing
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let sectionObj = sections?[section] else {QL4("Invalid state: no section"); return nil}
        
        let view = Bundle.loadView("ListItemsSectionHeaderView", owner: self) as! ListItemsSectionHeaderView
        view.section = sectionObj
        view.backgroundColor = sectionObj.color
        view.nameLabel.textColor = UIColor(contrastingBlackOrWhiteColorOn: sectionObj.color, isFlat: true)
        //            view.nameLabel.textColor = headerFontColor
        //            view.nameLabel.font = headerFont
//        view.delegate = self // TODO!!!!!!!!!!!!!!!!!!! re enable
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return DimensionsManager.listItemsHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionsExpanded ? sections?[section].listItems.count ?? 0 : 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ListItemCellNew
        cell.showsReorderControl = true
        cell.direction = .right
        
        // When returning cell height programatically (which we need now in order to use different cell heights for different screen sizes), here it's still the height from the storyboard so we have to pass the offset for the line to eb draw at the bottom. Apparently there's no method where we get the cell with final height (did move to superview / window also still have the height from the storyboard)
        cell.contentView.addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.defaultCellHeight)
        
        guard let listItem = sections?[indexPath.section].listItems[indexPath.row] else {QL4("No listItem"); return cell}
        cell.setup(status, mode: cellMode, tableViewListItem: listItem, delegate: self)
        cell.startStriked = false
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            guard let listItem = sections?[indexPath.section].listItems[indexPath.row] else {QL4("No listItem"); return}

            tableView.beginUpdates()
            
            // remove from content provider
            listItemsEditTableViewDelegate?.onListItemDeleted(indexPath: indexPath, tableViewListItem: listItem)
            
            // remove from tableview and model
            tableView.deleteRows(at: [indexPath], with: .top)
            
            tableView.endUpdates()
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return isEditing
    }
    
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        listItemsEditTableViewDelegate?.onListItemMoved(from: sourceIndexPath, to: destinationIndexPath)
    }
    
    // MARK: - Expand sections
    
    func setAllSectionsExpanded(_ expanded: Bool, animated: Bool, onComplete: VoidFunction? = nil) {
        
        guard expanded != sectionsExpanded else {QL1("No changes"); onComplete?(); return}
        
        guard let sections = sections else {QL4("No sections"); return}

        sectionsExpanded = expanded
        
        var completed = 0
        
        tableView.wrapUpdates {[weak self] in
            for (index, _) in sections.enumerated() {
                
                self?.setSectionExpanded(expanded, sectionIndex: index/*, section: section*/, animated: animated, onComplete: {
                    completed += 1
                    if completed == sections.count {
                        onComplete?()
                    }
                })
            }
        }
    }
    
    fileprivate func setSectionExpanded(_ expanded: Bool, sectionIndex: Int/*, section: ListItemsViewSection*/, animated: Bool, onComplete: VoidFunction? = nil) {
        guard let sections = sections else {QL4("No sections"); return}
        
        let sectionIndexPaths: [IndexPath] = (0..<sections[sectionIndex].listItems.count).map {
            return IndexPath(row: $0, section: sectionIndex)
        }
        
        if let onComplete = onComplete {
            CATransaction.setCompletionBlock(onComplete)
        }
        
        if expanded {
            tableView.insertRows(at: sectionIndexPaths, with: .top)

        } else {
            tableView.deleteRows(at: sectionIndexPaths, with: .top)
        }
    }
    
    
    // MARK: - ListItemCellDelegateNew
    
    
    func onItemSwiped(_ listItem: ListItem) {
        
        guard let indexPath = indexPathFor(listItem: listItem) else {QL4("Invalid state: No indexPath for list item: \(listItem)"); return}
        
        listItemsTableViewDelegate?.onListItemSelected(listItem, indexPath: indexPath)
        
        if tableView.numberOfRows(inSection: indexPath.section) == 1 {
            tableView.deleteSections(IndexSet([indexPath.section]), with: .top)
        } else {
            tableView.deleteRows(at: [indexPath], with: .top)
        }
    }
    
    func indexPathFor(listItem: ListItem) -> IndexPath? {
        guard let sections = sections else {QL4("No sections"); return nil}
        
        for (sectionIndex, section) in sections.enumerated() {
            let listItems = section.listItems
            for (index, item) in listItems.enumerated() {
                if item.same(listItem) {
                    return IndexPath(row: index, section: sectionIndex)
                }
            }
        }
        
        return nil
    }

    func onStartItemSwipe(_ listItem: ListItem) {
        //        clearPendingSwipeItemIfAny(true)
    }
    
    func onButtonTwoTap(_ listItem: ListItem) {
        // TODO!!!!!!!!!!!!!!! remove this undo - only for delete and then show it at the bottom.
        //        listItemsTableViewDelegate?.onListItemReset(tableViewListItem)
        //        self.swipedTableViewListItem = nil
    }
    
    func onNoteTap(_ cell: ListItemCellNew, listItem: ListItem) {
        if !listItem.note.isEmpty {
            if let noteButton = cell.noteButton {
                listItemsTableViewDelegate?.showPopup(text: listItem.note, cell: cell, button: noteButton)
            } else {
                QL3("No note button")
            }
        } else {
            QL4("Invalid state: There's no note. When there's no note there should be no button so we shouldn't be here.")
        }
    }
    
    func onMinusTap(_ listItem: ListItem) {
        listItemsTableViewDelegate?.onIncrementItem(listItem, delta: -1)
        SwipeToIncrementAlertHelper.check(self)
    }
    
    func onPlusTap(_ listItem: ListItem) {
        listItemsTableViewDelegate?.onIncrementItem(listItem, delta: 1)
        SwipeToIncrementAlertHelper.check(self)
    }
    
    func onPanQuantityUpdate(_ tableViewListItem: ListItem, newQuantity: Float) {
        listItemsTableViewDelegate?.onIncrementItem(tableViewListItem, delta: newQuantity - tableViewListItem.quantity(status))
    }
    
}
