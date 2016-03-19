//
//  SectionProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class SectionProviderImpl: SectionProvider {
    
    let dbProvider = RealmListItemProvider()
    
    func loadSection(name: String, list: List, handler: ProviderResult<Section?> -> ()) {
        DBProviders.sectionProvider.loadSection(name, list: list) {dbSectionMaybe in
            handler(ProviderResult(status: .Success, sucessResult: dbSectionMaybe))
            
            //            // TODO is this necessary here?
            //            self.remoteProvider.section(name, list: list) {remoteResult in
            //
            //                if let remoteSection = remoteResult.successResult {
            //                    let section = SectionMapper.SectionWithRemote(remoteSection)
            //                    handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: section))
            //                } else {
            //                    print("Error getting remote product, status: \(remoteResult.status)")
            //                    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
            //                    handler(ProviderResult(status: providerStatus))
            //                }
            //            }
        }
    }

    func add(section: Section, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        Providers.listItemsProvider.invalidateMemCache()
        DBProviders.sectionProvider.saveSection(section) {saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            if saved && remote {
                // TODO!! server
            }
        }
    }
    
    func remove(sectionUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        Providers.listItemsProvider.invalidateMemCache()
        DBProviders.sectionProvider.remove(sectionUuid, markForSync: true) {removed in
            handler(ProviderResult(status: removed ? .Success : .DatabaseUnknown))
            if removed && remote {
                // TODO!! server
            }
        }
    }
    
    func remove(section: Section, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        remove(section.uuid, remote: remote, handler)
    }
    
    func update(sections: [Section], remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        Providers.listItemsProvider.invalidateMemCache()
        DBProviders.sectionProvider.update(sections) {updated in
            handler(ProviderResult(status: updated ? .Success : .DatabaseUnknown))
            if updated && remote {
                // TODO!! server
            }
        }
    }
    
    func update(section: Section, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        update([section], remote: remote, handler)
    }
    
    func sectionSuggestionsContainingText(text: String, _ handler: ProviderResult<[String]> -> ()) {
        DBProviders.sectionProvider.sectionSuggestionsContainingText(text) {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSuggestions))
        }
    }

    func sections(names: [String], list: List, handler: ProviderResult<[Section]> -> ()) {
        DBProviders.sectionProvider.loadSections(names, list: list) {dbSections in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSections))
        }
    }
    
    func mergeOrCreateSection(sectionName: String, sectionColor: UIColor, status: ListItemStatus, possibleNewOrder: ListItemStatusOrder?, list: List, _ handler: ProviderResult<Section> -> Void) {
        
        // load section or create one (there's no more section data in the input besides of the name, so there's nothing to update).
        // There is no name update since here we have only name so either the name is in db or it's not, if it's not insert a new section
        loadSection(sectionName, list: list) {result in
            
            // TODO!!!! check if the optional section from db works otherwise return to using .Success / .NotFound with non optional
            // load product and update or create one
            // if we find a product with the name we update it - this is for the case the user changes the price for an existing product while adding an item
            if let existingSectionMaybe = result.sucessResult {
                if let existingSection = existingSectionMaybe {
                    handler(ProviderResult(status: .Success, sucessResult: existingSection))
                    
                } else {
                    if let order = possibleNewOrder {
                        let section = Section(uuid: NSUUID().UUIDString, name: sectionName, color: sectionColor, list: list, order: order)
                        handler(ProviderResult(status: .Success, sucessResult: section))
                        
                    } else { // no order known in advance - fetch listItems to count how many sections, order at the end
                        
                        Providers.listItemsProvider.listItems(list, sortOrderByStatus: .Stash, fetchMode: ProviderFetchModus.First) {result in
                            
                            if let listItems = result.sucessResult {
                                let order = listItems.sectionCount(status)
                                
                                let section = Section(uuid: NSUUID().UUIDString, name: sectionName, color: sectionColor, list: list, order: ListItemStatusOrder(status: status, order: order))
                                handler(ProviderResult(status: .Success, sucessResult: section))
                                
                            } else {
                                print("Error: loading section: \(result.status)")
                                handler(ProviderResult(status: .DatabaseUnknown))
                            }
                        }
                    }
                }
                
            } else {
                print("Error: loading section: \(result.status)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
}

