//
//  StatsProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

enum TimeUnit {
    case Day, Week, Month, Year
}

struct TimePeriod {
    let quantity: Int
    let timeUnit: TimeUnit
    
    init(quantity: Int, timeUnit: TimeUnit) {
        self.quantity = quantity
        self.timeUnit = timeUnit
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
