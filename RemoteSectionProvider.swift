//
//  RemoteSectionProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class RemoteSectionProvider: RemoteProvider {

    func removeSection(_ uuid: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.section + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func updateSections(_ sections: [Section], handler: @escaping (RemoteResult<Int64>) -> ()) {
        let listItemProvider = RemoteListItemProvider()
        let parameters: [[String: AnyObject]] = sections.map{listItemProvider.toRequestParams($0)}
        RemoteProvider.authenticatedRequestArrayParamsTimestamp(.put, Urls.sections, parameters) {result in
            handler(result)
        }
    }
    
    func removeSectionsWithName(_ name: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        RemoteProvider.authenticatedRequest(.delete, Urls.sectionsName + "/\(encodedName)") {result in
            handler(result)
        }
    }
}
