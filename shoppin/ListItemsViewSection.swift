//
//  ProductsTableViewSection.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

enum ListItemsViewSectionStyle {
    case Normal, Gray
}

protocol ItemActionsDelegate {
    func startItemSwipe(tableViewListItem: TableViewListItem)
    func endItemSwipe(tableViewListItem: TableViewListItem)
    func undoSwipe(tableViewListItem: TableViewListItem)
    func onNoteTap(tableViewListItem: TableViewListItem)
    func onHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection)
    func onMinusTap(tableViewListItem: TableViewListItem)
    func onPlusTap(tableViewListItem: TableViewListItem)
}

class ListItemsViewSection: NSObject, ListItemsSectionHeaderViewDelegate {
    
    var tableViewListItems: [TableViewListItem]
    
    private let cellIdentifier = ItemsListTableViewConstants.listItemCellIdentifier
    
    var headerBGColor: UIColor = UIColor(red: 167/255, green: 1, blue: 93/255, alpha: 1)
    var headerFontColor: UIColor = UIColor.blackColor()
    var labelFontColor: UIColor = UIColor.blackColor()
    
    var section: Section // as var to mutate order in-place (ListItemsTableViewController)
    
    var expanded: Bool = true
    let status: ListItemStatus
    
    private let hasHeader: Bool
    
    var style: ListItemsTableViewControllerStyle = .Normal

    var delegate: ItemActionsDelegate!
    
    private let headerFont = Fonts.regular

    var cellMode: ListItemCellMode = .Note
    
    // this could be solved maybe with inheritance or sth like "style injection", for now this is ok
    private var finalLabelFontColor:UIColor {
        var color:UIColor
//        if self.style == .Gray {
//            color = UIColor.lightGrayColor()
//        } else {
            color = self.labelFontColor
//        }
        return color
    }
    
    private var finalHeaderBGColor: UIColor {
        var color:UIColor
        if self.style == .Gray {
            color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        } else {
            color = self.headerBGColor
        }
        return color
    }
    
    private var finalHeaderFontColor: UIColor {
        var color:UIColor
//        if self.style == .Gray {
//            color = UIColor.grayColor()
//        } else {
            color = self.headerFontColor
//        }
        return color
    }
    
    
    init(section: Section, tableViewListItems:[TableViewListItem], hasHeader: Bool = true, status: ListItemStatus) {
        self.section = section
        self.tableViewListItems = tableViewListItems
        self.hasHeader = hasHeader
        self.status = status
    }
    
    func heightForHeader() -> Float {
        return self.hasHeader ? 30 : 0
    }
    
    func heightForFooter() -> Float {
        return 0
    }
    
    func cellReuseIdentifierForRow(row:Int) -> String {
        return cellIdentifier
    }
    
    func viewForHeader() -> UIView? {
        if self.hasHeader {
            let view = NSBundle.loadView("ListItemsSectionHeaderView", owner: self) as! ListItemsSectionHeaderView
            view.section = section
            view.backgroundColor = finalHeaderBGColor
            view.nameLabel.textColor = finalHeaderFontColor
            view.nameLabel.font = headerFont
            view.delegate = self
            return view
        } else {
            return nil
        }
    }
    
    func viewForFooter() -> UIView? {
        return nil
    }
    
    func heightForRow(row: Int) -> CGFloat {
        return 50
    }
    
    //    func cellsToRegister() -> NSSet {
    //        return NSSet()
    //    }
    
    
    
    func tableView(tableView: UITableView, row: NSInteger) -> UITableViewCell {

        let cell:ListItemCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ListItemCell
        cell.showsReorderControl = true
        
        let tableViewListItem = tableViewListItems[row]
        
        
        cell.nameLabel.text = NSLocalizedString(tableViewListItem.listItem.product.name, comment: "")
        cell.quantityLabel.text = String(tableViewListItem.listItem.quantity(status))
        
        cell.labelColor = self.finalLabelFontColor
//        cell.delegate = self
        cell.itemSwiped = {[weak self] in // use a closure to capture listitem
            self?.delegate.endItemSwipe(tableViewListItem)
        }
        cell.startItemSwipe = {[weak self] in
            self?.delegate.startItemSwipe(tableViewListItem)
        }
        cell.buttonTwoTap = {[weak self] in
            self?.delegate.undoSwipe(tableViewListItem)
        }
        cell.onNoteTapFunc = {[weak self] in
            self?.delegate.onNoteTap(tableViewListItem)
        }
        cell.onMinusTapFunc = {[weak self] in
            self?.delegate.onMinusTap(tableViewListItem)
        }
        cell.onPlusTapFunc = {[weak self] in
            self?.delegate.onPlusTap(tableViewListItem)
        }
        
        cell.mode = cellMode

        let hasNote = tableViewListItem.listItem.note.map{!$0.isEmpty} ?? false
        cell.noteButton.hidden = cellMode != .Note || !hasNote

        cell.setOpen(tableViewListItem.swiped)
        if tableViewListItem.swiped {
            cell.backgroundColor = UIColor.clearColor()
        } else {
            cell.backgroundColor = UIColor.whiteColor()
        }
        
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    func numberOfRows() -> Int {
        return expanded ? tableViewListItems.count : 0
    }
    
    func addItem(tableViewListItem:TableViewListItem) {
        self.tableViewListItems.append(tableViewListItem)
    }
    
    func buttonOneActionForItemText() {
        
    }
    
    func buttonTwoActionForItemText() {
        
    }
    
    func buttonThreeActionForItemText() {
        
    }
    
    // MARK: - ListItemsSectionHeaderViewDelegate
    
    func onHeaderTap(header: ListItemsSectionHeaderView) {
        delegate?.onHeaderTap(header, section: self)
    }
}

func ==(lhs: ListItemsViewSection, rhs: ListItemsViewSection) -> Bool {
    return lhs.section == rhs.section
}