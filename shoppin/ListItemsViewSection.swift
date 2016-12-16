//
//  ProductsTableViewSection.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework
import Providers

enum ListItemsViewSectionStyle {
    case normal, gray
}

protocol ItemActionsDelegate: class {
    func startItemSwipe(_ tableViewListItem: TableViewListItem)
    func endItemSwipe(_ tableViewListItem: TableViewListItem)
    func undoSwipe(_ tableViewListItem: TableViewListItem)
    func onNoteTap(_ cell: ListItemCell, tableViewListItem: TableViewListItem)
    func onHeaderTap(_ header: ListItemsSectionHeaderView, section: ListItemsViewSection)
    func onMinusTap(_ tableViewListItem: TableViewListItem)
    func onPlusTap(_ tableViewListItem: TableViewListItem)
    func onPanQuantityUpdate(_ tableViewListItem: TableViewListItem, newQuantity: Int)
}

class ListItemsViewSection: NSObject, ListItemsSectionHeaderViewDelegate, ListItemCellDelegate {
    
    var tableViewListItems: [TableViewListItem]
    
    fileprivate let cellIdentifier = ItemsListTableViewConstants.listItemCellIdentifier
    
    var headerBGColor: UIColor = UIColor.black
    var headerFontColor: UIColor = UIColor.white
    var labelFontColor: UIColor = UIColor.black
    
    var section: Section // as var to mutate order in-place (ListItemsTableViewController)
    
    var expanded: Bool = true
    let status: ListItemStatus
    
    fileprivate let hasHeader: Bool
    
    var style: ListItemsTableViewControllerStyle = .normal

    weak var delegate: ItemActionsDelegate?
    
    fileprivate let headerFont = Fonts.regular

    var cellMode: ListItemCellMode = .note
    var cellSwipeDirection: SwipeableCellDirection = .right
    
    fileprivate let headerHeight = Float(DimensionsManager.listItemsHeaderHeight)
    fileprivate let cellHeight = DimensionsManager.defaultCellHeight
    
    /**
     Returns total price of shown items exluding those marked for undo
     */
    var totalPrice: Float {
        return tableViewListItems.reduce(Float(0)) {sum, item in
            return sum + (item.swiped ? 0 : item.listItem.totalPrice(status))
        }
    }

    /**
     Returns total quantity of shown items exluding those marked for undo
     */
    var totalQuantity: Int {
        return tableViewListItems.reduce(0) {sum, item in
            return sum + (item.swiped ? 0 : item.listItem.quantity(status))
        }
    }
    
    // this could be solved maybe with inheritance or sth like "style injection", for now this is ok
    fileprivate var finalLabelFontColor:UIColor {
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
        return self.hasHeader ? headerHeight : 0
    }
    
    func heightForFooter() -> Float {
        return 0
    }
    
    func cellReuseIdentifierForRow(_ row:Int) -> String {
        return cellIdentifier
    }
    
    func viewForHeader() -> UIView? {
        if self.hasHeader {
            let view = Bundle.loadView("ListItemsSectionHeaderView", owner: self) as! ListItemsSectionHeaderView
            view.section = section
            view.backgroundColor = headerBGColor
            view.nameLabel.textColor = UIColor(contrastingBlackOrWhiteColorOn: headerBGColor, isFlat: true)
//            view.nameLabel.textColor = headerFontColor
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
    
    func heightForRow(_ row: Int) -> CGFloat {
        return cellHeight
    }
    
    //    func cellsToRegister() -> NSSet {
    //        return NSSet()
    //    }
    
    
    
    func tableView(_ tableView: UITableView, row: NSInteger) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ListItemCell
        cell.showsReorderControl = true
        cell.direction = cellSwipeDirection
        
        let tableViewListItem = tableViewListItems[row]
        
        cell.setup(status, mode: cellMode, labelColor: finalLabelFontColor, tableViewListItem: tableViewListItem, delegate: self)
        
        return cell
    }
    
    func numberOfRows() -> Int {
        return expanded ? tableViewListItems.count : 0
    }
    
    func addItem(_ tableViewListItem:TableViewListItem) {
        self.tableViewListItems.append(tableViewListItem)
    }
    
    func buttonOneActionForItemText() {
        
    }
    
    func buttonTwoActionForItemText() {
        
    }
    
    func buttonThreeActionForItemText() {
        
    }
    
    // MARK: - ListItemsSectionHeaderViewDelegate
    
    func onHeaderTap(_ header: ListItemsSectionHeaderView) {
        delegate?.onHeaderTap(header, section: self)
    }
    
    // MARK: - 
    
    func onItemSwiped(_ listItem: TableViewListItem) {
        delegate?.endItemSwipe(listItem)
    }
    
    func onStartItemSwipe(_ listItem: TableViewListItem) {
        delegate?.startItemSwipe(listItem)
    }
    
    func onButtonTwoTap(_ listItem: TableViewListItem) {
        _ = tableViewListItems.update(listItem.copy(swiped: false))
        delegate?.undoSwipe(listItem)
    }
    
    func onNoteTap(_ cell: ListItemCell, listItem: TableViewListItem) {
        delegate?.onNoteTap(cell, tableViewListItem: listItem)
    }
    
    func onMinusTap(_ listItem: TableViewListItem) {
        delegate?.onMinusTap(listItem)
    }
    
    func onPlusTap(_ listItem: TableViewListItem) {
        delegate?.onPlusTap(listItem)
    }
    
    func onPanQuantityUpdate(_ tableViewListItem: TableViewListItem, newQuantity: Int) {
        delegate?.onPanQuantityUpdate(tableViewListItem, newQuantity: newQuantity)
    }
}

func ==(lhs: ListItemsViewSection, rhs: ListItemsViewSection) -> Bool {
    return lhs.section == rhs.section
}
