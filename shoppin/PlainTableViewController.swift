//
//  PlainTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 03.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class PlainTableViewController: UITableViewController {

    var options:[String]!

    var onSelectOption:((Int, String) -> ())!
    
    let reuseIdentifier = "reuseIdentifier"
    
    init(options:[String], onSelectOption:(Int, String) -> ()) {
        self.options = options
        self.onSelectOption = onSelectOption
        
        super.init(style: UITableViewStyle.Plain)

        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.options.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UITableViewCell

        cell.textLabel?.text = self.options[indexPath.row]

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        self.onSelectOption(row, self.options[row])
    }
}