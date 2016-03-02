//
//  ErrorProvider.swift
//  shoppin
//
//  Created by ischuetz on 02/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

protocol ErrorProvider {

    func reportError(error: ErrorReport)
}
