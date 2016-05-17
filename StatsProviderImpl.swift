//
//  StatsProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct ProductAggregate {
    let product: Product
    let totalCount: Int
    let totalPrice: Float
    let percentage: Float
    
    init(product: Product, totalCount: Int, totalPrice: Float, percentage: Float) {
        self.product = product
        self.totalCount = totalCount
        self.totalPrice = totalPrice
        self.percentage = percentage
    }
}

final class GroupMonthYearAggregate: Equatable {
    let group: AggregateGroup
    let timePeriod: TimePeriod
    let referenceDate: NSDate
    let monthYearAggregates: [MonthYearAggregate]
    
    init(group: AggregateGroup, timePeriod: TimePeriod, referenceDate: NSDate, monthYearAggregates: [MonthYearAggregate]) {
        self.group = group
        self.timePeriod = timePeriod
        self.referenceDate = referenceDate
        self.monthYearAggregates = monthYearAggregates
    }
    
    /**
    Dates covered by timePeriod. The content of monthYearAggregates is irrelevant here.
    */
    lazy var allDates: [NSDate] = {
        // quantity can be negative, in which case we need quantity..0, or positive, in which case we need 0..quantity
        let dates: [NSDate] = min(self.timePeriod.quantity + 1, 0).stride(through: max(self.timePeriod.quantity, 0), by: 1).map {quantity in
            let offset = self.timePeriod.dateOffsetComponent(quantity)
            return NSCalendar.currentCalendar().dateByAddingComponents(offset, toDate: self.referenceDate, options: .MatchStrictly)!
        }
        
        return dates.sort{$0 < $1}
    }()
}

func ==(lhs: GroupMonthYearAggregate, rhs: GroupMonthYearAggregate) -> Bool {
    return lhs.group == rhs.group && lhs.timePeriod == rhs.timePeriod && lhs.referenceDate == rhs.referenceDate && lhs.monthYearAggregates == rhs.monthYearAggregates
}

struct MonthYearAggregate: Equatable {
    let monthYear: MonthYear
    let totalCount: Int
    let totalPrice: Float
    
    init(monthYear: MonthYear, totalCount: Int, totalPrice: Float) {
        self.monthYear = monthYear
        self.totalCount = totalCount
        self.totalPrice = totalPrice
    }
}
func ==(lhs: MonthYearAggregate, rhs: MonthYearAggregate) -> Bool {
    return lhs.monthYear == rhs.monthYear && lhs.totalCount == rhs.totalCount && lhs.totalPrice == rhs.totalPrice
}

class StatsProviderImpl: StatsProvider {

    func aggregate(monthYear: MonthYear, groupBy: GroupByAttribute, inventory: Inventory, _ handler: ProviderResult<[ProductAggregate]> -> ()) {
        RealmHistoryProvider().loadHistoryItems(monthYear, inventory: inventory) {historyItems in
            let productAggregates = self.toProductAggregates(historyItems)
            handler(ProviderResult(status: .Success, sucessResult: productAggregates))
        }
    }
    
    func aggregate(timePeriod: TimePeriod, groupBy: GroupByAttribute, inventory: Inventory, _ handler: ProviderResult<[ProductAggregate]> -> ()) {
        let dateComponents = timePeriod.dateOffsetComponent()
        
        if let startDate = NSCalendar.currentCalendar().dateByAddingComponents(dateComponents, toDate: NSDate(), options: .WrapComponents)?.toMillis() {
            
            RealmHistoryProvider().loadHistoryItems(startDate: startDate, inventory: inventory) {historyItems in
                let productAggregates = self.toProductAggregates(historyItems)
                handler(ProviderResult(status: .Success, sucessResult: productAggregates))
            }
            
        } else {
            print("Error: dateByAddingComponents in RealmStatsProvider, aggregate, returned nil. Can't calculate aggregate.")
            handler(ProviderResult(status: .DateCalculationError))
        }
    }
    
