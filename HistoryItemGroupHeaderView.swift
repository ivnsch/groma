//
//  HistoryItemGroupHeaderView.swift
//  shoppin
//
//  Created by ischuetz on 05/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

protocol HistoryItemGroupHeaderViewDelegate: class {
    func onHeaderTap(_ header: HistoryItemGroupHeaderView, sectionIndex: Int, sectionModel: SectionModel<HistoryItemGroup>)
    func onDeleteGroupTap(_ sectionModel: SectionModel<HistoryItemGroup>, header: HistoryItemGroupHeaderView)
}

class HistoryItemGroupHeaderView: UIView, CellUncovererDelegate {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var dateLabelVCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var deleteGroupButton: UIButton!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    fileprivate var cellUncoverer: CellUncoverer?
    
    var sectionIndex: Int?
    var sectionModel: SectionModel<HistoryItemGroup>?
    
    weak var delegate: HistoryItemGroupHeaderViewDelegate!
    
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
            if newValue.isEmpty {
                dateLabelVCenterConstraint.constant = 0
            } else {
                dateLabelVCenterConstraint.constant = -10
            }
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
                cellUncoverer?.setOpen(false, animated: true)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        cellUncoverer = CellUncoverer(parentView: self, button: contentView, leftLayoutConstraint: leftLayoutConstraint)
        cellUncoverer?.stashViewWidth = 76
        cellUncoverer?.allowOpen = true
        cellUncoverer?.delegate = self
        
        deleteGroupButton.addTarget(self, action: #selector(HistoryItemGroupHeaderView.onDeleteButtonTap(_:)), for: UIControlEvents.touchUpInside)
        
    }

    func onDeleteButtonTap(_ sender: UIButton) {
        if let sectionModel = sectionModel {
            delegate?.onDeleteGroupTap(sectionModel, header: self)
        } else {
            logger.e("No headerIndex or group")
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let sectionIndex = sectionIndex, let sectionModel = sectionModel {
            delegate?.onHeaderTap(self, sectionIndex: sectionIndex, sectionModel: sectionModel)
        } else {
            logger.e("No headerIndex or group")
        }
    }
    
    // MARK: - CellUncovererDelegate
    
    func onOpen(_ open: Bool) {
        self.open = open
    }
}
