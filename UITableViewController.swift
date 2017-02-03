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
        
        tableView.beginUpdates()
        if isNewSection {
            tableView.insertSections([indexPath.section], with: .top)
        }
        tableView.insertRows(at: [IndexPath(row: indexPath.row, section: indexPath.section)], with: .top)
        tableView.endUpdates()
    }
    
    func updateRow(indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func deleteSection(index: Int) {
        tableView.deleteSections(IndexSet([index]), with: .top)
    }
    
    func reload() {
        tableView.reloadData()
    }
}
