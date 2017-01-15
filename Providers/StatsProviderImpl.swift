//
//  StatsProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs
import RealmSwift

public struct ProductAggregate {
    public let product: Product
    public let totalCount: Int
    public let totalPrice: Float
    public let percentage: Float
    
    public init(product: Product, totalCount: Int, totalPrice: Float, percentage: Float) {
        self.product = product
        self.totalCount = totalCount
        self.totalPrice = totalPrice
        self.percentage = percentage
    }
}

public final class GroupMonthYearAggregate: Equatable {
    public let group: AggregateGroup
    public let timePeriod: TimePeriod
    public let referenceDate: Date
    public let monthYearAggregates: [MonthYearAggregate]
    
    public init(group: AggregateGroup, timePeriod: TimePeriod, referenceDate: Date, monthYearAggregates: [MonthYearAggregate]) {
        self.group = group
        self.timePeriod = timePeriod
        self.referenceDate = referenceDate
        self.monthYearAggregates = monthYearAggregates
    }
    
    /**
    Dates covered by timePeriod. The content of monthYearAggregates is irrelevant here.
    */
    public lazy var allDates: [Date] = {
        // quantity can be negative, in which case we need quantity..0, or positive, in which case we need 0..quantity
        let dates: [Date] = stride(from: min(self.timePeriod.quantity + 1, 0), through: max(self.timePeriod.quantity, 0), by: 1).map {quantity in
            let offset = self.timePeriod.dateOffsetComponent(quantity)
            return Calendar.current.date(byAdding: offset, to: self.referenceDate, wrappingComponents: false)!
        }
        return dates.sorted{$0 < $1}
    }()
}

public func ==(lhs: GroupMonthYearAggregate, rhs: GroupMonthYearAggregate) -> Bool {
    return lhs.group == rhs.group && lhs.timePeriod == rhs.timePeriod && lhs.referenceDate == rhs.referenceDate && lhs.monthYearAggregates == rhs.monthYearAggregates
}

public struct MonthYearAggregate: Equatable {
    public let monthYear: MonthYear
    public let totalCount: Int
    public let totalPrice: Float
    
    public init(monthYear: MonthYear, totalCount: Int, totalPrice: Float) {
        self.monthYear = monthYear
        self.totalCount = totalCount
        self.totalPrice = totalPrice
    }
}
public func ==(lhs: MonthYearAggregate, rhs: MonthYearAggregate) -> Bool {
    return lhs.monthYear == rhs.monthYear && lhs.totalCount == rhs.totalCount && lhs.totalPrice == rhs.totalPrice
}

class StatsProviderImpl: StatsProvider {

