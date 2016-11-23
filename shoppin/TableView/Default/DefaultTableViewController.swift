//
//  DefaultTableViewController.swift
//  TrainerApp
//
//  Created by Ivan Schuetz on 11/12/14.
//  Copyright (c) 2014 eGym. All rights reserved.
//

import UIKit

class DefaultTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    fileprivate var tableView:UITableView!
    
    lazy var sectionDelegates:[TableViewSectionDelegate] = self.generateSecionDelegates()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.tableView = self.generateTableView()
        self.view.addSubview(self.tableView)
        
        let views = ["tableView": self.tableView]
        for view in views.values {
            view?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        for constraint in [
            "H:|[tableView]|",
            "V:|[tableView]|"
            ] {
                self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: constraint, options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        }
    }
    
    func generateSecionDelegates() -> [TableViewSectionDelegate] {
        fatalError("This method must be overridden")
    }
    
    fileprivate func generateTableView() -> UITableView {
        let tableView = UITableView(frame: CGRect.null, style: UITableViewStyle.grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        for (cellClass, cellIdentifier): (UITableViewCell.Type, String) in self.cellsToRegister() {
            tableView.register(cellClass, forCellReuseIdentifier:cellIdentifier)
        }
        
        return tableView
    }
    
    func cellsToRegister() -> [(cellClass:UITableViewCell.Type, cellIdentifier:String)] {
        fatalError("This method must be overridden")
    }
    
    func sectionDelegateForIndex(_ index:Int) -> TableViewSectionDelegate {
        return self.sectionDelegates[index]
    }
    
    func sectionDelegateForIndexPath(_ indexPath:IndexPath) -> TableViewSectionDelegate {
        return self.sectionDelegateForIndex((indexPath as NSIndexPath).section)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = self.sectionDelegateForIndexPath(indexPath).heightForRow((indexPath as NSIndexPath).row)
        return CGFloat(height)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let height = self.sectionDelegateForIndex(section).heightForHeader()
        return CGFloat(height)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let height = self.sectionDelegateForIndex(section).heightForFooter()
        return CGFloat(height)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.sectionDelegateForIndex(section).viewForHeader()
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return self.sectionDelegateForIndex(section).viewForFooter()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.sectionDelegateForIndexPath(indexPath).tableView(tableView, cellForRow:(indexPath as NSIndexPath).row)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sectionDelegateForIndex(section).numberOfRows()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionDelegates.count
    }

}
