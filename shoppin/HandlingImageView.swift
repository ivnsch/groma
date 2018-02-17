//
//  HandlingImageView.swift
//
//  Created by Ivan Schuetz on 17.02.18.
//
import UIKit

open class HandlingImageView: UIImageView {

    open var movedToSuperViewHandler: (() -> ())?
    open var touchHandler: (() -> ())?

    override open func didMoveToSuperview() {
        movedToSuperViewHandler?()
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchHandler?()
    }
}

