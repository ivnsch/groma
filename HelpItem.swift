//
//  HelpItem.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

enum HelpItemType {
    case Normal, Troubleshooting
}

// Help screen content items
class HelpItem {
    
    let title: String
    let text: String
    let type: HelpItemType
    
    init(title: String, text: String, type: HelpItemType = .Normal) {
        self.title = title
        self.text = text
        self.type = type
    }
}
