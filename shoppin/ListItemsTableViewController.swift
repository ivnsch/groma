//
//  ListItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 24.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol ListItemsTableViewDelegate {
    func onListItemClear(tableViewListItem: TableViewListItem, notifyRemote: Bool, onFinish: VoidFunction) // submit item marked as undo
    func onListItemSelected(tableViewListItem: TableViewListItem, indexPath: NSIndexPath) // mark as undo
    func onListItemReset(tableViewListItem: TableViewListItem) // revert undo
    func onSectionHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection)
    func onIncrementItem(model: TableViewListItem, delta: Int)
    func onTableViewScroll(scrollView: UIScrollView)
    func onPullToAdd()
}

protocol ListItemsEditTableViewDelegate {
    func onListItemsOrderChangedSection(tableViewListItems: [TableViewListItem])
    func onListItemDeleted(tableViewListItem: TableViewListItem)
}

enum ListItemsTableViewControllerStyle {
    case Normal, Gray
}

class ListItemsTableViewController: UITableViewController, ItemActionsDelegate {
    
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section
    private(set) var tableViewSections: [ListItemsViewSection] = []
    
    private var lastContentOffset: CGFloat = 0
    
    var scrollViewDelegate: UIScrollViewDelegate?
    var listItemsTableViewDelegate: ListItemsTableViewDelegate?
    var listItemsEditTableViewDelegate: ListItemsEditTableViewDelegate?

    private(set) var sections: [Section] = [] // quick access. Sorting not necessarily same as in tableViewSections
    private(set) var items: [ListItem] = [] // quick access. Sorting not necessarily same as in tableViewSections
    
    var style: ListItemsTableViewControllerStyle = .Normal
    
    var status: ListItemStatus = .Todo
    
    private var swipedTableViewListItem: TableViewListItem? // Item marked for "undo". Item is not submitted until undo state is cleared
    
    func touchEnabled(enabled:Bool) {
        self.tableView.userInteractionEnabled = enabled
    }
    
    func enablePullToAdd() {
        let refreshControl = PullToAddHelper.createPullToAdd(self)
        refreshControl.addTarget(self, action: "onPullRefresh:", forControlEvents: .ValueChanged)
        self.refreshControl = refreshControl
    }
    
    func onPullRefresh(sender: UIRefreshControl) {
        sender.endRefreshing()
        listItemsTableViewDelegate?.onPullToAdd()
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        listItemsTableViewDelegate?.onTableViewScroll(scrollView)
    }
    
    var sectionsExpanded: Bool = true
    
    var cellMode: ListItemCellMode = .Note {
        didSet {
            // the section is only a "cell producer", it doesn't have access to the cells. So we have to set first the mode in the section (such that when the user scrolls the new cells are loaded with the correct mode, and in the visible cells, which we have access to, via the tableView, separately.
            for section in tableViewSections {
                section.cellMode = cellMode
            }
            if let cells = tableView.visibleCells as? [ListItemCell] {
                for cell in cells {
                    cell.mode = cellMode
                }
            } else {
                print("Error: ListItemsTableViewController.cellMode: Couldn't cast to [ListItemCell]. Cells: \(tableView.visibleCells)")
            }

        }
    }
    
    /**
     Returns total price of shown items exluding those marked for undo
     */
    var totalPrice: Float {
        return tableViewSections.sum{$0.totalPrice}
    }

    /**
     Returns total quantity of shown items exluding those marked for undo
     */
    var totalQuantity: Int {
        return tableViewSections.sum{$0.totalQuantity}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableView()
        
        //TODO maybe delete with this?
//        self.tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    func tableViewShiftDown(offset: CGFloat) { // offset/inset to start at given offset but scroll behind it
        self.tableView.inset = UIEdgeInsetsMake(offset, 0, 0, 0)
        self.tableView.topOffset = -self.tableView.inset.top
    }
    
    override func viewWillLayoutSubviews() {
//        println(self.view.constraints().count)
    }
    
