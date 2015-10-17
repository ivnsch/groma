//
//  ListItemGroupItemsViewController.swift
//  shoppin
//
//  Created by ischuetz on 14/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ListItemGroupItemsViewController: UIViewController, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    @IBAction func onAddToGroupTap(sender: UIButton) {
    }
}
