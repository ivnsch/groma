//
//  AutosuggestionsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 31/05/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class AutosuggestionsTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var tableView: HandlingTableView!

    var suggestions: [String] = []
    var filteredSuggestions: [String] = [] {
        didSet {
            self.view.hidden = self.filteredSuggestions.isEmpty
            self.tableView.reloadData()
            self.tableView.sizeToFit()
        }
    }

    private var suggestionConfirmed: ((String) -> ())!
    
    var suggestionSelected: ((String) -> ())?
    var upAtTopPressed: (() -> ())?
    var exitPressed: (() -> ())?

    private var selectedRow: Int? // we have to hold this separately as tableView.selectedRow is incremented by the system between keyDown and keyUp and this leads to jump (+1), it's also not possible to selectSuggestion in keyUpHandler because this leads to issue when selection is at the bottom
    
    init?(suggestionConfirmed: (String) -> ()) {
        self.suggestionConfirmed = suggestionConfirmed
        super.init(nibName: "AutosuggestionsTableViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tableView.headerView = nil

        self.initKeyHandlers()
    }
    
    private func initKeyHandlers() {
        
        var selectedRowInKeyDown: Int?
        
        self.tableView.keyDownHandler = {[weak self] theEvent in
            let keyCode = Int(theEvent.keyCode)
            selectedRowInKeyDown = self!.tableView.selectedRow
            
            switch keyCode {
            case 36:
                fallthrough
            case 53:
                return false // don't play "invalid key" sound
            default: break
            }
            
            return true
        }
        
        self.tableView.keyUpHandler = {[weak self] theEvent in
            let keyCode = Int(theEvent.keyCode)
            
            switch keyCode {
            case 126 where self!.tableView.selectedRow == 0:
                self!.upAtTopPressed?()
                break
            case 126:
                self!.selectCurrentSuggestion()
            case 125:
                if selectedRowInKeyDown == self!.tableView.selectedRow { // cycle when press down at the bottom
                    self!.selectRow(0)
                    self!.tableView.scrollToBeginningOfDocument(self!)
                }
                self!.selectCurrentSuggestion()
                break
            case 36:
                self!.confirmCurrentSuggestion()
            case 53:
                self!.exitPressed?()
                
            default: break
                
            }
            
            return true
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        self.confirmCurrentSuggestion()
    }
    
    private var selectedSuggestion: String? {
        let row = self.tableView.selectedRow
        if row >= 0 {
            return self.filteredSuggestions[row]
        } else {
            return nil
        }
    }
    
    private func selectCurrentSuggestion() {
        if let selectedSuggestion = self.selectedSuggestion {
            self.suggestionSelected?(selectedSuggestion)
        }
    }
    
    private func confirmCurrentSuggestion() {
        if let selectedSuggestion = self.selectedSuggestion {
            self.suggestionConfirmed(selectedSuggestion)
        }
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return self.filteredSuggestions.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("cell", owner: self) as! NSTableCellView
        let option = self.filteredSuggestions[row]
        let a = cell.textField
        cell.textField?.stringValue = option
        return cell
    }

    func selectRow(index: Int) {
        self.tableView.selectRowIndexes(NSIndexSet(index: index), byExtendingSelection: false)
    }
    
    func goDown() {
        self.selectRow(0)
        self.tableView.window?.makeFirstResponder(self.tableView)
        self.tableView.scrollToBeginningOfDocument(self)
        self.selectCurrentSuggestion()
    }
}