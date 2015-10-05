//
//  HistoryItemGroupHeaderView.swift
//  shoppin
//
//  Created by ischuetz on 05/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class HistoryItemGroupHeaderView: UIView {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
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
}
