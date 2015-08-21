//
//  RealmStatsProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

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

struct GroupMonthYearAggregate {
    let group: AggregateGroup
    let monthYearAggregates: [MonthYearAggregate]
    
    init(group: AggregateGroup, monthYearAggregates: [MonthYearAggregate]) {
        self.group = group
        self.monthYearAggregates = monthYearAggregates
    }
}

struct MonthYearAggregate {
    let monthYear: MonthYear
    let totalCount: Int
    let totalPrice: Float
    
    init(monthYear: MonthYear, totalCount: Int, totalPrice: Float) {
        self.monthYear = monthYear
        self.totalCount = totalCount
        self.totalPrice = totalPrice
    }
}


class RealmStatsProvider: RealmProvider {
    
    // TODO move non db logic to provider impl

    func aggregate(timePeriod: TimePeriod, groupBy: GroupByAttribute, handler: ProviderResult<[ProductAggregate]> -> ()) {
        
        let dateComponents = timePeriod.dateOffsetComponent()
        
        if let startDate = NSCalendar.currentCalendar().dateByAddingComponents(dateComponents, toDate: NSDate(), options: .WrapComponents) {
            
            RealmHistoryProvider().loadHistoryItems(startDate) {historyItems in
                
                var dict: OrderedDictionary<Product, (price: Float, quantity: Int)> = OrderedDictionary()
                var totalPrice: Float = 0
                for historyItem in historyItems {
                    let product = historyItem.product
                    let quantityPrice = Float(historyItem.quantity) * product.price
                    if let aggr = dict[product] {
                        dict[product] = (price: aggr.price + quantityPrice, quantity: aggr.quantity + historyItem.quantity)
                    } else {
                        dict[product] = (price: quantityPrice, quantity: historyItem.quantity)
                    }
                    totalPrice += quantityPrice
                }

                let productAggregates: [ProductAggregate] = dict.map {key, value in
                    
                    let percentage: Float = {
                        if totalPrice == 0 {
                            print("Warning: RealmStatsProvider.aggregate: totalPrice is 0")
                            return 0
                        } else {
                            return value.price * 100 / totalPrice
                        }
                        
                    }()
                    
                    return ProductAggregate(product: key, totalCount: value.quantity, totalPrice: value.price, percentage: percentage)
                }
                
                let sortedByPrice = productAggregates.sort {
                    $0.0.totalPrice > $0.1.totalPrice
                }
                
                handler(ProviderResult(status: .Success, sucessResult: sortedByPrice))
            }
            
            
        } else {
            print("Error: dateByAddingComponents in RealmStatsProvider, aggregate, returned nil. Can't calculate aggregate.")
            handler(ProviderResult(status: .DateCalculationError))
        }
    }
    
    
    func history(timePeriod: TimePeriod, group: AggregateGroup, handler: ProviderResult<GroupMonthYearAggregate> -> ()) {
    
        let dateComponents = timePeriod.dateOffsetComponent()
        
        if let startDate = NSCalendar.currentCalendar().dateByAddingComponents(dateComponents, toDate: NSDate(), options: .WrapComponents) {
            
            RealmHistoryProvider().loadHistoryItems(startDate) {historyItems in
                
                var dict: OrderedDictionary<MonthYear, (price: Float, quantity: Int)> = OrderedDictionary()

                for historyItem in historyItems {
                    
                    let components = NSCalendar.currentCalendar().components([.Month, .Year], fromDate: historyItem.addedDate)
                    let key = MonthYear(month: components.month, year: components.year)
                    let product = historyItem.product
                    if let aggr = dict[key] {
                        dict[key] = (price: aggr.price + (Float(historyItem.quantity) * product.price), quantity: aggr.quantity + historyItem.quantity)
                    } else {
                        dict[key] = (price: Float(historyItem.quantity) * product.price, quantity: historyItem.quantity)
                    }
                }
                
                let monthYearAggregates: [MonthYearAggregate] = dict.map {key, value in
                    MonthYearAggregate(monthYear: key, totalCount: value.quantity, totalPrice: value.price)
                }
                
                let groupMonthYearAggregate = GroupMonthYearAggregate(group: group, monthYearAggregates: monthYearAggregates)
                
                handler(ProviderResult(status: .Success, sucessResult: groupMonthYearAggregate))
            }
            
            
        } else {
            print("Error: dateByAddingComponents in RealmStatsProvider, aggregate, returned nil. Can't calculate aggregate.")
            handler(ProviderResult(status: .DateCalculationError))
        }
    }
    

    

}