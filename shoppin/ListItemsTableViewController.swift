//
//  ListItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 24.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

protocol ListItemsTableViewDelegate {
    func onListItemClear(tableViewListItem: TableViewListItem, onFinish: VoidFunction) // submit item marked as undo
    func onListItemSelected(tableViewListItem: TableViewListItem, indexPath: NSIndexPath) // mark as undo
    func onListItemReset(tableViewListItem: TableViewListItem) // revert undo
}

protocol ListItemsEditTableViewDelegate {
    func onListItemsChangedSection(tableViewListItems:[TableViewListItem])
    func onListItemDeleted(tableViewListItem:TableViewListItem)
}

enum ListItemsTableViewControllerStyle {
    case Normal, Gray
}

class ListItemsTableViewController: UITableViewController, ItemActionsDelegate {
    
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section
    private(set) var tableViewSections:[ListItemsViewSection] = []
    
    private var lastContentOffset:CGFloat = 0
    
    var scrollViewDelegate:UIScrollViewDelegate?
    var listItemsTableViewDelegate:ListItemsTableViewDelegate?
    var listItemsEditTableViewDelegate:ListItemsEditTableViewDelegate?

    private(set) var sections:[Section] = [] // quick access. Sorting not necessarily same as in tableViewSections
    private(set) var items:[ListItem] = [] // quick access. Sorting not necessarily same as in tableViewSections
    
    var style:ListItemsTableViewControllerStyle = .Normal
    
    private var swipedTableViewListItem: TableViewListItem? // Item marked for "undo". Item is not submitted until undo state is cleared
    
    var headerBGColor: UIColor?
    
    func touchEnabled(enabled:Bool) {
        self.tableView.userInteractionEnabled = enabled
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
    
    func setListItems(items:[ListItem]) { // as function instead of variable+didSet because didSet is called each time we modify the array
        self.items = items
        self.initTableViewContent()
    }
    
    private func initTableViewContent() {
        let(tableViewSections, sections) = self.buildTableViewSections(self.items)
        self.tableViewSections = tableViewSections
        self.sections = sections
        
        if let headerBGColor = headerBGColor {
            for section in tableViewSections {
                section.headerBGColor = headerBGColor
                section.headerFontColor = UIColor(contrastingBlackOrWhiteColorOn: headerBGColor, isFlat: true)
            }
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
            let tableViewSection = ListItemsViewSection(section: listItem.section, tableViewListItems: [tableViewListItem], hasHeader: hasHeader)
            tableViewSection.delegate = self
            self.tableViewSections.append(tableViewSection)
        }
    }

    /**
    Update or add list item
    When sure it's an "add" case use addListItem - this checks first if the item exists and is thus slower
    */
    func updateListItem(listItem: ListItem) {
        updateOrAddListItem(listItem, increment: false) // update means overwrite - don't increment
    }
    
    // TODO simpler way to update, maybe just always reinit the table... also refactor rest (build sections etc) it is way more complex than it should
    // right now prefer not to always reinit the table because this can change sorting
    // so first we should implement persistent sorting, then refactor this class
    // -parameter: increment if, in case it's an update, the quantities of the items should be added together. If false the quantity is just overwritten like the rest of fields
    func updateOrAddListItem(listItem: ListItem, increment: Bool, scrollToSelection: Bool = false) {
        if let indexPath = getIndexPath(listItem) {
            let oldItem = tableViewSections[indexPath.section].tableViewListItems[indexPath.row]

            if (oldItem.listItem.section == listItem.section) {
                tableViewSections[indexPath.section].tableViewListItems[indexPath.row] = TableViewListItem(listItem: listItem)
                tableView.reloadData()
            } else { // the item has a different (but present in tableview) section
                //update the list item before we reinit the table, to update the section...
                var itemIndexMaybe:Int?
                for (index, item) in items.enumerate() {
                    if item.uuid == listItem.uuid {
                        itemIndexMaybe = index
                    }
                }
                if let itemIndex = itemIndexMaybe {
                    items[itemIndex] = listItem
                    
                    initTableViewContent()
                }
            }
            
            if scrollToSelection {
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: true)
            }
            
        } else { // indexpath for updated item not in the tableview, this can happen if e.g. updated item has a new section (not in tableview)
            items.append(listItem) // FIXME hacky...
            initTableViewContent() // this will make the possible new section appear
            
            if scrollToSelection {
                let lastIndexPath = NSIndexPath(forRow: tableViewSections[tableViewSections.count - 1].tableViewListItems.count - 1, inSection: tableViewSections.count - 1)
                tableView.scrollToRowAtIndexPath(lastIndexPath, atScrollPosition: .Middle, animated: true)
            }
        }
    }
    
