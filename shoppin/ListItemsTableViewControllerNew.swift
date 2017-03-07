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
    func onListItemSelected(_ tableViewListItem: ListItem, indexPath: IndexPath)
    func onListItemSwiped(_ tableViewListItem: ListItem, indexPath: IndexPath)
    func onListItemReset(_ tableViewListItem: ListItem) // revert undo
    func onSectionHeaderTap(_ header: ListItemsSectionHeaderView, section: Section)
    func onIncrementItem(_ model: ListItem, delta: Float)
    func onQuantityInput(_ listItem: ListItem, quantity: Float)
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

class ListItemsTableViewControllerNew: UITableViewController, ListItemCellDelegateNew, ListItemsSectionHeaderViewDelegate {

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
    fileprivate let placeholderIdentifier = "placeholder"
    
    fileprivate var pullToAddView: MyRefreshControl?
    
    var placeHolderItem: (indexPath: IndexPath, item: ListItem)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initTableView()
    }
    
    fileprivate func initTableView() {
        // TODO!!!!!!!!!!!! still necessary?
//        self.tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        self.tableView.allowsSelectionDuringEditing = true
        
        
        tableView.register(UINib(nibName: "PlaceHolderItemCell", bundle: nil), forCellReuseIdentifier: "placeholder")
        
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
        listItemsTableViewDelegate?.onTableViewScroll(scrollView)
    }
    
//    TODO!!!!!!!!!!!!!!!! ?
//    func scrollToListItem(_ litsItem: ListItem) {
//        if let indexPath = getIndexPath(litsItem) {
//            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
//        } else {
//            QL2("Didn't find list item to scroll to")
//        }
//    }
    
    func findListItemIndexPath(listItem: ListItem) -> IndexPath? {
        guard let sections = sections else {QL4("No sections"); return nil}
        
        for (sectionIndex, s) in sections.enumerated() {
            for (listItemIndex, l) in s.listItems.enumerated() {
                if l.same(listItem) {
                    return IndexPath(row: listItemIndex, section: sectionIndex)
                }
            }
        }
        
        return nil
    }
    
    func findSectionIndex(section: Section) -> Int? {
        guard let sections = sections else {QL4("No sections"); return nil}
        for (sectionIndex, s) in sections.enumerated() {
            if s.same(section) {
                return sectionIndex
            }
        }
        return nil
    }
    
    
    func updateTableViewSection(section: Section) {
        if let sectionIndex = findSectionIndex(section: section) {
            tableView.reloadSections(IndexSet([sectionIndex]), with: .none)
        } else {
            QL3("Didn't find index for: \(section)")
        }
    }
    
    func updateListItemCell(listItem: ListItem) {
        if let indexPath = findListItemIndexPath(listItem: listItem) {
            tableView.reloadRows(at: [indexPath], with: .none)
        } else {
            QL3("Didn't find cell to update for: \(listItem)")
        }
    }
    
    
    // MARK: - Table view data source / delegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return isEditing
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionObj = sections?[section] else {QL4("Invalid state: no section"); return nil}
        
        let view = Bundle.loadView("ListItemsSectionHeaderView", owner: self) as! ListItemsSectionHeaderView
        view.config(section: sectionObj, contracted: contract)
        
        view.delegate = self
        return view
    }
    
    
    var contract: Bool = false
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return contract ? DimensionsManager.contractedSectionHeight : DimensionsManager.listItemsHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if sectionsExpanded {
            
            
            // TODO remove this - let method as it was before
            let addForPossiblePlaceholder: Int = {
                if let placeHolderItem = placeHolderItem, placeHolderItem.indexPath.section == section {
                    return 0
                } else {
                    return 0
                }
            }()
            
            let listItemsInSectionCount = sections?[section].listItems.count ?? 0
            
            return listItemsInSectionCount + addForPossiblePlaceholder
            
        } else {
            return 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections?.count ?? 0
        // TODO!!!!!!!!!!!!!!!! if placeholder item has a section that isn't yet in the table we have to add it here
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let placeHolderItem = placeHolderItem, placeHolderItem.indexPath == indexPath {
            let cell = tableView.dequeueReusableCell(withIdentifier: placeholderIdentifier) as! PlaceHolderItemCell
            cell.categoryColorView.backgroundColor = placeHolderItem.item.product.product.product.item.category.color
            return cell

        } else {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let listItem = sections?[indexPath.section].listItems[indexPath.row] else {QL4("No listItem"); return}
        listItemsTableViewDelegate?.onListItemSelected(listItem, indexPath: indexPath)
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
        
        listItemsTableViewDelegate?.onListItemSwiped(listItem, indexPath: indexPath)
        
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

    func onChangeQuantity(_ listItem: ListItem, delta: Float) {
        listItemsTableViewDelegate?.onIncrementItem(listItem, delta: delta)
    }
    
    func onQuantityInput(_ listItem: ListItem, quantity: Float) {
        listItemsTableViewDelegate?.onQuantityInput(listItem, quantity: quantity)
    }
    
    var isControllerInEditMode: Bool {
        return isEditing
    }
    
    // MARK: - ListItemsSectionHeaderViewDelegate
    
    func onHeaderTap(_ header: ListItemsSectionHeaderView) {
        guard let section = header.section else {QL4("Illegal state: header should have a section"); return}
        listItemsTableViewDelegate?.onSectionHeaderTap(header, section: section)
    }
}
