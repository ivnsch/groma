//
//  StatsProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class StatsProviderImpl: StatsProvider {
    
    private let dbStatsProvider = RealmStatsProvider()
    
    func aggregate(timePeriod: TimePeriod, groupBy: GroupByAttribute, handler: ProviderResult<[ProductAggregate]> -> ()) {
        self.dbStatsProvider.aggregate(timePeriod, groupBy: groupBy, handler: handler)
    }
    
    func history(timePeriod: TimePeriod, group: AggregateGroup, handler: ProviderResult<GroupMonthYearAggregate> -> ()) {
        self.dbStatsProvider.history(timePeriod, group: group, handler: handler)
    }
}