    func aggregate(_ monthYear: MonthYear, groupBy: GroupByAttribute, inventory: DBInventory, _ handler: @escaping (ProviderResult<[ProductAggregate]>) -> ()) {
        RealmHistoryProvider().loadHistoryItems(monthYear, inventory: inventory) {historyItems in
            if let historyItems = historyItems {
                let productAggregates = self.toProductAggregates(historyItems)
                handler(ProviderResult(status: .success, sucessResult: productAggregates))
            } else {
                QL4("Couldn't load items")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func aggregate(_ timePeriod: TimePeriod, groupBy: GroupByAttribute, inventory: DBInventory, _ handler: @escaping (ProviderResult<[ProductAggregate]>) -> ()) {
        let dateComponents = timePeriod.dateOffsetComponent()
        
        if let startDate = (Calendar.current as NSCalendar).date(byAdding: dateComponents as DateComponents, to: Date(), options: .wrapComponents)?.toMillis() {
            
            RealmHistoryProvider().loadHistoryItems(startDate: startDate, inventory: inventory) {historyItems in
                if let historyItems = historyItems {
                    let productAggregates = self.toProductAggregates(historyItems)
                    handler(ProviderResult(status: .success, sucessResult: productAggregates))
                } else {
                    QL4("Couldn't load items")
                    handler(ProviderResult(status: .unknown))
                }
            }
            
        } else {
            print("Error: dateByAddingComponents in RealmStatsProvider, aggregate, returned nil. Can't calculate aggregate.")
            handler(ProviderResult(status: .dateCalculationError))
        }
    }
    
    func history(_ timePeriod: TimePeriod, group: AggregateGroup, inventory: DBInventory, _ handler: @escaping (ProviderResult<GroupMonthYearAggregate>) -> ()) {
        let dateComponents = timePeriod.dateOffsetComponent()
        
        let referenceDate = Date() // today
        if let startDate = (Calendar.current as NSCalendar).date(byAdding: dateComponents as DateComponents, to: referenceDate, options: [])?.toMillis() {
            
            RealmHistoryProvider().loadHistoryItems(startDate: startDate, inventory: inventory) {historyItems in
                
                if let historyItems = historyItems {

                    var dict: OrderedDictionary<MonthYear, (price: Float, quantity: Int)> = OrderedDictionary()
                    
                    let (_, referenceDateMonth, referenceDateYear) = referenceDate.dayMonthYear
                    if timePeriod.timeUnit != .month {
                        QL4("Error: not supported timeunit: \(timePeriod.timeUnit) - the calculations will be incorrect") // for now we only need months (TODO complete or remove the other enum values, maybe even remove the enum)
                    }
                    
                    // Prefill the dictionary with the month years in time period's range. We need all the months in the result independently if they have history items or not ("left join")
                    let monthYears = stride(from: min(timePeriod.quantity + 1, 0), through: max(timePeriod.quantity, 0), by: 1).map {quantity in
                        MonthYear(month: referenceDateMonth, year: referenceDateYear).offsetMonths(quantity)
                    }
                    let monthYearsWithoutNils = monthYears.flatMap{$0} // we are not expecting nils here but we avoid ! (except in outlets) as general rule. There's an error log in offestMonths.
                    for monthYear in monthYearsWithoutNils {
                        dict[monthYear] = nil
                    }
                    
                    for historyItem in historyItems {
                        
                        let components = Calendar.current.dateComponents([.month, .year], from: historyItem.addedDate.millisToEpochDate())
                        if let month = components.month, let year = components.year {
                            let key = MonthYear(month: month, year: year)
                            if let aggr = dict[key] {
                                dict[key] = (price: aggr.price + historyItem.totalPaidPrice, quantity: aggr.quantity + historyItem.quantity)
                            } else {
                                dict[key] = (price: historyItem.totalPaidPrice, quantity: historyItem.quantity)
                            }
                        } else {
                            QL4("No month/year in components")
                            handler(ProviderResult(status: .unknown))
                            break
                        }
                    }
                    
                    let monthYearAggregates: [MonthYearAggregate] = dict.mapOpt {key, value in
                        MonthYearAggregate(monthYear: key, totalCount: value?.quantity ?? 0, totalPrice: value?.price ?? 0)
                    }
                    
                    let groupMonthYearAggregate = GroupMonthYearAggregate(group: group, timePeriod: timePeriod, referenceDate: referenceDate, monthYearAggregates: monthYearAggregates)
                    
                    handler(ProviderResult(status: .success, sucessResult: groupMonthYearAggregate))
                    
                } else {
                    QL4("Couldn't load items")
                    handler(ProviderResult(status: .unknown))
                }
            }
            
        } else {
            print("Error: dateByAddingComponents in RealmStatsProvider, aggregate, returned nil. Can't calculate aggregate.")
            handler(ProviderResult(status: .dateCalculationError))
        }
    }
    
    fileprivate func toProductAggregates(_ historyItems: Results<HistoryItem>) -> [ProductAggregate] {
        
        // extract from history items total quantity and price for each product (a product can appear in multiple history items)
        var dict: OrderedDictionary<String, (product: Product, price: Float, quantity: Int)> = OrderedDictionary()
        var totalPrice: Float = 0
        for historyItem in historyItems {
            let product = historyItem.product.product // the product units are irrelevant for this - we just want to know how much we spended e.g. for "apples" - whether we bought sometimes in "boxes" or others in "kg" doesn't make a difference
            let itemTotalPaidPrice = historyItem.totalPaidPrice
            if let aggr = dict[product.uuid] {
                // we put the product in values which overwrites the product of the last entry for this uuid if existent, the product for one uuid is always the same so this doesn't matter.
                dict[product.uuid] = (product: product, price: aggr.price + itemTotalPaidPrice, quantity: aggr.quantity + historyItem.quantity)
            } else {
                dict[product.uuid] = (product: product, price: itemTotalPaidPrice, quantity: historyItem.quantity)
            }
            totalPrice += itemTotalPaidPrice
        }
        
        // construct the aggregates based on the dictionary
        let productAggregates: [ProductAggregate] = dict.map {key, value in
            
            let percentage: Float = {
                if totalPrice == 0 {
                    print("Warning: RealmStatsProvider.aggregate: totalPrice is 0")
                    return 0
                } else {
                    return value.price * 100 / totalPrice
                }
            }()
            
            return ProductAggregate(product: value.product, totalCount: value.quantity, totalPrice: value.price, percentage: percentage)
        }
        
        let sortedByPrice = productAggregates.sorted {
            $0.0.totalPrice > $0.1.totalPrice
        }
        
        return sortedByPrice
    }
    
    func hasDataForMonthYear(_ monthYear: MonthYear, inventory: DBInventory, handler: @escaping (ProviderResult<Bool>) -> Void) {
        Prov.historyProvider.historyItems(monthYear, inventory: inventory) {result in
            if let items = result.sucessResult {
                handler(ProviderResult(status: .success, sucessResult: items.isEmpty))
            } else {
                QL4("Didn't return result, monthYear: \(monthYear), inventory: \(inventory)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func clearMonthYearData(_ monthYear: MonthYear, inventory: DBInventory, remote: Bool, handler: @escaping (ProviderResult<Any>) -> Void) {
        Prov.historyProvider.removeHistoryItemsForMonthYear(monthYear, inventory: inventory, remote: remote, handler: handler)
    }
    
    func oldestDate(_ inventory: DBInventory, _ handler: @escaping (ProviderResult<Date>) -> Void) {
        Prov.historyProvider.oldestDate(inventory, handler: handler)
    }
    
}
