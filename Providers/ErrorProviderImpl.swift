//
//  ErrorProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 02/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


class ErrorProviderImpl: ErrorProvider {

    fileprivate let remoteProvider = RemoteErrorReporter()
    
    func reportError(_ error: ErrorReport) {
        logger.d("Reporting an error: \(error)")
        remoteProvider.report(error) {remoteResult in
            if !remoteResult.success {
                logger.e("Coudn't report error: \(remoteResult)")
            }
        }
    }
}
