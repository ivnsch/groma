//
//  QuickAddGroupViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class QuickAddGroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var groupNameInput: UITextField!
    @IBOutlet weak var itemsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
