//
//  HandlingButton.swift
//  shoppin
//
//  Created by ischuetz on 25/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class HandlingButton: UIButton {

    var tapHandler: VoidFunction?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    fileprivate func sharedInit() {
        addTarget(self, action: #selector(HandlingButton.onTap(_:)), for: .touchUpInside)
    }

    @objc func onTap(_ sender: UIButton) {
        tapHandler?()
    }
}
