//
//  HistoryItemGroupHeaderView.swift
//  shoppin
//
//  Created by ischuetz on 05/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol HistoryItemGroupHeaderViewDelegate {
    func onHeaderTap(header: HistoryItemGroupHeaderView, sectionIndex: Int, sectionModel: SectionModel<HistoryItemGroup>)
}

class HistoryItemGroupHeaderView: UIView {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
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

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let sectionIndex = sectionIndex, sectionModel = sectionModel {
            delegate?.onHeaderTap(self, sectionIndex: sectionIndex, sectionModel: sectionModel)
        } else {
            print("Error: HistoryItemGroupHeaderView.touchesEnded: no headerIndex or group")
        }
    }
}
