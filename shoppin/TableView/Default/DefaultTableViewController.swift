//
//  DefaultTableViewController.swift
//  TrainerApp
//
//  Created by Ivan Schuetz on 11/12/14.
//  Copyright (c) 2014 eGym. All rights reserved.
//

import UIKit

class DefaultTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var tableView:UITableView!
    
    lazy var sectionDelegates:[TableViewSectionDelegate] = self.generateSecionDelegates()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.tableView = self.generateTableView()
        self.view.addSubview(self.tableView)
        
        let views = ["tableView": self.tableView]
        for view in views.values {
            view.setTranslatesAutoresizingMaskIntoConstraints(false)
        }
        
        for constraint in [
            "H:|[tableView]|",
            "V:|[tableView]|"
            ] {
                self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(constraint, options: NSLayoutFormatOptions(0), metrics: nil, views: views))
        }
    }
    
    func generateSecionDelegates() -> [TableViewSectionDelegate] {
        fatalError("This method must be overridden")
    }
    
    private func generateTableView() -> UITableView {
        let tableView = UITableView(frame: CGRectNull, style: UITableViewStyle.Grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        for (cellClass:UITableViewCell.Type, cellIdentifier) in self.cellsToRegister() {
            tableView.registerClass(cellClass, forCellReuseIdentifier:cellIdentifier)
        }
        
        return tableView
    }
    
    func cellsToRegister() -> [(cellClass:UITableViewCell.Type, cellIdentifier:String)] {
        fatalError("This method must be overridden")
    }
    
    func sectionDelegateForIndex(index:Int) -> TableViewSectionDelegate {
        return self.sectionDelegates[index]
    }
    
    func sectionDelegateForIndexPath(indexPath:NSIndexPath) -> TableViewSectionDelegate {
        return self.sectionDelegateForIndex(indexPath.section)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let height = self.sectionDelegateForIndexPath(indexPath).heightForRow(indexPath.row)
        return CGFloat(height)
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let height = self.sectionDelegateForIndex(section).heightForHeader()
        return CGFloat(height)
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let height = self.sectionDelegateForIndex(section).heightForFooter()
        return CGFloat(height)
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.sectionDelegateForIndex(section).viewForHeader()
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return self.sectionDelegateForIndex(section).viewForFooter()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return self.sectionDelegateForIndexPath(indexPath).tableView(tableView, cellForRow:indexPath.row)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sectionDelegateForIndex(section).numberOfRows()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.sectionDelegates.count
    }

}
