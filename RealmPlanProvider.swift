//
//  RealmPlanProvider.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmPlanProvider: RealmProvider {

    let dbHistoryProvider = RealmHistoryProvider()

    // TODO optimize - fetch first plan items, is it possible (and better) to fetch only history items for the fetched plan items?
    func planItems(startDate: NSDate, handler: [PlanItem] -> ()) {
        dbHistoryProvider.loadHistoryItems(startDate: NSDate().startOfMonth) {[weak self] historyItems in
            if let weakSelf = self {
                let productQuantities = weakSelf.productsTotalQuantities(historyItems)
                // Use history to calculate how much has been already consumed of each product in current time period
                let mapper: DBPlanItem -> PlanItem = {dbPlanItem in
                    let usedQuantity = productQuantities[dbPlanItem.product.uuid] ?? 0
                    return PlanItemMapper.planItemWith(dbPlanItem, usedQuantity: usedQuantity)
                }
                weakSelf.load(mapper, handler: handler)
                
            } else {
                print("Error: RealmPlanProvider.planItems, self is nil")
            }
        }
    }

    // TODO optimize - fetch first plan item, if there's no plan item, there's no need to fetch the history
    func planItem(productName: String, startDate: NSDate, handler: PlanItem? -> ()) {
        dbHistoryProvider.loadHistoryItems(productName, startDate: NSDate().startOfMonth) {[weak self] historyItems in
            if let weakSelf = self {
                // Use history to calculate how much has been already consumed product in current time period
                let mapper: DBPlanItem -> PlanItem = {dbPlanItem in
                    let usedQuantity = historyItems.totalQuantity
                    return PlanItemMapper.planItemWith(dbPlanItem, usedQuantity: usedQuantity)
                }
                weakSelf.loadFirst(mapper, filter: "product.name = '\(productName)'", handler: handler)
                
            } else {
                print("Error: RealmPlanProvider.planItems, self is nil")
            }
        }
    }
    
    /**
    * Calculates total amount of product in history items
    * Returns dictionary product uuid -> total amount
    */
    private func productsTotalQuantities(historyItems: [HistoryItem]) -> [String: Int] {
        var dict: [String: Int] = [:]
        for historyItem in historyItems {
            if dict[historyItem.product.uuid] == nil {
                dict[historyItem.product.uuid] = historyItem.quantity
            } else {
                dict[historyItem.product.uuid]! += historyItem.quantity
            }
        }
        return dict
    }
    
    func add(item: PlanItem, handler: Bool -> ()) {
        update(item, handler: handler)
    }

    func update(item: PlanItem, handler: Bool -> ()) {
        let dbObj = PlanItemMapper.dbWith(item)
        self.saveObj(dbObj, update: true, handler: handler)
    }
    
    func remove(item: PlanItem, handler: Bool -> ()) {
        self.remove("product.name = '\(item.product.name)'", handler: handler, objType: DBPlanItem.self)
    }
    
    func increment(item: PlanItem, delta: Int, onlyDelta: Bool = false, handler: Bool -> ()) {
        
        // load
        let realm = try! Realm()
        var results = realm.objects(DBPlanItem)
        results = results.filter(NSPredicate(format: "product.name = '\(item.product.name)'", argumentArray: []))
        let objs: [DBPlanItem] = results.toArray(nil)
        let dbPlanItems = objs.map{PlanItemMapper.planItemWith($0, usedQuantity: -1)} // usedQuantity is ignored here (we only convert to DB object and it doesn't use this), FIXME it's not good to have not used fields like this
        let planItemMaybe = dbPlanItems.first
        
        if let planItem = planItemMaybe {
        // increment
        let incrementedPlanItem: PlanItem =  {
            if onlyDelta {
                return planItem.copy(quantityDelta: planItem.quantityDelta + delta)
            } else {
                return planItem.incrementQuantityCopy(delta)
            }
        }()
        
        // convert to db object
        let dbIncrementedPlanItem = PlanItemMapper.dbWith(incrementedPlanItem)
        
        
        // save
        realm.write {
            for obj in objs {
                obj.lastUpdate = NSDate()
                realm.add(dbIncrementedPlanItem, update: true)
            }
        }
        
        handler(true)
        
        
        } else {
            print("Plan item not found: \(item)")
            handler(false)
        }
    }
    
}