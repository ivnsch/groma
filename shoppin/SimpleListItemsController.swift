//
//  SimpleListItemsController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 02/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import RealmSwift
import QorumLogs

class SimpleListItemsController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
//    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!
    
    
    var listItems: RealmSwift.List<ListItem>?
    
    var status: ListItemStatus = .done
    
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
    
    
    @IBOutlet weak var topBar: ListTopBarView!
    fileprivate var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    fileprivate var topEditSectionControllerManager: ExpandableTopViewController<EditSectionViewController>?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "SimpleListItemCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
}

extension SimpleListItemsController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ListItemCellNew
        
        if let listItem = listItems?[indexPath.row] {
            cell.setup(status, mode: cellMode, tableViewListItem: listItem, delegate: self)
            
        } else {
            QL4("Invalid state: no listitem for: \(indexPath)")
        }
        
        return cell
    }
    
}

extension SimpleListItemsController: ListItemCellDelegateNew {
    
    func onItemSwiped(_ listItem: ListItem) {
        
    }
    
    func onStartItemSwipe(_ listItem: ListItem) {
        
    }
    
    func onButtonTwoTap(_ listItem: ListItem) {
        
    }
    
    func onNoteTap(_ cell: ListItemCellNew, listItem: ListItem) {
        
    }
    
    func onMinusTap(_ listItem: ListItem) {
        
    }
    
    func onPlusTap(_ listItem: ListItem) {
        
    }
    
    func onPanQuantityUpdate(_ tableViewListItem: ListItem, newQuantity: Int) {
        
    }
    
    
}
