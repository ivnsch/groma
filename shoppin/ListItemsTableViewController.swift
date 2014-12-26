//
//  ListItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 24.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

protocol ListItemsTableViewDelegate {
    func onListItemDoubleTap(listItem:ListItem, indexPath:NSIndexPath)
}

enum ListItemsTableViewControllerStyle {
    case Normal, Gray
}

class ListItemsTableViewController: UITableViewController, UIScrollViewDelegate {
    
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section
    private var tableViewSections:[ListItemsViewSection] = []
    
    private var lastContentOffset:CGFloat = 0
    
    var scrollViewDelegate:UIScrollViewDelegate?
    var listItemsTableViewDelegate:ListItemsTableViewDelegate?
    
    private(set) var sections:[Section] = [] // quick access. Sorting not necessarily same as in tableViewSections
    private(set) var items:[ListItem] = [] // quick access. Sorting not necessarily same as in tableViewSections
    
    var style:ListItemsTableViewControllerStyle = .Normal
    
    var tableViewTopInset:CGFloat {
        set {
            self.tableView.contentInset = UIEdgeInsetsMake(newValue, 0, 0, 0)
            
            //TODO do we need this
            self.tableView.setNeedsLayout()
            self.tableView.layoutIfNeeded()
        }
        get {
            return self.tableView.contentInset.top
        }
    }
    
    var tableViewTopOffset:CGFloat {
        set {
            self.tableView.contentOffset = CGPointMake(0, newValue)
        }
        get {
            return self.tableView.contentOffset.y
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableView()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTapGesture:")
        tapGesture.numberOfTapsRequired = 2
        self.tableView.addGestureRecognizer(tapGesture)
    }
    
    
    override func viewWillLayoutSubviews() {
//        println(self.view.constraints().count)
    }
    
    private func initTableView() {
        self.tableView.registerClass(ListItemCell.self, forCellReuseIdentifier: ItemsListTableViewConstants.listItemCellIdentifier)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
    }
    
    func setListItems(items:[ListItem]) { // as function instead of variable+didSet because didSet is called each time we modify the array
        self.items = items
        let(tableViewSections, sections) = self.buildTableViewSections(self.items)
        self.tableViewSections = tableViewSections
        self.sections = sections
        self.tableView.reloadData()
    }
    
    func addListItem(listItem:ListItem) {
        self.items.append(listItem)
        
        self.addListItemToSection(listItem)
        
        self.tableView.reloadData()
    }
    
    private func addListItemToSection(listItem:ListItem) {
        let foundSectionMaybe = self.tableViewSections.filter({ (s:ListItemsViewSection) -> Bool in
            s.section == listItem.section
        }).first
        
        if let foundSection = foundSectionMaybe {
            foundSection.addItem(listItem)
        } else {
            let hasHeader = listItem.section.name != defaultSectionIdentifier
            self.sections.append(listItem.section)
            self.tableViewSections.append(ListItemsViewSection(section: listItem.section, listItems: [listItem], hasHeader: hasHeader))
        }
    }
    
    // loops through list items to generate tableview sections, returns also found sections so we don't have to loop 2x
    // assumes the items are grouped by section (items with section A, then items with section B, etc.)
    private func buildTableViewSections(listItems:[ListItem]) -> (tableViewSections:[ListItemsViewSection], sections:[Section]) {
        var tableViewSections:[ListItemsViewSection] = []
        var sections:[Section] = []
        
        if !listItems.isEmpty {
            var set = [Section: Int]() // a "set" for quick lookup which sections we added already
            
            //we don't need to initialise this variable here but compiler complains otherwise...
            var currentSection:ListItemsViewSection = ListItemsViewSection(section: listItems.first!.section, listItems: [])
            
            //go through all the items, create new section when we find one, add following items to the current section until we find new one
            //o(n)
            for item in listItems {
                if set[item.section] == nil {
                    set[item.section] = 1 // dummy value... swift doesn't have Set
                    sections.append(item.section)
                    
                    currentSection = ListItemsViewSection(section: item.section, listItems: [])
                    if self.style == .Gray {
                        currentSection.style = .Gray
                    }
                    tableViewSections.append(currentSection)
                }
                currentSection.addItem(item)
            }
        }
        
        return (tableViewSections, sections)
    }
    
    func removeListItem(listItem:ListItem, indexPath:NSIndexPath) {
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
            self.items.removeAtIndex(index)
            let tableViewSection = self.tableViewSections[indexPath.section]
            tableViewSection.listItems.removeAtIndex(indexPath.row)
            
            if tableViewSection.listItems.isEmpty {
                // remove table view section
                self.tableViewSections.removeAtIndex(indexPath.section)
                // remove model section TODO better way
                var sectionIndexMaybe:Int?
                for (index, section) in enumerate(self.sections) {
                    if section == tableViewSection.section {
                        sectionIndexMaybe = index
                    }
                }
                if let sectionIndex = sectionIndexMaybe {
                    self.sections.removeAtIndex(sectionIndex)
                }
            }
        }
        
        self.tableView.reloadData()
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    func handleTapGesture(sender:UITapGestureRecognizer) {
        let tapLocation = sender.locationInView(self.tableView)
        let indexPathMaybe:NSIndexPath? = self.tableView.indexPathForRowAtPoint(tapLocation)
        
        if let indexPath = indexPathMaybe {
            let listItem:ListItem = self.tableViewSections[indexPath.section].listItems[indexPath.row]
            listItemsTableViewDelegate?.onListItemDoubleTap(listItem, indexPath: indexPath)
        }
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
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
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            //            self.toggleItemDone(self.sections[indexPath.section].listItems[indexPath.row])
        }
    }
}
