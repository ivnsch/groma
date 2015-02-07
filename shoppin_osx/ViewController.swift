//
//  ViewController.swift
//  shoppin_osx
//
//  Created by ischuetz on 07.02.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var tableView: NSTableView!

    private var products:[Product]?
    
    private let listItemsProvider = ProviderFactory().listItemProvider

    override func viewDidLoad() {
        super.viewDidLoad()

        self.products = self.listItemsProvider.products()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func numberOfRowsInTableView(aTableView: NSTableView!) -> Int {
        return self.products?.count ?? 0
    }
    
//    func tableView(tableView: NSTableView!, objectValueForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject! {
//        
//        println("column: \(tableColumn)")
//        return "foo"
//    }
    
    
    func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject! {
        
        let identifier = tableColumn.identifier
        let cellView = tableView.makeViewWithIdentifier(identifier, owner:self) as NSTableCellView

        let product = self.products![row]
        
        
        cellView.textField?.stringValue = product.name

        return cellView
    }
    
    
    
//    
//    // This method is optional if you use bindings to provide the data
//    - (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    // Group our "model" object, which is a dictionary
//    NSDictionary *dictionary = [_tableContents objectAtIndex:row];
//    
//    // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary
//    NSString *identifier = [tableColumn identifier];
//    
//    if ([identifier isEqualToString:@"MainCell"]) {
//    // We pass us as the owner so we can setup target/actions into this main controller object
//    NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
//    // Then setup properties on the cellView based on the column
//    cellView.textField.stringValue = [dictionary objectForKey:@"Name"];
//    cellView.imageView.objectValue = [dictionary objectForKey:@"Image"];
//    return cellView;
//    } else if ([identifier isEqualToString:@"SizeCell"]) {
//    NSTextField *textField = [tableView makeViewWithIdentifier:identifier owner:self];
//    NSImage *image = [dictionary objectForKey:@"Image"];
//    NSSize size = image ? [image size] : NSZeroSize;
//    NSString *sizeString = [NSString stringWithFormat:@"%.0fx%.0f", size.width, size.height];
//    textField.objectValue = sizeString;
//    return textField;
//    } else {
//    NSAssert1(NO, @"Unhandled table column identifier %@", identifier);
//    }
//    return nil;
//    }

}