    // loops through list items to generate tableview sections, returns also found sections so we don't have to loop 2x
    private func buildTableViewSections(listItems:[ListItem]) -> (tableViewSections:[ListItemsViewSection], sections:[Section]) {
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
                    
                    currentTableViewSection = ListItemsViewSection(section: listItem.section, tableViewListItems: [])
                    currentTableViewSection.delegate = self

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
    func removeListItem(listItem:ListItem, animation:UITableViewRowAnimation) {
        
        if let indexPath = self.getIndexPath(listItem) {
            self.removeListItem(listItem, indexPath: indexPath, animation: animation)
        }
    }
    
    // TODO return bool
    private func removeListItem(listItem:ListItem, indexPath:NSIndexPath, animation:UITableViewRowAnimation) {
        // TODO review this, we store items reduntantely, so find index in one list, remove, use indexPath for the other list....
        // also is it thread safe to pass indexpath like this
        // paramater indexPath and listitem?
        var indexMaybe:Int?
        for i in 0...self.items.count {
            if self.items[i] == listItem {
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
                // remove table view section
                self.tableViewSections.removeAtIndex(indexPath.section)
                // remove model section TODO better way
                let sectionIndexMaybe: Int? = getIndex(tableViewSection.section)
                if let sectionIndex = sectionIndexMaybe {
                    self.sections.removeAtIndex(sectionIndex)
                    self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: animation)
                }
            }
            self.tableView.endUpdates()
        }
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
        
//        let velocity = scrollView.panGestureRecognizer.velocityInView(scrollView.superview)
//        let scrollingUp = (velocity.y < 0)
        
        clearPendingSwipeItemIfAny()
    }
    
    func getIndexPath(listItem: ListItem) -> NSIndexPath? {
        for (sectionIndex, s) in self.tableViewSections.enumerate() {
            for (listItemIndex, l) in s.tableViewListItems.enumerate() {
                if (listItem.same(l.listItem)) { // find by only uuid
                    let indexPath = NSIndexPath(forRow: listItemIndex, inSection: sectionIndex)
                    return indexPath
                }
            }
        }
        return nil
    }
    
    func getIndex(section: Section) -> Int? {
        for (index, s) in self.sections.enumerate() {
            if section.same(s) {
                return index
            }
        }
        return nil
    }
    
    
    /**
    Submits item marked as "undo" if there is any
    - parameter: onFinish optional callback to execute after submitting (this may e.g. call a provider). If there's no pending item, this is not called.
    */
    func clearPendingSwipeItemIfAny(onFinish: VoidFunction? = nil) {
        if let s = self.swipedTableViewListItem {
            
            listItemsTableViewDelegate?.onListItemClear(s) {
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
        clearPendingSwipeItemIfAny()
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
    
    func onHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        if let sectionIndex = getIndex(section.section) {
            toggleSectionExpanded(sectionIndex, section: section)
        } else {
            print("Error: ListItemsTableViewController.onHeaderTap: Invalid state: No section index found for section, which is in table view")
        }
    }
    
    private func toggleSectionExpanded(sectionIndex: Int, section: ListItemsViewSection) {
        
        let sectionIndexPaths: [NSIndexPath] = (0..<section.tableViewListItems.count).map {
            return NSIndexPath(forRow: $0, inSection: sectionIndex)
        }
        
        if section.expanded { // collapse
            tableView.wrapUpdates {[weak self] in
                self?.tableView.deleteRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
                section.expanded = false
            }
        } else { // expand
            tableView.wrapUpdates {[weak self] in
                self?.tableView.insertRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
                section.expanded = true
            }
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: sectionIndex), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
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
    func markOpen(open: Bool, indexPath: NSIndexPath, onFinish: VoidFunction? = nil) {
        if let section = self.tableViewSections[safe: indexPath.section], tableViewListItem = section.tableViewListItems[safe: indexPath.row] {
            // Note: order is important here! first show open at current index path, then remove possible pending (which can make indexPath invalid, thus later), then update pending variable with new item
            self.showCellOpen(open, indexPath: indexPath)
            self.clearPendingSwipeItemIfAny {
                self.swipedTableViewListItem = tableViewListItem
                onFinish?()
            }
            
        } else {
            print("Warning: markOpen: \(open), self not set or indexPath not found: \(indexPath)")
        }
    }
    
    private func showCellOpen(open: Bool, indexPath: NSIndexPath) {
        if let swipeableCell = tableView.cellForRowAtIndexPath(indexPath) as? SwipeableCell {
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
                tableViewListItem.listItem.order = listItemIndex
            }
            sectionRows += section.numberOfRows()
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
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
        
        self.listItemsEditTableViewDelegate?.onListItemsChangedSection(modifiedListItems)
    }
}
