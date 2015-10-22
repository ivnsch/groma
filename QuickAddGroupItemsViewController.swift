//
//  QuickAddGroupItemsViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class QuickAddGroupItemsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var itemsLabel: UILabel!
    @IBOutlet weak var itemsTableView: UITableView!
    
    @IBAction func onOkTap(sender: UIButton) {
    }
    
    @IBAction func onCancelTap(sender: UIButton) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
