//
//  BaseOrUnitCellView.swift
//  groma
//
//  Created by Ivan Schuetz on 21.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

protocol BaseOrUnitCellView {

    var backgroundView: UIView { get }

    func mark(toDelete: Bool, animated: Bool)
    func showSelected(selected: Bool, animated: Bool)
}

extension BaseOrUnitCellView where Self: UIView {

    func mark(toDelete: Bool, animated: Bool) {
        animIf(animated) { [weak self] in
            self?.backgroundView.backgroundColor = toDelete ? UIColor.flatRed : Theme.grey
        }
    }

    func showSelected(selected: Bool, animated: Bool) {
        backgroundView.backgroundColor = selected ? Theme.green : Theme.grey
    }
}



