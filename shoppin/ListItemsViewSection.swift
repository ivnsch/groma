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

class ListItemsViewSection: NSObject, ListItemsSectionHeaderViewDelegate, ListItemCellDelegate {
    
    var tableViewListItems: [TableViewListItem]
    
    private let cellIdentifier = ItemsListTableViewConstants.listItemCellIdentifier
    
    var headerBGColor: UIColor = UIColor.blackColor()
    var headerFontColor: UIColor = UIColor.whiteColor()
    var labelFontColor: UIColor = UIColor.blackColor()
    
    var section: Section // as var to mutate order in-place (ListItemsTableViewController)
    
    var expanded: Bool = true
    let status: ListItemStatus
    
    private let hasHeader: Bool
    
    var style: ListItemsTableViewControllerStyle = .Normal

    var delegate: ItemActionsDelegate!
    
    private let headerFont = Fonts.regular

    var cellMode: ListItemCellMode = .Note
    
    /**
     Returns total price of shown items exluding those marked for undo
     */
    var totalPrice: Float {
        return tableViewListItems.reduce(Float(0)) {sum, item in
            
            print("item: \(item.listItem.product.name), price: \(item.listItem.product.price), swiped: \(item.swiped)")
            
            return sum + (item.swiped ? 0 : item.listItem.totalPrice(status))
        }
    }
    
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
    
    init(section: Section, tableViewListItems:[TableViewListItem], hasHeader: Bool = true, status: ListItemStatus) {
        self.section = section
        self.tableViewListItems = tableViewListItems
        self.hasHeader = hasHeader
        self.status = status
    }
    
    func heightForHeader() -> Float {
        return self.hasHeader ? Float(Constants.listItemsTableViewHeaderHeight) : 0
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
            view.backgroundColor = headerBGColor
            view.nameLabel.textColor = headerFontColor
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
        return Constants.cellDefaultHeight
    }
    
    //    func cellsToRegister() -> NSSet {
    //        return NSSet()
    //    }
    
    
    
    func tableView(tableView: UITableView, row: NSInteger) -> UITableViewCell {

        let cell:ListItemCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ListItemCell
        cell.showsReorderControl = true
        
        let tableViewListItem = tableViewListItems[row]
        
        cell.setup(status, mode: cellMode, labelColor: finalLabelFontColor, tableViewListItem: tableViewListItem, delegate: self)
        
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
    
    // MARK: - 
    
    func onItemSwiped(listItem: TableViewListItem) {
        delegate?.endItemSwipe(listItem)
    }
    
    func onStartItemSwipe(listItem: TableViewListItem) {
        delegate?.startItemSwipe(listItem)
    }
    
    func onButtonTwoTap(listItem: TableViewListItem) {
        tableViewListItems.update(listItem.copy(swiped: false))
        delegate?.undoSwipe(listItem)
    }
    
    func onNoteTap(listItem: TableViewListItem) {
        delegate?.onNoteTap(listItem)
    }
    
    func onMinusTap(listItem: TableViewListItem) {
        delegate?.onMinusTap(listItem)
    }
    
    func onPlusTap(listItem: TableViewListItem) {
        delegate?.onPlusTap(listItem)
    }
}

func ==(lhs: ListItemsViewSection, rhs: ListItemsViewSection) -> Bool {
    return lhs.section == rhs.section
}