    private func initTableView() {
//        self.tableView.registerClass(ListItemCell.self, forCellReuseIdentifier: ItemsListTableViewConstants.listItemCellIdentifier)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        
        self.tableView.allowsSelectionDuringEditing = true
//        self.tableView.setEditing(true, animated: true)
    }
    
    func setListItems(items: [ListItem]) { // as function instead of variable+didSet because didSet is called each time we modify the array
        self.items = items
        self.initTableViewContent()
        
        if QorumLogs.minimumLogLevelShown < 2 {
            print("List for status: \(status)")
            print(debugTableViewListItems())
        }
    }
    
    private func initTableViewContent() {
        let(tableViewSections, sections) = buildTableViewSections(items)
        self.tableViewSections = tableViewSections
        self.sections = sections
        
        for section in tableViewSections {
            section.headerBGColor = section.section.color
        }

        self.tableView.reloadData()
    }
    
    func addListItem(listItem:ListItem) {
        self.items.append(listItem)
        
        self.addListItemToSection(listItem)
        
        self.tableView.reloadData()
    }

    private func addListItemToSection(listItem:ListItem) {
        
        let tableViewListItem = TableViewListItem(listItem: listItem)
        
        let foundSectionMaybe = self.tableViewSections.filter({ (s:ListItemsViewSection) -> Bool in
            s.section == listItem.section
        }).first
        
        if let foundSection = foundSectionMaybe {
            foundSection.addItem(tableViewListItem)
        } else {
            let hasHeader = listItem.section.name != defaultSectionIdentifier
            self.sections.append(listItem.section)
            let tableViewSection = ListItemsViewSection(section: listItem.section, tableViewListItems: [tableViewListItem], hasHeader: hasHeader, status: status)
            tableViewSection.delegate = self
            tableViewSection.cellMode = cellMode
            self.tableViewSections.append(tableViewSection)
        }
    }

    func updateListItems(listItems: [ListItem], status: ListItemStatus, notifyRemote: Bool) {
        for listItem in listItems {
            updateListItem(listItem, status: status, notifyRemote: notifyRemote)
        }
    }
    
    /**
    Update or add list item
    When sure it's an "add" case use addListItem - this checks first if the item exists and is thus slower
    */
    func updateListItem(listItem: ListItem, status: ListItemStatus, notifyRemote: Bool) {
        updateOrAddListItem(listItem, status: status, increment: false, notifyRemote: notifyRemote) // update means overwrite - don't increment
    }

    func incrementListItem(increment: ItemIncrement, status: ListItemStatus, notifyRemote: Bool) {
        if let (tableViewListItem, _) = findFirstListItemWithIndexPath({$0.uuid == increment.itemUuid}) {
            let incrementedListItem = tableViewListItem.listItem.increment(ListItemStatusQuantity(status: status, quantity: increment.delta))
            updateOrAddListItem(incrementedListItem, status: status, increment: false, notifyRemote: notifyRemote) // update means overwrite - don't increment
        } else {
            QL1("Couldn't increment list item because it's not in the table view")
        }
    }
    
    private func findIndexInItems(listItem: ListItem) -> Int? {
        for (index, item) in items.enumerate() {
            if item.same(listItem) {
                return index
            }
        }
        return nil
    }
    
    private func replaceItemAndRebuildTable(listItem: ListItem) {
        if let index = findIndexInItems(listItem) {
            items[index] = listItem
            initTableViewContent()
        } else {
            print("Error: Invalid state: ListItemsTableViewController.updateOrAddListItem: listItem: \(listItem) not found in items, despite its indexPath was found in sections")
        }
    }
    
