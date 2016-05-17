//
//  HistoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol HistoryProvider {
    
    func historyItems(range: NSRange, inventory: Inventory, _ handler: ProviderResult<[HistoryItem]> -> ())

    /**
    * Get all history items with a date greater or equal than startDate, until today
    */
    func historyItems(startDate: Int64, inventory: Inventory, _ handler: ProviderResult<[HistoryItem]> -> ())

    func historyItems(monthYear: MonthYear, inventory: Inventory, _ handler: ProviderResult<[HistoryItem]> -> Void)
    
    func historyItemsGroups(range: NSRange, inventory: Inventory, _ handler: ProviderResult<[HistoryItemGroup]> -> ())
    
    func historyItem(uuid: String, handler: ProviderResult<HistoryItem?> -> Void)
    
    func removeHistoryItem(historyItem: HistoryItem, _ handler: ProviderResult<Any> -> ())

    func removeHistoryItem(uuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func removeHistoryItemGroupForHistoryItemLocal(uuid: String, _ handler: ProviderResult<Any> -> Void)
    
    func removeHistoryItemsGroup(historyItemGroup: HistoryItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void)

    func removeHistoryItemsForMonthYear(monthYear: MonthYear, inventory: Inventory, remote: Bool, handler: ProviderResult<Any> -> Void)

    func removeAllHistoryItems(handler: ProviderResult<Any> -> Void)

    func oldestDate(inventory: Inventory, handler: ProviderResult<NSDate> -> Void)
    
    // NOTE: only for debug purpose! Normally history items can be added only via inventory
    func addHistoryItems(historyItems: [HistoryItem], _ handler: ProviderResult<Any> -> Void)
}