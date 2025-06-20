//
//  HistoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public protocol HistoryProvider {
    
    func historyItems(_ range: NSRange, inventory: DBInventory, _ handler: @escaping (ProviderResult<Results<HistoryItem>>) -> Void)

    /**
    * Get all history items with a date greater or equal than startDate, until today
     // TODO - not used - remove?
    */
//    func historyItems(_ startDate: Int64, inventory: DBInventory, _ handler: @escaping (ProviderResult<Results<HistoryItem>>) -> Void)

    func historyItems(_ monthYear: MonthYear, inventory: DBInventory, _ handler: @escaping (ProviderResult<Results<HistoryItem>>) -> Void)
    
    func historyItemsGroups(_ range: NSRange, inventory: DBInventory, _ handler: @escaping (ProviderResult<[HistoryItemGroup]>) -> ())
    
    func historyItem(_ uuid: String, handler: @escaping (ProviderResult<HistoryItem?>) -> Void)
    
    func removeHistoryItem(_ historyItem: HistoryItem, _ handler: @escaping (ProviderResult<Any>) -> ())

    func removeHistoryItem(_ uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func removeHistoryItemGroupForHistoryItemLocal(_ uuid: String, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func removeHistoryItemsGroup(_ historyItemGroup: HistoryItemGroup, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func removeHistoryItemsForMonthYear(_ monthYear: MonthYear, inventory: DBInventory, remote: Bool, handler: @escaping (ProviderResult<Any>) -> Void)

    func removeAllHistoryItems(_ handler: @escaping (ProviderResult<Any>) -> Void)

    func oldestDate(_ inventory: DBInventory, handler: @escaping (ProviderResult<Date>) -> Void)
    
    // NOTE: only for debug purpose! Normally history items can be added only via inventory
    func addHistoryItems(_ historyItems: [HistoryItem], _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func removeHistoryItemsOlderThan(_ date: Date, handler: @escaping (ProviderResult<Bool>) -> Void)
}
