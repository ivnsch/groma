//
//  UnitsDelegate.swift
//  shoppin
//
//  Created by Ivan Schuetz on 20/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

protocol UnitsCollectionViewDelegateDelegate: class {
    func sizeFotUnitCell(indexPath: IndexPath) -> CGSize
    func didSelectUnit(indexPath: IndexPath)
}

class UnitsDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    fileprivate weak var delegate: UnitsCollectionViewDelegateDelegate?
    
    init(delegate: UnitsCollectionViewDelegateDelegate) {
        self.delegate = delegate
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectUnit(indexPath: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return delegate?.sizeFotUnitCell(indexPath: indexPath) ?? CGSize.zero
    }
}
