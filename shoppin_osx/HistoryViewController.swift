//
//  HistoryViewController.swift
//  shoppin
//
//  Created by ischuetz on 24/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class HistoryViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, HistoryItemCellDelegate {
    
    @IBOutlet weak var tableView: NSTableView!
    
    private var historyItems: [HistoryItem] = []
    
    private let historyProvider = ProviderFactory().historyProvider
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.historyProvider.historyItems(successHandler{[weak self] historyItems in
            self?.historyItems = historyItems
            self?.tableView.reloadData()
        })
        
        self.tableView.reloadData()
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return self.historyItems.count
        
    }

    // MARK: - NSTableViewDelegate
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cell = tableView.makeViewWithIdentifier("historyItem", owner: self) as! HistoryItemCellOSX
        
        cell.delegate = self
        cell.historyItem = self.historyItems[row]
        
        return cell
    }
}