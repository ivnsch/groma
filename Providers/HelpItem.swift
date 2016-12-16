//
//  HelpItem.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public enum HelpItemType {
    case normal, troubleshooting
}

// Help screen content items
public class HelpItem {
    
    public let title: String
    public let text: String
    public let type: HelpItemType
    
    public init(title: String, text: String, type: HelpItemType = .normal) {
        self.title = title
        self.text = text
        self.type = type
    }
}
