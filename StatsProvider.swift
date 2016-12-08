//
//  StatsProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

enum TimeUnit {
    case month, year
}

struct TimePeriod: Equatable {
    let quantity: Int
    let timeUnit: TimeUnit
    
    init(quantity: Int, timeUnit: TimeUnit) {
        self.quantity = quantity
        self.timeUnit = timeUnit
    }
    
    func dateOffsetComponent() -> DateComponents {
        return dateOffsetComponent(quantity)
    }
    
    func dateOffsetComponent(_ quantity: Int) -> DateComponents {
        
        var dateComponents = DateComponents()
        
        switch timeUnit {
        case .month: dateComponents.month = quantity
        case .year: dateComponents.year = quantity
        }
        
        return dateComponents
    }
}

func ==(lhs: TimePeriod, rhs: TimePeriod) -> Bool {
    return lhs.quantity == rhs.quantity && lhs.timeUnit == rhs.timeUnit
}

enum GroupByAttribute {
    case name/*, Category*/ //TODO categories
}

enum AggregateGroup: Equatable {
    case all
//    case CategoryItem(Category) // TODO sth like this
    case productItem(Product)
}
func ==(lhs: AggregateGroup, rhs: AggregateGroup) -> Bool {
    switch (lhs, rhs) {
    case (.productItem(_), .productItem(_)): return true
    case (.all, .all): return true
    default: return false
    }
}

protocol StatsProvider {
    
    func aggregate(_ monthYear: MonthYear, groupBy: GroupByAttribute, inventory: DBInventory, _ handler: @escaping (ProviderResult<[ProductAggregate]>) -> ())

    func aggregate(_ timePeriod: TimePeriod, groupBy: GroupByAttribute, inventory: DBInventory, _ handler: @escaping (ProviderResult<[ProductAggregate]>) -> ())
    
    func history(_ timePeriod: TimePeriod, group: AggregateGroup, inventory: DBInventory, _ handler: @escaping (ProviderResult<GroupMonthYearAggregate>) -> ())
    
    func hasDataForMonthYear(_ monthYear: MonthYear, inventory: DBInventory, handler: @escaping (ProviderResult<Bool>) -> Void)
    
    func clearMonthYearData(_ monthYear: MonthYear, inventory: DBInventory, remote: Bool, handler: @escaping (ProviderResult<Any>) -> Void)
    
    func oldestDate(_ inventory: DBInventory, _ handler: @escaping (ProviderResult<Date>) -> Void)
}
