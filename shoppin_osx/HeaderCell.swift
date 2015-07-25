//
//  HeaderCell.swift
//  shoppin
//
//  Created by ischuetz on 03/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol HeaderCellDelegate: class {
    func headerDeleteTapped(cell: HeaderCell)
}

class HeaderCell: NSTableCellView {
    
    @IBOutlet weak var view: NSView!
    
    @IBOutlet weak var titleField: NSTextField!
   
    var title: String? {
        didSet {
            if let title = self.title {
                self.titleField.stringValue = title
            }
        }
    }
   
    weak var delegate: HeaderCellDelegate?
    
    init() {
        super.init(frame: CGRectZero)

        if NSBundle.mainBundle().loadNibNamed("Header", owner: self, topLevelObjects: nil) {
            self.view.frame = self.bounds
            self.addSubview(self.view)
        }
    }
   
    override func viewDidMoveToSuperview() {
        self.view.translatesAutoresizingMaskIntoConstraints = false
        for c in [
            "H:|[v]|",
            "V:|[v]|"
            ] {
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(c, options: NSLayoutFormatOptions(), metrics: nil, views: ["v": self.view]))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(dirtyRect: NSRect) {
        
        // Drawing code here.
        NSColor.greenColor().setFill()
        NSRectFill(dirtyRect)
        
        super.drawRect(dirtyRect)
    }
    
    @IBAction func headerDeleteTapped(sender: NSButton) {
        delegate?.headerDeleteTapped(self)
    }
}