    func history(timePeriod: TimePeriod, group: AggregateGroup, inventory: Inventory, _ handler: ProviderResult<GroupMonthYearAggregate> -> ()) {
        let dateComponents = timePeriod.dateOffsetComponent()
        
        let referenceDate = NSDate() // today
        if let startDate = NSCalendar.currentCalendar().dateByAddingComponents(dateComponents, toDate: referenceDate, options: [])?.toMillis() {
            
            RealmHistoryProvider().loadHistoryItems(startDate: startDate, inventory: inventory) {historyItems in
                
                var dict: OrderedDictionary<MonthYear, (price: Float, quantity: Int)> = OrderedDictionary()
                
                let (_, referenceDateMonth, referenceDateYear) = referenceDate.dayMonthYear
                if timePeriod.timeUnit != .Month {
                    QL4("Error: not supported timeunit: \(timePeriod.timeUnit) - the calculations will be incorrect") // for now we only need months (TODO complete or remove the other enum values, maybe even remove the enum)
                }
                
                // Prefill the dictionary with the month years in time period's range. We need all the months in the result independently if they have history items or not ("left join")
                let monthYears = min(timePeriod.quantity + 1, 0).stride(through: max(timePeriod.quantity, 0), by: 1).map {quantity in
                    MonthYear(month: referenceDateMonth, year: referenceDateYear).offsetMonths(quantity)
                }
                let monthYearsWithoutNils = monthYears.flatMap{$0} // we are not expecting nils here but we avoid ! (except in outlets) as general rule. There's an error log in offestMonths.
                for monthYear in monthYearsWithoutNils {
                    dict[monthYear] = nil
                }
                
                for historyItem in historyItems {
                    
                    let components = NSCalendar.currentCalendar().components([.Month, .Year], fromDate: historyItem.addedDate.millisToEpochDate())
                    let key = MonthYear(month: components.month, year: components.year)
                    if let aggr = dict[key] {
                        dict[key] = (price: aggr.price + historyItem.totalPaidPrice, quantity: aggr.quantity + historyItem.quantity)
                    } else {
                        dict[key] = (price: historyItem.totalPaidPrice, quantity: historyItem.quantity)
                    }
                }
                
                let monthYearAggregates: [MonthYearAggregate] = dict.mapOpt {key, value in
                    MonthYearAggregate(monthYear: key, totalCount: value?.quantity ?? 0, totalPrice: value?.price ?? 0)
                }
                
                let groupMonthYearAggregate = GroupMonthYearAggregate(group: group, timePeriod: timePeriod, referenceDate: referenceDate, monthYearAggregates: monthYearAggregates)
                
                handler(ProviderResult(status: .Success, sucessResult: groupMonthYearAggregate))
            }
            
        } else {
            print("Error: dateByAddingComponents in RealmStatsProvider, aggregate, returned nil. Can't calculate aggregate.")
            handler(ProviderResult(status: .DateCalculationError))
        }
    }
    
    private func toProductAggregates(historyItems: [HistoryItem]) -> [ProductAggregate] {
        
        // extract from history items total quantity and price for each product (a product can appear in multiple history items)
        var dict: OrderedDictionary<String, (product: Product, price: Float, quantity: Int)> = OrderedDictionary()
        var totalPrice: Float = 0
        for historyItem in historyItems {
            let product = historyItem.product
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
        
        let sortedByPrice = productAggregates.sort {
            $0.0.totalPrice > $0.1.totalPrice
        }
        
        return sortedByPrice
    }
    
    func hasDataForMonthYear(monthYear: MonthYear, inventory: Inventory, handler: ProviderResult<Bool> -> Void) {
        Providers.historyProvider.historyItems(monthYear, inventory: inventory) {result in
            if let items = result.sucessResult {
                handler(ProviderResult(status: .Success, sucessResult: items.isEmpty))
            } else {
                QL4("Didn't return result, monthYear: \(monthYear), inventory: \(inventory)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func clearMonthYearData(monthYear: MonthYear, inventory: Inventory, remote: Bool, handler: ProviderResult<Any> -> Void) {
        Providers.historyProvider.removeHistoryItemsForMonthYear(monthYear, inventory: inventory, remote: remote, handler: handler)
    }
    
    func oldestDate(inventory: Inventory, _ handler: ProviderResult<NSDate> -> Void) {
        Providers.historyProvider.oldestDate(inventory, handler: handler)
    }
    
}