    // TODO simpler way to update, maybe just always reinit the table... also refactor rest (build sections etc) it is way more complex than it should
    // right now prefer not to always reinit the table because this can change sorting
    // so first we should implement persistent sorting, then refactor this class
    // -parameter: increment if, in case it's an update, the quantities of the items should be added together. If false the quantity is just overwritten like the rest of fields
    // -status: the updated status of list item (if the item has switched status (e.g. swipe from todo to done), this is the new status, otherwise it's just the current status of the item)
    // TODO increment seems not ot be used, what was this for? remove?
    func updateOrAddListItem(listItem: ListItem, status: ListItemStatus, increment: Bool, scrollToSelection: Bool = false, notifyRemote: Bool) {
        
        if let indexPath = getIndexPath(listItem) {
        
            let oldItem = tableViewSections[indexPath.section].tableViewListItems[indexPath.row]
        
            if !oldItem.listItem.hasStatus(status) {
        
                // the item is in this tableview but has now a new status - delete (swipe) it from tableview. This is used by websockets
                // when another user e.g. sends to item to cart we want to show the receiving users the item being "swiped" and then deleted
                markOpen(true, indexPath: indexPath, notifyRemote: notifyRemote) {[weak self] in // swipe
                    self?.clearPendingSwipeItemIfAny(notifyRemote) // delete
                }
                
            } else {
                
                var finalIndexPath: NSIndexPath?
                
                if (oldItem.listItem.section == listItem.section) { // item is already in table view and also has same section
                    replaceItemAndRebuildTable(listItem)
                    finalIndexPath = indexPath // item is in the same place as before
                    
                } else { // the item is already in table view but has a different section
                    //update item and rebuild table, which organises sections
                    replaceItemAndRebuildTable(listItem)
                    finalIndexPath = getIndexPath(listItem) // since the item changed section the index path is now different, get it again
                }
                
                if scrollToSelection {
                    if let finalIndexPath = finalIndexPath {
                        tableView.scrollToRowAtIndexPath(finalIndexPath, atScrollPosition: .Top, animated: true)
                    } else {
                        QL4("Invalid state: Index path should be set. Initial index path: \(indexPath). ListItem: \(listItem)")
                    }
                }
            }
            
        } else { // indexpath for updated item not in the tableview -> item is new or has a new section
            items.append(listItem) // insert item at end of the list
            initTableViewContent() // rebuild table - this makes also possible new section appear
            
            if scrollToSelection {
                if let indexPath = getIndexPath(listItem) { // lookup indexpath where new item was inserted (initTableViewContent puts the item where it belongs)
                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
                }
            }
        }
    }
    
    // Returns a string representing current sections with listitems
    private func debugTableViewListItems() -> String {
        return tableViewSections.reduce("") {str, section in
            let sectionListItemsStr = section.tableViewListItems.reduce("") {str, tableViewListItem in
                return "\(str)\t\(tableViewListItem)\n"
            }
            return "(\(str)\(section.section.name)):\n[\(sectionListItemsStr)]"
        }
    }

    // Returns a string representing current sections with listitems - focus: order
    private func debugTableViewListItemsOrder() -> String {
        return tableViewSections.reduce("") {str, section in
            let sectionListItemsStr = section.tableViewListItems.reduce("") {str, tableViewListItem in
                return "\(str)\t\(tableViewListItem.listItem.shortOrderDebugDescription)\n"
            }
            return "\(str)\(section.section.shortOrderDebugDescription):\n[\(sectionListItemsStr)]"
        }
    }
    
    // Updates a section based on identity (uuid). Note that this isn't usable for order update, as updating order requires to update the order field of sections below
    func updateSection(section: Section) {
        
        // This is maybe not the most performant way to do this update but it guarantees consistency as it uses the "official" entry point to initialise the table, which is setListItems
        let updatedItems: [ListItem] = items.map{item in
            if item.section.same(section) {
                return item.copy(section: section, note: nil)
            } else {
                return item
            }
        }
        setListItems(updatedItems)
    }
    
