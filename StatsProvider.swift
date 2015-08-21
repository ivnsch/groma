//
//  StatsProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

enum TimeUnit {
    case Month, Year
}

struct TimePeriod {
    let quantity: Int
    let timeUnit: TimeUnit
    
    init(quantity: Int, timeUnit: TimeUnit) {
        self.quantity = quantity
        self.timeUnit = timeUnit
    }
    
    func dateOffsetComponent() -> NSDateComponents {
        
        let dateComponents = NSDateComponents()
        
        let quantity = self.quantity
        
        switch timeUnit {
        case .Month: dateComponents.month = quantity
        case .Year: dateComponents.year = quantity
        }
        
        return dateComponents
    }
}

enum GroupByAttribute {
    case Name/*, Category*/ //TODO categories
}

enum AggregateGroup {
    case All
//    case CategoryItem(Category) // TODO sth like this
    case ProductItem(Product)
}

protocol StatsProvider {

    func aggregate(timePeriod: TimePeriod, groupBy: GroupByAttribute, handler: ProviderResult<[ProductAggregate]> -> ())
    
    func history(timePeriod: TimePeriod, group: AggregateGroup, handler: ProviderResult<GroupMonthYearAggregate> -> ())
    
}
