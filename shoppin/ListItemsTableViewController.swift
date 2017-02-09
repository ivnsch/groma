//
//  ListItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 24.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers
import RealmSwift

protocol ListItemsTableViewDelegate: class {
    func onListItemClear(_ tableViewListItem: TableViewListItem, notifyRemote: Bool, onFinish: VoidFunction) // submit item marked as undo
    func onListItemSelected(_ tableViewListItem: TableViewListItem, indexPath: IndexPath) // mark as undo
    func onListItemReset(_ tableViewListItem: TableViewListItem) // revert undo
    func onSectionHeaderTap(_ header: ListItemsSectionHeaderView, section: ListItemsViewSection)
    func onIncrementItem(_ model: TableViewListItem, delta: Float)
    func onTableViewScroll(_ scrollView: UIScrollView)
    func onPullToAdd()
}

protocol ListItemsEditTableViewDelegate: class {
    func onListItemsOrderChangedSection(_ tableViewListItems: [TableViewListItem])
    func onListItemDeleted(_ tableViewListItem: TableViewListItem)
}

enum ListItemsTableViewControllerStyle {
    case normal, gray
}

class ListItemsTableViewController: UITableViewController, ItemActionsDelegate {
    
    fileprivate let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section
    fileprivate(set) var tableViewSections: [ListItemsViewSection] = []
    
    fileprivate var lastContentOffset: CGFloat = 0
    
    weak var scrollViewDelegate: UIScrollViewDelegate?
    weak var listItemsTableViewDelegate: ListItemsTableViewDelegate?
    weak var listItemsEditTableViewDelegate: ListItemsEditTableViewDelegate?

    fileprivate(set) var sections: [Section] = [] // quick access. Sorting not necessarily same as in tableViewSections
    fileprivate(set) var items: [ListItem] = [] // quick access. Sorting not necessarily same as in tableViewSections
    
    var style: ListItemsTableViewControllerStyle = .normal
    
    var status: ListItemStatus = .todo
    
    fileprivate var swipedTableViewListItem: TableViewListItem? // Item marked for "undo".
    
    func touchEnabled(_ enabled:Bool) {
        self.tableView.isUserInteractionEnabled = enabled
    }
    
