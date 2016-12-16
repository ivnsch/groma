//
//  ProviderFetchModus.swift
//  shoppin
//
//  Created by ischuetz on 27/07/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO these fetch modes are a mess and are mostly used incorrectly - fix!
public enum ProviderFetchModus {

    case first // handler is invoked only on first successful result, either from local DB or remote - memory cache not considered here (backward compatibility)
    case both // handler is invoked if local DB is successful and also when the remote call completes (latest only if the remote call result is different than local DB result)

    // TODO rename, and do we still need "First" maybe remove that, adjust handling accordingly and name this "First"?
    case memOnly // only retrieve from memory and don't do background udpates (not db or server). If the memory cache is disabled, falls back to .First
}
