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
    
    init(options:[String], onSelectOption:@escaping (Int, String) -> ()) {
        super.init(style: UITableViewStyle.plain)

        self.options = options
        self.onSelectOption = onSelectOption
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) 

        cell.textLabel?.text = self.options[(indexPath as NSIndexPath).row]

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = (indexPath as NSIndexPath).row
        self.onSelectOption(row, self.options[row])
    }
}
