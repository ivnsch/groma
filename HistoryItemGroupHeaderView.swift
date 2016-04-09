//
//  HistoryItemGroupHeaderView.swift
//  shoppin
//
//  Created by ischuetz on 05/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol HistoryItemGroupHeaderViewDelegate {
    func onHeaderTap(header: HistoryItemGroupHeaderView, sectionIndex: Int, sectionModel: SectionModel<HistoryItemGroup>)
    func onDeleteGroupTap(sectionModel: SectionModel<HistoryItemGroup>, header: HistoryItemGroupHeaderView)
}

class HistoryItemGroupHeaderView: UIView, CellUncovererDelegate {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var deleteGroupButton: UIButton!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    private var cellUncoverer: CellUncoverer?
    
    var sectionIndex: Int?
    var sectionModel: SectionModel<HistoryItemGroup>?
    
    var delegate: HistoryItemGroupHeaderViewDelegate!
    
    var date: String {
        set {
            dateLabel.text = newValue
        }
        get {
            return dateLabel.text ?? ""
        }
    }

    var userName: String {
        set {
            userNameLabel.text = newValue
        }
        get {
            return userNameLabel.text ?? ""
        }
    }
    
    var price: String {
        set {
            priceLabel.text = newValue
        }
        get {
            return priceLabel.text ?? ""
        }
    }
    
    var open: Bool = false {
        didSet {
            if !open {
                cellUncoverer?.close()
            } else {
                QL3("Opening of cell not supported yet")
            }
            
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        cellUncoverer = CellUncoverer(parentView: self, button: contentView, leftLayoutConstraint: leftLayoutConstraint)
        cellUncoverer?.stashViewWidth = 76
        cellUncoverer?.allowOpen = true
        cellUncoverer?.delegate = self
        
        deleteGroupButton.addTarget(self, action: "onDeleteButtonTap:", forControlEvents: UIControlEvents.TouchUpInside)
        
    }

    func onDeleteButtonTap(sender: UIButton) {
        if let sectionModel = sectionModel {
            delegate?.onDeleteGroupTap(sectionModel, header: self)
        } else {
            QL4("No headerIndex or group")
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let sectionIndex = sectionIndex, sectionModel = sectionModel {
            delegate?.onHeaderTap(self, sectionIndex: sectionIndex, sectionModel: sectionModel)
        } else {
            QL4("No headerIndex or group")
        }
    }
    
    // MARK: - CellUncovererDelegate
    
    func onOpen(open: Bool) {
        self.open = open
    }
}