    // loops through list items to generate tableview sections, returns also found sections so we don't have to loop 2x
    private func buildTableViewSections(listItems: [ListItem]) -> (tableViewSections:[ListItemsViewSection], sections:[Section]) {
        var tableViewSections:[ListItemsViewSection] = []
        var sections:[Section] = []
        
        if !listItems.isEmpty {
            var set = [Section: Int]() // "set" for quick lookup which sections we added already
            

            var currentTableViewSection:ListItemsViewSection!
            
            for listItem in listItems {
                
                let tableViewListItem = TableViewListItem(listItem: listItem)
                
                if set[listItem.section] == nil { // section not created yet - create one
                    set[listItem.section] = 1 // dummy value... swift doesn't have Set
                    sections.append(listItem.section)
                    
                    currentTableViewSection = ListItemsViewSection(section: listItem.section, tableViewListItems: [], status: status)
                    currentTableViewSection.cellMode = cellMode
                    currentTableViewSection.delegate = self
                    currentTableViewSection.expanded = sectionsExpanded

                    if self.style == .Gray {
                        currentTableViewSection.style = .Gray
                    }
                    tableViewSections.append(currentTableViewSection)
                    
                } else { //the section is in the set, this means it's in the tableViewSections. find it
                    for tableViewSection in tableViewSections {
                        if tableViewSection.section == listItem.section {
                            currentTableViewSection = tableViewSection
                        }
                    }
                }
                currentTableViewSection.addItem(tableViewListItem)
            }
        }
        
        return (tableViewSections, sections)
    }
    
    // TODO return bool
    func removeListItem(listItem: ListItem, animation: UITableViewRowAnimation = .Bottom) {
        if let indexPath = self.getIndexPath(listItem) {
            self.removeListItem(listItem, indexPath: indexPath, animation: animation)
        }
    }
    
    func removeListItem(uuid: String, animation: UITableViewRowAnimation = .Bottom) {
        if let indexPath = self.getIndexPath(uuid) {
            self.removeListItem(uuid, indexPath: indexPath, animation: animation)
        }
    }

    private func removeListItem(listItem: ListItem, indexPath: NSIndexPath, animation: UITableViewRowAnimation = .Bottom) {
        removeListItem(listItem.uuid, animation: animation)
    }
    
