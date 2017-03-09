//
//  HandlingView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 09/03/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

// Convenience view to handle events without subclassing
open class HandlingView: UIView {
    
    open var movedToSuperViewHandler: (() -> ())?
    open var touchHandler: (() -> ())?
    
    override open func didMoveToSuperview() {
        self.movedToSuperViewHandler?()
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchHandler?()
    }
}
