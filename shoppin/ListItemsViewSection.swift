//
//  ProductsTableViewSection.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class ListItemsViewSection: NSObject {
    
    var listItems:[ListItem]
    
    private let cellIdentifier = ItemsListTableViewConstants.listItemCellIdentifier
    
    var headerBGColor:UIColor = UIColor(red: 0.7, green: 0.7, blue: 1, alpha: 1)
    
    var headerFontColor:UIColor = UIColor.blackColor()
    var labelColor:UIColor = UIColor.blackColor()
    
    let section:Section
    
    private let hasHeader:Bool
    
    
    init(section:Section, listItems:[ListItem], hasHeader:Bool = true) {
        self.section = section
        self.listItems = listItems
        self.hasHeader = hasHeader
    }
    
    func heightForHeader() -> Float {
        return self.hasHeader ? 30 : 0
    }
    
    func heightForFooter() -> Float {
        return 0
    }
    
    func cellReuseIdentifierForRow(row:Int) -> String {
        return ItemsListTableViewConstants.listItemCellIdentifier
    }
    
    func viewForHeader() -> UIView? {
        var v:UIView?
        
        if self.hasHeader {
            let label = UILabel()
            label.text = "  " + self.section.name //FIXME - container doesn't work properly!
            label.backgroundColor = self.headerBGColor
            label.textColor = self.headerFontColor
            label.font = UIFont(name: "Trebuchet MS", size: 15)
            v = label
        } else {
            v = nil
        }
        
        
//        let container = UIView()
//        container.addSubview(v)
//        
//        let views:Dictionary = ["label": v]
//        for view in views.values {
//            view.setTranslatesAutoresizingMaskIntoConstraints(false)
//        }
//
//        let metrics:Dictionary = ["padding": 5]
//        
//        for constraint in [
//            "H:|-(padding)-[label]",
//            "V:|-(padding)-[label]-(padding)-|"
//            ] {
//                container.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(constraint, options: NSLayoutFormatOptions.allZeros, metrics: metrics, views: views))
//        }
        
        return v
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

        let cell:ListItemCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as ListItemCell

        let listItem = listItems[row]
        
        cell.listItem = listItem
        cell.labelColor = self.labelColor
        
        return cell
    }
    
    func numberOfRows() -> Int {
        return listItems.count
    }
    
    func addItem(listItem:ListItem) {
        self.listItems.append(listItem)
    }
    
}
