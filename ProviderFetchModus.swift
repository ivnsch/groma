//
//  ProviderFetchModus.swift
//  shoppin
//
//  Created by ischuetz on 27/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

enum ProviderFetchModus {

    case First // handler is invoked only on first successful result, either from local DB or remote
    case Both // handler is invoked if local DB is successful and also when the remote call completes (latest only if the remote call result is different than local DB result)
}
