//
//  UITableViewController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 03/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

extension UITableViewController {
    
    // MARK: - Table view row manipulation
    
    func addRow(indexPath: IndexPath, isNewSection: Bool) {
        tableView.addRow(indexPath: indexPath, isNewSection: isNewSection)
    }
    
    func updateRow(indexPath: IndexPath) {
        tableView.updateRow(indexPath: indexPath)
    }
    
    func deleteSection(index: Int) {
        tableView.deleteSection(index: index)
    }
    
    func reload() {
        tableView.reloadData()
    }
}