    func enablePullToAdd() {
        let refreshControl = PullToAddHelper.createPullToAdd(self)
        refreshControl.addTarget(self, action: #selector(ListItemsTableViewController.onPullRefresh(_:)), for: .valueChanged)
        self.refreshControl = refreshControl
    }
    
    func onPullRefresh(_ sender: UIRefreshControl) {
        sender.endRefreshing()
        listItemsTableViewDelegate?.onPullToAdd()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        listItemsTableViewDelegate?.onTableViewScroll(scrollView)
    }
    
    var sectionsExpanded: Bool = true
    
    var cellMode: ListItemCellMode = .note {
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
    
    var cellSwipeDirection: SwipeableCellDirection = .right
    
    /**
     Returns total price of shown items exluding those marked for undo
     */
    var totalPrice: Float {
        return tableViewSections.sum{$0.totalPrice}
    }

    /**
     Returns total quantity of shown items exluding those marked for undo
     */
    var totalQuantity: Float {
        return tableViewSections.sum{$0.totalQuantity}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableView()
        
        //TODO maybe delete with this?
//        self.tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    func tableViewShiftDown(_ offset: CGFloat) { // offset/inset to start at given offset but scroll behind it
        self.tableView.inset = UIEdgeInsetsMake(offset, 0, 0, 0)
        self.tableView.topOffset = -self.tableView.inset.top
    }
    
    override func viewWillLayoutSubviews() {
//        println(self.view.constraints().count)
    }
    
    fileprivate func initTableView() {
//        self.tableView.registerClass(ListItemCell.self, forCellReuseIdentifier: ItemsListTableViewConstants.listItemCellIdentifier)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        
        self.tableView.allowsSelectionDuringEditing = true
//        self.tableView.setEditing(true, animated: true)
    }
    
    func setListItems(_ items: [ListItem]) { // as function instead of variable+didSet because didSet is called each time we modify the array
        self.items = items
        self.initTableViewContent()
        
        if QorumLogs.minimumLogLevelShown < 2 {
            print("List for status: \(status)")
            print(debugTableViewListItems())
        }
    }
    
    fileprivate func initTableViewContent() {
        let(tableViewSections, sections) = buildTableViewSections(items)
        self.tableViewSections = tableViewSections
        self.sections = sections
        
        for section in tableViewSections {
            section.headerBGColor = section.section.color
        }

        self.tableView.reloadData()
    }
    
    func addListItem(_ listItem:ListItem) {
        self.items.append(listItem)
        
        self.addListItemToSection(listItem)
        
        self.tableView.reloadData()
    }

    fileprivate func addListItemToSection(_ listItem:ListItem) {
        
        let tableViewListItem = TableViewListItem(listItem: listItem)
        
        let foundSectionMaybe = self.tableViewSections.filter({ (s:ListItemsViewSection) -> Bool in
            s.section.same(listItem.section)
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

    func updateListItems(_ listItems: [ListItem], status: ListItemStatus, notifyRemote: Bool) {
        for listItem in listItems {
            updateListItem(listItem, status: status, notifyRemote: notifyRemote)
        }
    }
    
    /**
    Update or add list item
    When sure it's an "add" case use addListItem - this checks first if the item exists and is thus slower
    */
    func updateListItem(_ listItem: ListItem, status: ListItemStatus, notifyRemote: Bool) {
        updateOrAddListItem(listItem, status: status, increment: false, notifyRemote: notifyRemote) // update means overwrite - don't increment
    }

    func incrementListItem(_ increment: ItemIncrement, status: ListItemStatus, notifyRemote: Bool) {
        if let (tableViewListItem, _) = findFirstListItemWithIndexPath({$0.uuid == increment.itemUuid}) {
            let incrementedListItem = tableViewListItem.listItem.increment(ListItemStatusQuantity(status: status, quantity: increment.delta))
            updateOrAddListItem(incrementedListItem, status: status, increment: false, notifyRemote: notifyRemote) // update means overwrite - don't increment
        } else {
            QL2("Couldn't increment list item because it's not in the table view")
        }
    }

    func updateQuantity(_ uuid: String, quantity: Float, notifyRemote: Bool) {
        if let (tableViewListItem, _) = findFirstListItemWithIndexPath({$0.uuid == uuid}) {
            let updatedItem = tableViewListItem.listItem.updateQuantity(ListItemStatusQuantity(status: status, quantity: quantity))
            updateListItem(updatedItem, status: status, notifyRemote: notifyRemote)
        } else {
            QL2("Couldn't update list item quantity because it's not in the table view")
        }
    }
    
    fileprivate func findIndexInItems(_ listItem: ListItem) -> Int? {
        for (index, item) in items.enumerated() {
            if item.same(listItem) {
                return index
            }
        }
        return nil
    }
    
    fileprivate func replaceItemAndRebuildTable(_ listItem: ListItem) {
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
    func updateOrAddListItem(_ listItem: ListItem, status: ListItemStatus, increment: Bool, scrollToSelection: Bool = false, notifyRemote: Bool) {
        
        guard listItem.hasStatus(self.status) else {return} // with websockets it can be that if 2 list items controllers are active at the same time (e.g. when we are in cart) we receive list items here which don't have quantity in the status of this controller, so there's nothing to do in this method. This guard is required for the method to function correctly (otherwise item is appended at the end of table if not found).
        
        if let indexPath = getIndexPath(listItem) {
        
            let oldItem = tableViewSections[(indexPath as NSIndexPath).section].tableViewListItems[(indexPath as NSIndexPath).row]
        
            if self.status != status {
                // the item is in this tableview but has now a new status - delete (swipe) it from tableview. This is used by websockets
                // when another user e.g. sends to item to cart we want to show the receiving users the item being "swiped" and then deleted
                markOpen(true, indexPath: indexPath, notifyRemote: notifyRemote) {[weak self] in // swipe
                    self?.clearPendingSwipeItemIfAny(notifyRemote) // delete
                }
                
            } else {
                
                var finalIndexPath: IndexPath?
                
                if (oldItem.listItem.section.same(listItem.section)) { // item is already in table view and also has same section
                    replaceItemAndRebuildTable(listItem)
                    finalIndexPath = indexPath // item is in the same place as before
                    
                } else { // the item is already in table view but has a different section
                    //update item and rebuild table, which organises sections
                    replaceItemAndRebuildTable(listItem)
                    finalIndexPath = getIndexPath(listItem) // since the item changed section the index path is now different, get it again
                }
                
                if scrollToSelection {
                    if let finalIndexPath = finalIndexPath {
                        tableView.scrollToRow(at: finalIndexPath, at: .top, animated: true)
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
                    tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
        }
    }
    
    // Returns a string representing current sections with listitems
    fileprivate func debugTableViewListItems() -> String {
        return tableViewSections.reduce("") {str, section in
            let sectionListItemsStr = section.tableViewListItems.reduce("") {str, tableViewListItem in
                return "\(str)\t\(tableViewListItem)\n"
            }
            return "(\(str)\(section.section.shortOrderDebugDescription)):\n[\(sectionListItemsStr)]"
        }
    }

    // Returns a string representing current sections with listitems - focus: order
    fileprivate func debugTableViewListItemsOrder() -> String {
        return tableViewSections.reduce("") {str, section in
            let sectionListItemsStr = section.tableViewListItems.reduce("") {str, tableViewListItem in
                return "\(str)\t\(tableViewListItem.listItem.shortOrderDebugDescription)\n"
            }
            return "\(str)\(section.section.shortOrderDebugDescription):\n[\(sectionListItemsStr)]"
        }
    }
    
    // Updates a section based on identity (uuid). Note that this isn't usable for order update, as updating order requires to update the order field of sections below
    func updateSection(_ section: Section) {
        
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

    func updateSections(_ sections: [Section]) {
        
        let sectionsDict = sections.toDictionary{($0.uuid, $0)}
        
        // This is maybe not the most performant way to do this update but it guarantees consistency as it uses the "official" entry point to initialise the table, which is setListItems
        let updatedItems: [ListItem] = items.map{item in
            if let section = sectionsDict[item.section.uuid] {
                return item.copy(section: section, note: nil)
            } else {
                return item
            }
        }
        setListItems(updatedItems)
    }
    
    // loops through list items to generate tableview sections, returns also found sections so we don't have to loop 2x
    fileprivate func buildTableViewSections(_ listItems: [ListItem]) -> (tableViewSections:[ListItemsViewSection], sections:[Section]) {
        var tableViewSections:[ListItemsViewSection] = []
        var sections:[Section] = []
        
        if !listItems.isEmpty {
            var set = [String: Int]() // "set" for quick lookup which sections we added already
            

            var currentTableViewSection:ListItemsViewSection!
            
            for listItem in listItems {
                
                let tableViewListItem = TableViewListItem(listItem: listItem)

                if set[listItem.section.uuid] == nil { // section not created yet - create one
                    set[listItem.section.uuid] = 1 // dummy value... swift doesn't have Set

                    sections.append(listItem.section)
                    
                    currentTableViewSection = ListItemsViewSection(section: listItem.section, tableViewListItems: [], status: status)
                    currentTableViewSection.cellMode = cellMode
                    currentTableViewSection.cellSwipeDirection = cellSwipeDirection
                    currentTableViewSection.delegate = self
                    currentTableViewSection.expanded = sectionsExpanded

                    if self.style == .gray {
                        currentTableViewSection.style = .gray
                    }
                    tableViewSections.append(currentTableViewSection)
                    
                } else { //the section is in the set, this means it's in the tableViewSections. find it
                    for tableViewSection in tableViewSections {
                        if tableViewSection.section.same(listItem.section) {
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
    func removeListItem(_ listItem: ListItem, animation: UITableViewRowAnimation = .bottom) {
        if let indexPath = self.getIndexPath(listItem) {
            self.removeListItem(listItem, indexPath: indexPath, animation: animation)
        }
    }
    
    func removeListItem(uuid: String, animation: UITableViewRowAnimation = .bottom) {
        if let indexPath = self.getIndexPath(listItemUuid: uuid) {
            self.removeListItem(uuid, indexPath: indexPath, animation: animation)
        }
    }

    fileprivate func removeListItem(_ listItem: ListItem, indexPath: IndexPath, animation: UITableViewRowAnimation = .bottom) {
        removeListItem(uuid: listItem.uuid, animation: animation)
    }
    
    // Special entry point for reactive delete (Realm) - since after the item has been deleted from db it's marked as "invalid" attempting to access it (e.g. to get the uuid) causes a crash. So we have to work with index only. An alternative solution would be to store the uuid of item being deleted somewhere and use it when we get the notification. We try first with index and see how it goes.
    func removeListItem(index: Int, animation: UITableViewRowAnimation = .bottom) {
        
        func findIndexPath(index: Int) -> IndexPath? {
            var count = 0
            for (i, s) in tableViewSections.enumerated() {
                if index < count + s.tableViewListItems.count {
                    return IndexPath(row: index - count, section: i)
                } else {
                    count += s.tableViewListItems.count
                }
            }
            QL2("No index path for index: \(index)")
            return nil
        }
        
        if let indexPath = findIndexPath(index: index) {
            QL1("Found list item for index: \(index), item: \(indexPath)")
            removeListItem(index: index, indexPath: indexPath, animation: animation)
        } else {
            QL4("Didn't find index path for index: \(index)")
        }
    }
    
    // TODO return bool
    fileprivate func removeListItem(_ listItemUuid: String, indexPath: IndexPath, animation: UITableViewRowAnimation = .bottom) {
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
        
        removeListItem(index: indexMaybe, indexPath: indexPath, animation: animation)
    }
    
    fileprivate func removeListItem(index: Int?, indexPath: IndexPath, animation: UITableViewRowAnimation) {
        if let index = index {
            // remove from model
            self.items.remove(at: index)
            let tableViewSection = self.tableViewSections[indexPath.section]
            tableViewSection.tableViewListItems.remove(at: indexPath.row)
            
            // remove from table view
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: animation)
            
            // remove section if no items
            if tableViewSection.tableViewListItems.isEmpty {
                removeSection(tableViewSection.section.uuid, indexPath: indexPath, animation: animation)
            }
            self.tableView.endUpdates()
        }
    }
    
    // TODO we are iterating multiple times through listitems, once to find the product and in removeListItem...
    func removeListItemReferencingProduct(quantifiableProductUuid: String) {
        if let (tableViewListItem, _) = findFirstListItemWithIndexPath({$0.product.uuid == quantifiableProductUuid}) {
            removeListItem(tableViewListItem.listItem)
        } else {
            QL1("removeListItemReferencingProduct list item is not in list items table view. Quantifiable product uuid: \(quantifiableProductUuid)")
        }
    }

    func removeListItemsReferencingCategory(_ categoryUuid: String) {
        for (tableViewListItem, _) in findListItemsWithIndexPath({$0.product.product.product.item.category.uuid == categoryUuid}) {
            removeListItem(tableViewListItem.listItem)
        }
    }
    
    // Used by websocket, when receiving a notification of an updated product
    func updateProduct(_ product: Product, status: ListItemStatus) {
        fatalError("disabled")
        // Commented because structural changes
//        if let (tableViewListItem, _) = findFirstListItemWithIndexPath({$0.product.product.uuid == product.uuid}) {
//            let updated = tableViewListItem.listItem.update(product: product)
//            updateListItem(updated, status: status, notifyRemote: false)
//        } else {
//            QL1("updateProduct list item is not in list items table view. Product uuid: \(product.uuid)")
//        }
    }
    
    // TODO why do we need indexPath and have to look for the index in the sections array using uuid, shouldn't both have the same index?
    fileprivate func removeSection(_ uuid: String, indexPath: IndexPath, animation: UITableViewRowAnimation = .bottom) {
        tableView.wrapUpdates {[weak self] in guard let weakSelf = self else {return}
            // remove table view section
            weakSelf.tableViewSections.remove(at: (indexPath as NSIndexPath).section)
            // remove model section TODO better way
            let sectionIndexMaybe: Int? = weakSelf.getSectionIndex(uuid)
            if let sectionIndex = sectionIndexMaybe {
                weakSelf.sections.remove(at: sectionIndex)
                // remove from table view
                weakSelf.tableView.deleteSections(IndexSet(integer: sectionIndex), with: animation)
            }
        }
    }
    
    func removeSection(_ uuid: String) {
        if let indexPath = getSectionIndexPath(uuid) {
            removeSection(uuid, indexPath: indexPath)
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
        
//        let velocity = scrollView.panGestureRecognizer.velocityInView(scrollView.superview)
//        let scrollingUp = (velocity.y < 0)
        
        clearPendingSwipeItemIfAny(true)
    }
    
    func getIndexPath(listItemUuid: String) -> IndexPath? {
        for (sectionIndex, s) in self.tableViewSections.enumerated() {
            for (listItemIndex, l) in s.tableViewListItems.enumerated() {
                if (listItemUuid == l.listItem.uuid) {
                    let indexPath = IndexPath(row: listItemIndex, section: sectionIndex)
                    return indexPath
                }
            }
        }
        return findListItemsWithIndexPath{$0.uuid == listItemUuid}.first.map{$0.indexPath}
    }

    func getItem(_ listItemUuid: String) -> TableViewListItem? {
        for s in self.tableViewSections {
            for l in s.tableViewListItems {
                if (listItemUuid == l.listItem.uuid) {
                    return l
                }
            }
        }
        return nil
    }
    
    fileprivate typealias TableViewListItemWithIndexPath = (item: TableViewListItem, indexPath: IndexPath)

    fileprivate func findFirstListItemWithIndexPath(_ filter: (ListItem) -> Bool) -> TableViewListItemWithIndexPath? {
        return findListItemsWithIndexPath(filter).first
    }
    
    fileprivate func findListItemsWithIndexPath(_ filter: (ListItem) -> Bool) -> [TableViewListItemWithIndexPath] {
        var arr: [TableViewListItemWithIndexPath] = []
        for (sectionIndex, s) in self.tableViewSections.enumerated() {
            for (listItemIndex, l) in s.tableViewListItems.enumerated() {
                if (filter(l.listItem)) {
                    let indexPath = IndexPath(row: listItemIndex, section: sectionIndex)
                    arr.append((l, indexPath))
                }
            }
        }
        return arr
    }
    
    func getIndexPath(_ listItem: ListItem) -> IndexPath? {
        return getIndexPath(listItemUuid: listItem.uuid)
    }
    
    func getIndex(_ section: Section) -> Int? {
        return getSectionIndex(section.uuid)
    }
    
    func getSectionIndex(_ uuid: String) -> Int? {
        for (index, s) in self.sections.enumerated() {
            if uuid == s.uuid {
                return index
            }
        }
        return nil
    }
    
    func getSectionIndexPath(_ uuid: String) -> IndexPath? {
        for (sectionIndex, s) in self.tableViewSections.enumerated() {
            if (uuid == s.section.uuid) {
                return IndexPath(row: 0, section: sectionIndex)
            }
        }
        return nil
    }
    
    /**
    Submits item marked as "undo" if there is any
    - parameter: onFinish optional callback to execute after submitting (this may e.g. call a provider). If there's no pending item, this is not called.
    */
    func clearPendingSwipeItemIfAny(_ notifyRemote: Bool, onFinish: VoidFunction? = nil) {
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
    
    func startItemSwipe(_ tableViewListItem: TableViewListItem) {
        clearPendingSwipeItemIfAny(true)
    }
    
    func endItemSwipe(_ tableViewListItem: TableViewListItem) {
//        let allListItems = self.tableViewSections.map {
//            $0.listItems
//            }.reduce([], combine: +)
     
        // TODO call also onListItemSelected here? (like in selection)
        self.swipedTableViewListItem = tableViewListItem
    }
    
    func undoSwipe(_ tableViewListItem: TableViewListItem) {
        listItemsTableViewDelegate?.onListItemReset(tableViewListItem)
        self.swipedTableViewListItem = nil
    }

    func onNoteTap(_ cell: ListItemCell, tableViewListItem: TableViewListItem) {
        if !tableViewListItem.listItem.note.isEmpty {
            
            // use parent controller otherwise popup scrolls with the table
            if let parentController = parent {
                let noteButton = cell.noteButton
                
                let topOffset: CGFloat = 64
                let frame = parentController.view.bounds.copy(y: topOffset, height: parentController.view.bounds.height)
                
                let noteButtonPointParentController = parentController.view.convert(CGPoint(x: (noteButton?.center.x)!, y: (noteButton?.center.y)!), from: cell)
                // adjust the anchor point also for topOffset
                let buttonPointWithOffset = noteButtonPointParentController.copy(y: noteButtonPointParentController.y - topOffset)
                
                AlertPopup.showCustom(message: tableViewListItem.listItem.note, controller: parentController, frame: frame, rootControllerStartPoint: buttonPointWithOffset)
            } else {
                QL3("No parent controller, can't show note popup")
            }
            
            
            
        } else {
            print("Error: Invalid state in onNoteTap. There's no note. When there's no note there should be no button so we shouldn't be here.")
        }
    }
    
    func onMinusTap(_ tableViewListItem: TableViewListItem) {
        listItemsTableViewDelegate?.onIncrementItem(tableViewListItem, delta: -1)
        SwipeToIncrementAlertHelper.check(self)
    }
    
    func onPlusTap(_ tableViewListItem: TableViewListItem) {
        listItemsTableViewDelegate?.onIncrementItem(tableViewListItem, delta: 1)
        SwipeToIncrementAlertHelper.check(self)
    }
    
    func onHeaderTap(_ header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        listItemsTableViewDelegate?.onSectionHeaderTap(header, section: section)
    }
    
    func onPanQuantityUpdate(_ tableViewListItem: TableViewListItem, newQuantity: Float) {
        listItemsTableViewDelegate?.onIncrementItem(tableViewListItem, delta: newQuantity - tableViewListItem.listItem.quantity(status))
    }
    
    func setAllSectionsExpanded(_ expanded: Bool, animated: Bool, onComplete: VoidFunction? = nil) {
        
        var completed = 0
        for (index, section) in tableViewSections.enumerated() {
            setSectionExpanded(expanded, sectionIndex: index, section: section, animated: animated, onComplete: {[weak self] in
                completed += 1
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
    fileprivate func setSectionExpanded(_ expanded: Bool, sectionIndex: Int, section: ListItemsViewSection, animated: Bool, onComplete: VoidFunction? = nil) {
        
        let sectionIndexPaths: [IndexPath] = (0..<section.tableViewListItems.count).map {
            return IndexPath(row: $0, section: sectionIndex)
        }
        
        if let onComplete = onComplete {
            CATransaction.setCompletionBlock(onComplete)
        }

        if expanded {
            tableView.wrapUpdates {[weak self] in
                self?.tableView.insertRows(at: sectionIndexPaths, with: .top)
                section.expanded = true
            }
        } else {
            tableView.wrapUpdates {[weak self] in
                self?.tableView.deleteRows(at: sectionIndexPaths, with: .top)
                section.expanded = false
            }
        }
    }
    
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.isEditing
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.tableViewSections[section].viewForHeader()
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return self.tableViewSections[section].viewForFooter()
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat(self.tableViewSections[section].heightForFooter())
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(self.tableViewSections[section].heightForHeader())
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewSections[section].numberOfRows()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableViewSections.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = self.tableViewSections[(indexPath as NSIndexPath).section]
        return section.heightForRow((indexPath as NSIndexPath).row)
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = self.tableViewSections[(indexPath as NSIndexPath).section]
        return section.tableView(tableView, row:(indexPath as NSIndexPath).row)
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableViewListItem = self.tableViewSections[(indexPath as NSIndexPath).section].tableViewListItems[(indexPath as NSIndexPath).row]
        self.listItemsTableViewDelegate?.onListItemSelected(tableViewListItem, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            self.tableView.beginUpdates()

            // remove from tableview and model
            let listItem = self.tableViewSections[(indexPath as NSIndexPath).section].tableViewListItems[(indexPath as NSIndexPath).row]
            self.removeListItem(listItem.listItem, indexPath: indexPath, animation: UITableViewRowAnimation.bottom)

            // remove from content provider
            self.listItemsEditTableViewDelegate?.onListItemDeleted(listItem)

            self.tableView.endUpdates()
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return self.isEditing
    }

    /**
    Sets pending item (mark as undo" if open and shows cell open state. Submits currently pending item if existent.
    parameter onFinish: After cell marked open and automatic update of possible second "undo" item (to "done").
     // TODO!!!! remove notify remote parameter, this is necessary anymore
    */
    func markOpen(_ open: Bool, indexPath: IndexPath, notifyRemote: Bool, onFinish: VoidFunction? = nil) {
        if let section = self.tableViewSections[safe: (indexPath as NSIndexPath).section], let tableViewListItem = section.tableViewListItems[safe: (indexPath as NSIndexPath).row] {
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
    
    fileprivate func showCellOpen(_ open: Bool, indexPath: IndexPath) {
        if let swipeableCell = tableView.cellForRow(at: indexPath) as? SwipeableCell {
            if let section = tableViewSections[safe: (indexPath as NSIndexPath).section] {
                if section.tableViewListItems[safe: (indexPath as NSIndexPath).row] != nil {
                    section.tableViewListItems[(indexPath as NSIndexPath).row].swiped = open
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

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        do {
            if sourceIndexPath != destinationIndexPath {
                
                let srcSection = self.tableViewSections[(sourceIndexPath as NSIndexPath).section]
                let tableViewListItem = srcSection.tableViewListItems[(sourceIndexPath as NSIndexPath).row]
                srcSection.tableViewListItems.remove(at: (sourceIndexPath as NSIndexPath).row)
                
                let dstSection = self.tableViewSections[(destinationIndexPath as NSIndexPath).section]
                
                try Realm().write {
                    tableViewListItem.listItem.section = dstSection.section
                    
                    //        let absoluteRow = tableView.absoluteRow(destinationIndexPath)
                    dstSection.tableViewListItems.insert(tableViewListItem, at: (destinationIndexPath as NSIndexPath).row)
                    
                    // updates list item models with current ordering in table view
                    for section in self.tableViewSections {
                        for (listItemIndex, tableViewListItem) in section.tableViewListItems.enumerated() {
                            tableViewListItem.listItem.updateOrderMutable(ListItemStatusOrder(status: status, order: listItemIndex))
                        }
                    }
                }

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
            
        } catch let e {
            QL4("Realm error: \(e)")
        }
    }
    
    
    func hasSectionWith(_ f: (Section) -> Bool) -> Bool {
        return tableViewSections.contains(where: {tableViewSection in
            f(tableViewSection.section)
        })
    }
    
    func scrollToListItem(_ litsItem: ListItem) {
        if let indexPath = getIndexPath(litsItem) {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        } else {
            QL2("Didn't find list item to scroll to")
        }
    }
}
