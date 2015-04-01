//
//  ViewController.swift
//  shoppin_osx
//
//  Created by ischuetz on 07.02.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
   
    // wrapper to retrieve data for tableview
    private struct ListItemRow {
        let listItem:ListItem
        
        init(_ listItem:ListItem) {
            self.listItem = listItem
        }
        
        func getColumnString(columnIdentifier: ListItemColumnIdentifier) -> String? {
            switch columnIdentifier {
                case .ProductName:
                    return listItem.product.name
                case .Quantity:
                    return String(listItem.quantity)
                case .Price:
                    return listItem.product.price.toString(2)!
                default:
                    return nil
            }
        }
    }
    
    private enum ListItemColumnIdentifier:String {
        case ProductName = "name"
        case Quantity = "quantity"
        case Price = "price"
        case Edit = "edit"
    }
    

    private var currentList:List?
    
    @IBOutlet weak var tableView: NSTableView!

    private var listItemRows:[ListItemRow] = []
    
    private let listItemsProvider = ProviderFactory().listItemProvider

    override func viewDidLoad() {
        super.viewDidLoad()

        let currentList = self.listItemsProvider.firstList
        self.currentList = currentList
        self.initList(currentList)
    }

    private func initList(list:List) {
        let listItems = self.listItemsProvider.listItems(list)
        self.listItemRows = listItems.map{ListItemRow($0)}
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return self.listItemRows.count

    }
    
//    func tableView(tableView: NSTableView!, objectValueForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject! {
//        println("column: \(tableColumn)")
//        return "foo"
//    }
    
    
    private func makeButtonsCell(columnIdentifier: ListItemColumnIdentifier, tableView: NSTableView, row:Int) -> EditListItemButtonsCell {
      
        var cell = tableView.makeViewWithIdentifier(columnIdentifier.rawValue, owner:self) as! EditListItemButtonsCell
        
        
        return cell
    }
    
    private func makeDefaultCell(columnIdentifier: ListItemColumnIdentifier, tableView: NSTableView, row:Int) -> NSTableCellView {
        
        var cell = tableView.makeViewWithIdentifier(columnIdentifier.rawValue, owner:self) as! NSTableCellView

        let listItemRow = self.listItemRows[row]

        if let columnString = listItemRow.getColumnString(columnIdentifier) {
            cell.textField?.stringValue = columnString
        }
        
        return cell
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let columnIdentifier = ListItemColumnIdentifier(rawValue: tableColumn!.identifier)!

        switch columnIdentifier {
            case .Edit:
                return self.makeButtonsCell(columnIdentifier, tableView: tableView, row: row)
            default:
                return self.makeDefaultCell(columnIdentifier, tableView: tableView, row: row)
        }
    }
    
    @IBAction func onRowDeleteTap(sender: NSButton) {
        let row = self.tableView.rowForView(sender)

        let listItem = self.listItemRows[row].listItem
        self.listItemsProvider.remove(listItem)

        self.removeRow(row)
    }
    
    @IBAction func menuAddTapped(sender: NSButton) {
        let rowIndex = self.listItemRows.count
        self.addListItem(rowIndex)
    }
    
    @IBAction func rowAddTapped(sender: NSButton) {
        let rowIndex = self.tableView.rowForView(sender) + 1
        self.addListItem(rowIndex)
        
        self.updateListItemsModelsOrder()
        self.listItemsProvider.update(self.listItemRows.map{$0.listItem})
    }
    
    private func addListItem(rowIndex: Int) {
        if let list = self.currentList {
            let editListItemController = EditListItemController()
            editListItemController.addTappedFunc = {listItemInput in
                
                let listItemMaybe = self.listItemsProvider.add(listItemInput, list: list, order: rowIndex)
                
                if let currentList = self.currentList, listItem = listItemMaybe {
                    self.listItemRows.insert(ListItemRow(listItem), atIndex: rowIndex)
                    self.tableView.wrapUpdates {
                        self.tableView.insertRowsAtIndexes(NSIndexSet(index: rowIndex), withAnimation: NSTableViewAnimationOptions.SlideDown)
                        }()
                    
                } else {
                    println("Warning: trying to add item without current list")
                }

                editListItemController.close()
            }
            editListItemController.show(list)
        }
    }
    
    // updates list item models with current ordering in table view
    private func updateListItemsModelsOrder() {
        var sectionRows = 0
        for (listItemIndex, listItemRow) in enumerate(self.listItemRows) {
            listItemRow.listItem.order = listItemIndex
        }
    }
    
    func removeRow(row:Int) {
        let listItemRow = self.listItemRows[row]
        self.listItemRows.removeAtIndex(row)
        
        self.tableView.wrapUpdates {
            self.tableView.removeRowsAtIndexes(NSIndexSet(index: row), withAnimation: NSTableViewAnimationOptions.EffectFade | NSTableViewAnimationOptions.SlideLeft)
        }()
    }
}

