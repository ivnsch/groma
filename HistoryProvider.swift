//
//  HistoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol HistoryProvider {
    
    func historyItems(range: NSRange, _ handler: ProviderResult<[HistoryItem]> -> ())

    func syncHistoryItems(handler: (ProviderResult<[Any]> -> ()))
    
    func removeHistoryItem(historyItem: HistoryItem, _ handler: ProviderResult<Any> -> ())
}