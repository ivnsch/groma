//
//  ErrorProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 02/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class ErrorProviderImpl: ErrorProvider {

    fileprivate let remoteProvider = RemoteErrorReporter()
    
    func reportError(_ error: ErrorReport) {
        QL2("Reporting an error: \(error)")
        remoteProvider.report(error) {remoteResult in
            if !remoteResult.success {
                QL4("Coudn't report error: \(remoteResult)")
            }
        }
    }
}