    // TODO return bool
    private func removeListItem(listItemUuid: String, indexPath: NSIndexPath, animation: UITableViewRowAnimation = .Bottom) {
        // TODO review this, we store items reduntantely, so find index in one list, remove, use indexPath for the other list....
        // also is it thread safe to pass indexpath like this
        // paramater indexPath and listitem?
        var indexMaybe:Int?
        for i in 0...self.items.count {
            if self.items[i].uuid == listItemUuid {
                indexMaybe = i
                break
            }
        }
        
        if let index = indexMaybe {
            // remove from model
            self.items.removeAtIndex(index)
            let tableViewSection = self.tableViewSections[indexPath.section]
            tableViewSection.tableViewListItems.removeAtIndex(indexPath.row)
            
            // remove from table view
            self.tableView.beginUpdates()
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: animation)
            
            // remove section if no items
            if tableViewSection.tableViewListItems.isEmpty {
                removeSection(tableViewSection.section.uuid, indexPath: indexPath, animation: animation)
            }
            self.tableView.endUpdates()
        }
    }
    
    // TODO we are iterating multiple times through listitems, once to find the product and in removeListItem...
    func removeListItemReferencingProduct(productUuid: String) {
        if let (tableViewListItem, _) = findFirstListItemWithIndexPath({$0.product.uuid == productUuid}) {
            removeListItem(tableViewListItem.listItem)
        } else {
            QL1("removeListItemReferencingProduct list item is not in list items table view. Product uuid: \(productUuid)")
        }
    }

    func removeListItemsReferencingCategory(categoryUuid: String) {
        for (tableViewListItem, _) in findListItemsWithIndexPath({$0.product.product.category.uuid == categoryUuid}) {
            removeListItem(tableViewListItem.listItem)
        }
    }
    
    // Used by websocket, when receiving a notification of an updated product
    func updateProduct(product: Product, status: ListItemStatus) {
        if let (tableViewListItem, _) = findFirstListItemWithIndexPath({$0.product.product.uuid == product.uuid}) {
            let updated = tableViewListItem.listItem.update(product)
            updateListItem(updated, status: status, notifyRemote: false)
        } else {
            QL1("updateProduct list item is not in list items table view. Product uuid: \(product.uuid)")
        }
    }
    
    // TODO why do we need indexPath and have to look for the index in the sections array using uuid, shouldn't both have the same index?
    private func removeSection(uuid: String, indexPath: NSIndexPath, animation: UITableViewRowAnimation = .Bottom) {
        // remove table view section
        self.tableViewSections.removeAtIndex(indexPath.section)
        // remove model section TODO better way
        let sectionIndexMaybe: Int? = getSectionIndex(uuid)
        if let sectionIndex = sectionIndexMaybe {
            self.sections.removeAtIndex(sectionIndex)
            // remove from table view
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: animation)
        }
    }
    
    func removeSection(uuid: String) {
        if let indexPath = getSectionIndexPath(uuid) {
            removeSection(uuid, indexPath: indexPath)
        }
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
        
//        let velocity = scrollView.panGestureRecognizer.velocityInView(scrollView.superview)
//        let scrollingUp = (velocity.y < 0)
        
        clearPendingSwipeItemIfAny(true)
    }
    
    func getIndexPath(listItemUuid: String) -> NSIndexPath? {
        for (sectionIndex, s) in self.tableViewSections.enumerate() {
            for (listItemIndex, l) in s.tableViewListItems.enumerate() {
                if (listItemUuid == l.listItem.uuid) {
                    let indexPath = NSIndexPath(forRow: listItemIndex, inSection: sectionIndex)
                    return indexPath
                }
            }
        }
        return findListItemsWithIndexPath{$0.uuid == listItemUuid}.first.map{$0.indexPath}
    }
    
    private typealias TableViewListItemWithIndexPath = (item: TableViewListItem, indexPath: NSIndexPath)

    private func findFirstListItemWithIndexPath(filter: ListItem -> Bool) -> TableViewListItemWithIndexPath? {
        return findListItemsWithIndexPath(filter).first
    }
    
    private func findListItemsWithIndexPath(filter: ListItem -> Bool) -> [TableViewListItemWithIndexPath] {
        var arr: [TableViewListItemWithIndexPath] = []
        for (sectionIndex, s) in self.tableViewSections.enumerate() {
            for (listItemIndex, l) in s.tableViewListItems.enumerate() {
                if (filter(l.listItem)) {
                    let indexPath = NSIndexPath(forRow: listItemIndex, inSection: sectionIndex)
                    arr.append((l, indexPath))
                }
            }
        }
        return arr
    }
    
    func getIndexPath(listItem: ListItem) -> NSIndexPath? {
        return getIndexPath(listItem.uuid)
    }
    
    func getIndex(section: Section) -> Int? {
        return getSectionIndex(section.uuid)
    }
    
    func getSectionIndex(uuid: String) -> Int? {
        for (index, s) in self.sections.enumerate() {
            if uuid == s.uuid {
                return index
            }
        }
        return nil
    }
    
    func getSectionIndexPath(uuid: String) -> NSIndexPath? {
        for (sectionIndex, s) in self.tableViewSections.enumerate() {
            if (uuid == s.section.uuid) {
                return NSIndexPath(forRow: 0, inSection: sectionIndex)
            }
        }
        return nil
    }
    
    /**
    Submits item marked as "undo" if there is any
    - parameter: onFinish optional callback to execute after submitting (this may e.g. call a provider). If there's no pending item, this is not called.
    */
    func clearPendingSwipeItemIfAny(notifyRemote: Bool, onFinish: VoidFunction? = nil) {
        if let s = self.swipedTableViewListItem {
            
            listItemsTableViewDelegate?.onListItemClear(s, notifyRemote: notifyRemote) {
                self.swipedTableViewListItem = nil
                //            self.removeListItem(s.listItem, animation: UITableViewRowAnimation.Bottom)
                
                onFinish?()
            }
        } else {
            onFinish?()
        }
    }
    
    // MARK: - ItemActionsDelegate
    
    func startItemSwipe(tableViewListItem: TableViewListItem) {
        clearPendingSwipeItemIfAny(true)
    }
    
    func endItemSwipe(tableViewListItem: TableViewListItem) {
//        let allListItems = self.tableViewSections.map {
//            $0.listItems
//            }.reduce([], combine: +)
     
        // TODO call also onListItemSelected here? (like in selection)
        self.swipedTableViewListItem = tableViewListItem
    }
    
    func undoSwipe(tableViewListItem: TableViewListItem) {
        listItemsTableViewDelegate?.onListItemReset(tableViewListItem)
        self.swipedTableViewListItem = nil
    }

    func onNoteTap(tableViewListItem: TableViewListItem) {
        if let note = tableViewListItem.listItem.note {
            AlertPopup.show(message: note, controller: self)
            
        } else {
            print("Error: Invalid state in onNoteTap. There's no note. When there's no note there should be no button so we shouldn't be here.")
        }
    }
    
    func onMinusTap(tableViewListItem: TableViewListItem) {
        listItemsTableViewDelegate?.onIncrementItem(tableViewListItem, delta: -1)
    }
    
    func onPlusTap(tableViewListItem: TableViewListItem) {
        listItemsTableViewDelegate?.onIncrementItem(tableViewListItem, delta: 1)
    }
    
    func onHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        listItemsTableViewDelegate?.onSectionHeaderTap(header, section: section)
    }
    
    func setAllSectionsExpanded(expanded: Bool, animated: Bool, onComplete: VoidFunction? = nil) {
        
        var completed = 0
        for (index, section) in tableViewSections.enumerate() {
            setSectionExpanded(expanded, sectionIndex: index, section: section, animated: animated, onComplete: {[weak self] in
                completed++
                if completed == self?.tableViewSections.count {
                    onComplete?()
                }
            })
        }
        sectionsExpanded = expanded
    }

  
    // This updates all the sections at once opposed to method below, but the animation is not as smooth
