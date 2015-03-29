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

    private var listItemRows:[ListItemRow]?
    
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
        return self.listItemRows?.count ?? 0

    }
    
//    func tableView(tableView: NSTableView!, objectValueForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject! {
//        println("column: \(tableColumn)")
//        return "foo"
//    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let identifier = tableColumn!.identifier
        let cellView = tableView.makeViewWithIdentifier(identifier, owner:self) as! NSTableCellView

        let listItemRow = self.listItemRows![row]
        
        let columnIdentifier = ListItemColumnIdentifier(rawValue: identifier)
        
        if let columnString = listItemRow.getColumnString(columnIdentifier!) {
            cellView.textField?.stringValue = columnString
            
            
        } else {
//            switch columnIdentifier {
//                case .Edit:
//                default:
//                    break;
//            }
        }
        
        return cellView
    }
    
    @IBAction func onRowDeleteTap(sender: NSButton) {
        let row = self.tableView.rowForView(sender)
        self.removeRow(row)
    }
    
    @IBAction func rowAddTapped(sender: NSButton) {
        if let list = self.currentList {
            let editListItemController = EditListItemController()
            editListItemController.addTappedFunc = {listItemInput in
                
                let listItem = self.listItemsProvider.add(listItemInput, list: list)
              
                if let currentList = self.currentList {
                    self.initList(currentList)
                    self.tableView.reloadData()
                    
                } else {
                    println("Warning: trying to add item without current list")
                }

                editListItemController.close()
            }
            editListItemController.show(list)
        }
    }
    
    func removeRow(row:Int) {
        let listItemRow = self.listItemRows![row]
        self.listItemRows?.removeAtIndex(row)
        
        self.tableView.wrapUpdates {
            self.tableView.removeRowsAtIndexes(NSIndexSet(index: row), withAnimation: NSTableViewAnimationOptions.EffectFade | NSTableViewAnimationOptions.SlideLeft)
        }()
    }
}

