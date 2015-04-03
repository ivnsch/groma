//
//  ViewController.swift
//  shoppin_osx
//
//  Created by ischuetz on 07.02.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa


class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, ListItemCellManagerDelegate {
   
    private var currentList:List?
    
    @IBOutlet weak var tableView: NSTableView!

    private var cellManagers:[CellManager] = []
    
    private let listItemsProvider = ProviderFactory().listItemProvider

    private var listItemRows:[ListItemCellManager] {
        return self.cellManagers.filter {$0 as? ListItemCellManager != nil} as! [ListItemCellManager]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let currentList = self.listItemsProvider.firstList
        self.currentList = currentList
        self.initList(currentList)
    }

    private func initList(list:List) {
        let listItems = self.listItemsProvider.listItems(list)
        
        self.cellManagers = self.createCellManagers(listItems)
    }
    
    private func createCellManagers(listItems: [ListItem]) -> [CellManager] {
        var cellManagers:[CellManager] = []
        var foundSections = Set<String>() // quick lookup
        
        for listItem in listItems {
            if !foundSections.contains(listItem.section.name) {
                foundSections.insert(listItem.section.name)
                cellManagers.append(HeaderCellManager(section: listItem.section))
            }
            
            cellManagers.append(ListItemCellManager(listItem: listItem, delegate: self))
        }
        return cellManagers
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return self.cellManagers.count

    }
    
//    func tableView(tableView: NSTableView!, objectValueForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject! {
//        println("column: \(tableColumn)")
//        return "foo"
//    }
    

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return self.cellManagers[row].makeCell(tableView, tableColumn: tableColumn, row: row)
    }
    

    @IBAction func menuAddTapped(sender: NSButton) {
        let rowIndex = self.cellManagers.count
        self.addListItem(rowIndex)
    }


    private func toListItemInput(listItem: ListItem) -> ListItemInput {
        return ListItemInput(
            name: listItem.product.name,
            quantity: listItem.quantity,
            price: listItem.product.price,
            section: listItem.section.name)
    }
    
    private func toUpdatedListItem(listItem:ListItem, listItemInput: ListItemInput) -> ListItem {
        
        let section = Section(name: listItemInput.section)
        
        // for now we overwrite existing product on update (provider just sets the fields on existing product)
        // later we may want to think about this, depending how we use products
        // for example if we used products e.g. to make statistics about bought products, and a user changes "strawberries" name into "fish", we will make them incorrect
        // or if for some reason we have different list items pointing to same product, we will change product name for all of them - also incorrect
        // this behaviour may be desired though to correct spelling errors
        // so yes we have to think about it
        let product = Product(id: "dummy", name: listItemInput.name, price: listItemInput.price)
        
        return ListItem(
            id: listItem.id,
            done: listItem.done,
            quantity: listItemInput.quantity,
            product: product,
            section: section,
            list: listItem.list,
            order: listItem.order
        )
    }
    
    private func addListItem(rowIndex: Int) {
        if let list = self.currentList {
            let editListItemController = EditListItemController()
            editListItemController.addTappedFunc = {listItemInput in
                
                let listItemMaybe = self.listItemsProvider.add(listItemInput, list: list, order: rowIndex)
                
                if let currentList = self.currentList, listItem = listItemMaybe {
                    
                    let cellManager = ListItemCellManager(listItem: listItem, delegate: self)
                    self.cellManagers.insert(cellManager, atIndex: rowIndex)
                    self.tableView.wrapUpdates {
                        self.tableView.insertRowsAtIndexes(NSIndexSet(index: rowIndex), withAnimation: NSTableViewAnimationOptions.SlideDown)
                    }()
                    
                } else {
                    println("Warning: trying to add item without current list")
                }
                
                editListItemController.close()
            }
            
            editListItemController.windowDidLoadFunc = {
                editListItemController.modus = .Add
            }
            
            editListItemController.show(list)
        }
    }
    
    private func addListItemInRow(rowIndex: Int) {
        self.addListItem(rowIndex)
        self.updateListItemsModelsOrder()
    }
    
    private func updateListItem(rowIndex: Int, listItemRow: ListItemRow) {
        if let list = self.currentList {
            let editListItemController = EditListItemController()
            editListItemController.addTappedFunc = {listItemInput in
              
                let updatedListItem = self.toUpdatedListItem(listItemRow.listItem, listItemInput: listItemInput)
                if (!self.listItemsProvider.update(updatedListItem)) {
                    println("Error: couldn't update item")
                }
                
                self.cellManagers[rowIndex] = ListItemCellManager(listItem: updatedListItem, delegate: self)
                
                let editableColumnIndices: NSIndexSet =  NSIndexSet(indexesInRange: NSMakeRange(0, 1))
                self.tableView.wrapUpdates {
                    self.tableView.reloadDataForRowIndexes(NSIndexSet(index: rowIndex), columnIndexes: editableColumnIndices)
                    
                }()
 
                editListItemController.close()
            }

            editListItemController.windowDidLoadFunc = {
                editListItemController.modus = .Edit
                editListItemController.prefill(self.toListItemInput(listItemRow.listItem))
            }
            
            editListItemController.show(list)
        }
    }
    
    // updates list item models with current ordering in table view
    private func updateListItemsModelsOrder() {
        var sectionRows = 0
        
        for (listItemIndex, listItemRow) in enumerate(listItemRows) {
            listItemRow.listItemRow.listItem.order = listItemIndex
        }
        
        self.updateAllListItemsInProvider()
    }
    
    func removeRow(row:Int, listItemRow: ListItemRow) {
        self.cellManagers.removeAtIndex(row)
        
        self.tableView.wrapUpdates {
            self.tableView.removeRowsAtIndexes(NSIndexSet(index: row), withAnimation: NSTableViewAnimationOptions.EffectFade | NSTableViewAnimationOptions.SlideLeft)
        }()
        
        self.listItemsProvider.remove(listItemRow.listItem)
        
        updateListItemsModelsOrder()
    }

    private func moveRowWithLimitsCheck(rowIndex: Int, targetIndex: Int, anim: NSTableViewAnimationOptions) {
        if targetIndex >= 0 && targetIndex < self.cellManagers.count {
            self.moveRow(rowIndex, targetIndex: targetIndex, anim: anim)
        }
    }
    
    private func moveRow(rowIndex: Int, targetIndex: Int, anim: NSTableViewAnimationOptions) {
        let listItemRow = self.cellManagers[rowIndex]
        
        self.cellManagers.removeAtIndex(rowIndex)
        self.cellManagers.insert(listItemRow, atIndex: targetIndex)
        
        self.tableView.wrapUpdates {
            self.tableView.removeRowsAtIndexes(NSIndexSet(index: rowIndex), withAnimation: NSTableViewAnimationOptions.EffectFade | anim)
            self.tableView.insertRowsAtIndexes(NSIndexSet(index: targetIndex), withAnimation: NSTableViewAnimationOptions.EffectFade | anim)
        }()
        
        updateListItemsModelsOrder() // this can be optimised in changing only order of items at rowIndex and targetIndex
        
        self.assignListItemsToSections()
    }
    
    func assignListItemsToSections() {
        
        var currentSection:Section?
 
        for cellManager in self.cellManagers {
            
            if let headerCellManager = cellManager as? HeaderCellManager {
                currentSection = headerCellManager.section
            
            } else if let listItemCellManager = cellManager as? ListItemCellManager {
                let listItem = listItemCellManager.listItemRow.listItem
                
                if let cs = currentSection {
                    listItem.section = cs
                    
                } else {
                    println("Warning: Invalid state - list item before any section")
                }
            }
        }
        
        self.updateAllListItemsInProvider()
    }
    
    private func updateAllListItemsInProvider() {
        self.listItemsProvider.update(self.listItemRows.map{$0.listItemRow.listItem})
    }
    
    func rowAddTapped(cell: NSTableCellView, listItemRow: ListItemRow) {
        let index = self.tableView.rowForView(cell)
        self.addListItemInRow(index + 1)
    }
    
    func rowDeleteTapped(cell: NSTableCellView, listItemRow: ListItemRow) {
        let index = self.tableView.rowForView(cell)
        self.removeRow(index, listItemRow: listItemRow)
    }
    
    func rowUpTapped(cell: NSTableCellView, listItemRow: ListItemRow) {
        let index = self.tableView.rowForView(cell)
        self.moveRowWithLimitsCheck(index, targetIndex: index - 1, anim: NSTableViewAnimationOptions.SlideUp)
    }
    
    func rowDownTapped(cell: NSTableCellView, listItemRow: ListItemRow) {
        let index = self.tableView.rowForView(cell)
        self.moveRowWithLimitsCheck(index, targetIndex: index + 1, anim: NSTableViewAnimationOptions.SlideDown)
    }
    
    func rowEditTapped(cell: NSTableCellView, listItemRow: ListItemRow) {
        let index = self.tableView.rowForView(cell)
        self.updateListItem(index, listItemRow: listItemRow)
    }
}

