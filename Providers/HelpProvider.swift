//
//  HelpProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public protocol HelpProvider {

    func helpItems(_ handler: @escaping (ProviderResult<[HelpItem]>) -> Void)
}