//    func setAllSectionsExpanded(expanded: Bool, animated: Bool, onComplete: VoidFunction? = nil) {
//        func getSectionIndexPaths(section: ListItemsViewSection, sectionIndex: Int) -> [NSIndexPath] {
//            return (0..<section.tableViewListItems.count).map {return NSIndexPath(forRow: $0, inSection: sectionIndex)}
//        }
//        tableView.wrapUpdates {[weak self] in
//            if let weakSelf = self {
//                for (index, section) in weakSelf.tableViewSections.enumerate() {
//                    let sectionIndexPaths = getSectionIndexPaths(section, sectionIndex: index)
//                    if expanded {
//                        weakSelf.tableView.insertRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
//                    } else {
//                        weakSelf.tableView.deleteRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
//                    }
//                }
//                weakSelf.sectionsExpanded = expanded
//            }
//        }
//        onComplete?()
//    }
//    
    private func setSectionExpanded(expanded: Bool, sectionIndex: Int, section: ListItemsViewSection, animated: Bool, onComplete: VoidFunction? = nil) {
        
        let sectionIndexPaths: [NSIndexPath] = (0..<section.tableViewListItems.count).map {
            return NSIndexPath(forRow: $0, inSection: sectionIndex)
        }
        
        if let onComplete = onComplete {
            CATransaction.setCompletionBlock(onComplete)
        }

        if expanded {
            tableView.wrapUpdates {[weak self] in
                self?.tableView.insertRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
                section.expanded = true
            }
        } else {
            tableView.wrapUpdates {[weak self] in
                self?.tableView.deleteRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
                section.expanded = false
            }
        }
    }
    
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return self.editing
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.tableViewSections[section].viewForHeader()
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return self.tableViewSections[section].viewForFooter()
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat(self.tableViewSections[section].heightForFooter())
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(self.tableViewSections[section].heightForHeader())
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewSections[section].numberOfRows()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.tableViewSections.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let section = self.tableViewSections[indexPath.section]
        return section.heightForRow(indexPath.row)
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = self.tableViewSections[indexPath.section]
        return section.tableView(tableView, row:indexPath.row)
        
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tableViewListItem = self.tableViewSections[indexPath.section].tableViewListItems[indexPath.row]
        self.listItemsTableViewDelegate?.onListItemSelected(tableViewListItem, indexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            self.tableView.beginUpdates()

            // remove from tableview and model
            let listItem = self.tableViewSections[indexPath.section].tableViewListItems[indexPath.row]
            self.removeListItem(listItem.listItem, indexPath: indexPath, animation: UITableViewRowAnimation.Bottom)
            
            // remove from content provider
            self.listItemsEditTableViewDelegate?.onListItemDeleted(listItem)
            
            self.tableView.endUpdates()
        }
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return self.editing
    }

    /**
    Sets pending item (mark as undo" if open and shows cell open state. Submits currently pending item if existent.
    parameter onFinish: After cell marked open and automatic update of possible second "undo" item (to "done").
    */
    func markOpen(open: Bool, indexPath: NSIndexPath, notifyRemote: Bool, onFinish: VoidFunction? = nil) {
        if let section = self.tableViewSections[safe: indexPath.section], tableViewListItem = section.tableViewListItems[safe: indexPath.row] {
            // Note: order is important here! first show open at current index path, then remove possible pending (which can make indexPath invalid, thus later), then update pending variable with new item
            self.showCellOpen(open, indexPath: indexPath)
            self.clearPendingSwipeItemIfAny(notifyRemote) {
                self.swipedTableViewListItem = tableViewListItem
                onFinish?()
            }
            
        } else {
            QL3("markOpen: \(open), self not set or indexPath not found: \(indexPath)")
        }
    }
    
    private func showCellOpen(open: Bool, indexPath: NSIndexPath) {
        if let swipeableCell = tableView.cellForRowAtIndexPath(indexPath) as? SwipeableCell {
            if let section = tableViewSections[safe: indexPath.section] {
                if section.tableViewListItems[safe: indexPath.row] != nil {
                    section.tableViewListItems[indexPath.row].swiped = open
                } else {
                    QL3("Didn't find item for index path: \(indexPath)")
                }
            } else {
                QL4("Didn't find section for index path: \(indexPath)")
            }
            swipeableCell.setOpen(open, animated: true)
        } else {
            print("Warning: showCellOpen: \(open), no swipeable cell for indexPath: \(indexPath)")
        }
    }
   
    // updates list item models with current ordering in table view
    // TODO review and remove commented / not necessary code
    private func updateListItemsModelsOrder() {
        var sectionRows = 0
        for section in self.tableViewSections {
            for (listItemIndex, tableViewListItem) in section.tableViewListItems.enumerate() {
//                let absoluteRowIndex = listItemIndex + sectionRows
//                tableViewListItem.listItem.order = absoluteRowIndex
                tableViewListItem.listItem.updateOrderMutable(ListItemStatusOrder(status: status, order: listItemIndex))
            }
            sectionRows += section.numberOfRows()
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if sourceIndexPath != destinationIndexPath {
            let srcSection = self.tableViewSections[sourceIndexPath.section]
            let tableViewListItem = srcSection.tableViewListItems[sourceIndexPath.row]
            srcSection.tableViewListItems.removeAtIndex(sourceIndexPath.row)
            
            let dstSection = self.tableViewSections[destinationIndexPath.section]
            tableViewListItem.listItem.section = dstSection.section //not superclean to update model data in this controller, but for simplicity...
            
            //        let absoluteRow = tableView.absoluteRow(destinationIndexPath)
            dstSection.tableViewListItems.insert(tableViewListItem, atIndex: destinationIndexPath.row)
            
            self.updateListItemsModelsOrder()
            
            // update only list items in modified section(s)
            var modifiedListItems = srcSection.tableViewListItems
            if dstSection != srcSection {
                modifiedListItems += dstSection.tableViewListItems
            }
            
            delay(0.4) {
                // show possible changes, e.g. new section color
                tableView.reloadData()
            }
            
            self.listItemsEditTableViewDelegate?.onListItemsOrderChangedSection(modifiedListItems)
        }
    }
}
