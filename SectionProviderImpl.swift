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
    
    // TODO! use list
    func loadSection(name: String, list: List, handler: ProviderResult<Section> -> ()) {
        dbProvider.loadSection(name) {dbSectionMaybe in
            if let dbSection = dbSectionMaybe {
                handler(ProviderResult(status: .Success, sucessResult: dbSection))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
            
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
        self.dbProvider.saveSection(section) {saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            if saved && remote {
                // TODO!! server
            }
        }
    }
    
    func remove(section: Section, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        Providers.listItemsProvider.invalidateMemCache()
        self.dbProvider.remove(section) {removed in
            handler(ProviderResult(status: removed ? .Success : .DatabaseUnknown))
            if removed && remote {
                // TODO!! server
            }
        }
    }
    
    func update(sections: [Section], remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        Providers.listItemsProvider.invalidateMemCache()
        self.dbProvider.update(sections) {updated in
            handler(ProviderResult(status: updated ? .Success : .DatabaseUnknown))
            if updated && remote {
                // TODO!! server
            }
        }
    }
    
    func sectionSuggestions(handler: ProviderResult<[Suggestion]> -> ()) {
        dbProvider.loadSectionSuggestions {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSuggestions))
        }
    }

    func sections(names: [String], handler: ProviderResult<[Section]> -> ()) {
        self.dbProvider.loadSections(names) {dbSections in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSections))
        }
    }
    
    func mergeOrCreateSection(sectionName: String, possibleNewOrder: Int?, list: List, _ handler: ProviderResult<Section> -> Void) {
        
        // load section or create one (there's no more section data in the input besides of the name, so there's nothing to update).
        // There is no name update since here we have only name so either the name is in db or it's not, if it's not insert a new section
        loadSection(sectionName, list: list) {result in
            
            // load product and update or create one
            // if we find a product with the name we update it - this is for the case the user changes the price for an existing product while adding an item
            if let existingSection = result.sucessResult {
                handler(ProviderResult(status: .Success, sucessResult: existingSection))
                
            } else {
                if result.status == .NotFound { // new section
                    
                    if let order = possibleNewOrder {
                        let section = Section(uuid: NSUUID().UUIDString, name: sectionName, order: order)
                        handler(ProviderResult(status: .Success, sucessResult: section))
                        
                    } else { // no order known in advance - fetch listItems to count how many sections, order at the end
                        
                        Providers.listItemsProvider.listItems(list, fetchMode: ProviderFetchModus.First) {result in
                            
                            if let listItems = result.sucessResult {
                                let order = listItems.sectionCount
                                
                                let section = Section(uuid: NSUUID().UUIDString, name: sectionName, order: order)
                                handler(ProviderResult(status: .Success, sucessResult: section))
                                
                            } else {
                                print("Error: loading section: \(result.status)")
                                handler(ProviderResult(status: .DatabaseUnknown))
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
}

