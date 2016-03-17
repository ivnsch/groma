//
//  RealmSectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class RealmSectionProvider: RealmProvider {
    
    func loadSectionWithUuid(uuid: String, handler: Section? -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        self.loadFirst(mapper, filter: DBSection.createFilter(uuid), handler: handler)
    }
    
    func loadSection(name: String, list: List, handler: Section? -> ()) {
        loadSections([name], list: list) {sections in
            handler(sections.first)
        }
    }
    
    func loadSections(names: [String], list: List, handler: [Section] -> ()) {
        let mapper = {SectionMapper.sectionWithDB($0)}
        self.load(mapper, filter: DBSection.createFilterWithNames(names, listUuid: list.uuid), handler: handler)
    }
    
    func saveSection(section: Section, handler: Bool -> ()) {
        let dbSection = DBSection()
        dbSection.uuid = section.uuid
        dbSection.name = section.name
        
        self.saveObj(dbSection, handler: handler)
    }
    
    func saveSections(sections: [Section], handler: Bool -> ()) {
        let dbSections = sections.map{SectionMapper.dbWithSection($0)}
        self.saveObjs(dbSections, update: true, handler: handler)
    }
    
    func remove(section: Section, markForSync: Bool, handler: Bool -> ()) {
        remove(section.uuid, markForSync: markForSync, handler: handler)
    }
    
    func remove(sectionUuid: String, markForSync: Bool, handler: Bool -> ()) {
        
        let additionalActions: (Realm -> Void)? = markForSync ? {realm in
            let toRemove = DBSectionToRemove(uuid: sectionUuid, lastServerUpdate: NSDate()) // TODO!!!! review lastServerUpdate - what to set here?
            realm.add(toRemove, update: true)
        } : nil
        
        self.remove(DBSection.createFilter(sectionUuid), handler: handler, objType: DBSection.self, additionalActions: additionalActions)
    }
    
    func update(sections: [Section], handler: Bool -> ()) {
        let dbSections = sections.map{SectionMapper.dbWithSection($0)}
        self.saveObjs(dbSections, update: true, handler: handler)
    }
    
    // Gets suggestions both from section and category names
    func sectionSuggestionsContainingText(text: String, handler: [String] -> Void) {
        withRealm({ realm in
            let sectionNames: [String] = realm.objects(DBSection).filter(DBSection.createFilterNameContains(text)).map{$0.name}
            let categoryNames: [String] = realm.objects(DBProductCategory).filter(DBProductCategory.createFilterNameContains(text)).map{$0.name}
            let allNames: [String] = (sectionNames + categoryNames).distinct()
            return allNames
            
            }) { (allNamesMaybe: [String]?) -> Void in
                if let allNames = allNamesMaybe {
                    handler(allNames)
                } else {
                    print("Error: RealmListItemProvider.loadSectionSuggestions: Couldn't load section suggestions")
                    handler([])
                }
        }
    }
}
