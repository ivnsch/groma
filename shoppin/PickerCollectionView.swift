//
//  PickerCollectionView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 21/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

protocol PickerCollectionViewDelegate: class {
    
    var cellSize: CGSize {get}
    var cellSpacing: CGFloat {get}
//    var sizeForFirstLastItem: CGSize {get}
    
    func onStartScrolling()
    func onSelectItem(index: Int)
    
    func onSnap(cellIndex: Int)
}

class PickerCollectionView: UIView, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    fileprivate(set) var collectionView: UICollectionView!
    
    weak var delegate: PickerCollectionViewDelegate?
    
    var open: Bool = false
    
    fileprivate let boxY: CGFloat
    fileprivate let boxCenterY: CGFloat
    
    fileprivate var boxHeight: CGFloat {
        return (boxCenterY - boxY) * 2
    }
    
    fileprivate let cellHeight: CGFloat
    fileprivate let cellSpacing: CGFloat
    
    // TODO are boxY and boxCenterY still necessary? 
    
    convenience init(size: CGSize, center: CGPoint, layout: UICollectionViewLayout, boxY: CGFloat, boxCenterY: CGFloat, cellHeight: CGFloat, cellSpacing: CGFloat, delegate: PickerCollectionViewDelegate) {
        self.init(frame: CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height), layout: layout, boxY: boxY, boxCenterY: boxCenterY, cellHeight: cellHeight, cellSpacing: cellSpacing, delegate: delegate)
    }
    
    init(frame: CGRect, layout: UICollectionViewLayout, boxY: CGFloat, boxCenterY: CGFloat, cellHeight: CGFloat, cellSpacing: CGFloat, delegate: PickerCollectionViewDelegate) {
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), collectionViewLayout: layout)
        
        self.boxY = boxY
        self.boxCenterY = boxCenterY
        
        self.cellHeight = cellHeight
        self.cellSpacing = cellSpacing
        
        self.delegate = delegate
        
        super.init(frame: frame)
        
        addSubview(collectionView)

        let size = delegate.cellSize
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset = UIEdgeInsets(top: frame.height / 2 - size.height / 2, left: 0, bottom: frame.height / 2 - size.height / 2, right: 0)
        
        initMasks()
        
        collectionView.delegate = self
    }
    
    var insets: UIEdgeInsets {
        return (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset
    }
    
    func scrollToItem(index: Int, animated: Bool = true) {
        guard let delegate = delegate else {logger.w("No delegate"); return}
        
        let size = delegate.cellSize
        let cellHeight = size.height
        let cellSpacing = delegate.cellSpacing
        
        let insets = UIEdgeInsets(top: frame.height / 2 - size.height / 2, left: 0, bottom: frame.height / 2 - size.height / 2, right: 0)
        
        let itemCenterInCollectionView = CGFloat(index) * (cellHeight + cellSpacing) + cellHeight / 2 + insets.top
        
//        let boxCenterRelativeToCollectionViewTop: CGFloat = boxCenterY - wheelVar.frame.origin.y
        let boxCenterRelativeToCollectionViewTop: CGFloat = center.y - frame.origin.y // NOTE: boxCenterY -> center.y assumption that the collection view center is the same as the box center.
        let boxCenterRelativeToCollectionContentView: CGFloat = collectionView.contentOffset.y + boxCenterRelativeToCollectionViewTop
        
        let offsetDelta = itemCenterInCollectionView - boxCenterRelativeToCollectionContentView
        let offset = collectionView.contentOffset.y + offsetDelta
        
        collectionView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    fileprivate func initMasks() {

        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height / 2)
        gradient.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 1)
        gradient.endPoint = CGPoint(x: 0, y: 0)
        
        let gradient2 = CAGradientLayer()
        gradient2.frame = CGRect(x: 0, y: bounds.height / 2, width: bounds.width, height: bounds.height / 2)
        gradient2.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
        gradient2.startPoint = CGPoint(x: 0, y: 0)
        gradient2.endPoint = CGPoint(x: 0, y: 1)
        
        
        let combinedGradient = CALayer()
        combinedGradient.frame = bounds
        combinedGradient.addSublayer(gradient)
        combinedGradient.addSublayer(gradient2)
        
        layer.mask = combinedGradient
        
    }
    
//    
//    func onStartScrolling() {
//        delegate?.onStartScrolling()
//    }
//    
//    func onSelectItem(index: Int) {
//        delegate?.onSelectItem(index: index)
//    }
//    
//    func onSnap(cellIndex: Int) {
//        delegate?.onSnap(cellIndex: cellIndex)
//    }
//    
    
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        scrollToItem(index: indexPath.row)
        delegate?.onSelectItem(index: indexPath.row)
    }
    
    fileprivate func snap(scrollView: UIScrollView) {
        
        let totalCellHeight = cellHeight + cellSpacing
        
        let offset = scrollView.contentOffset.y
    
        let cellStart = floor((offset) / totalCellHeight) * totalCellHeight
        
        let nextCellStart = cellStart + totalCellHeight
        
        var cellStartToUse: CGFloat

        if abs(offset - cellStart) < abs(offset - nextCellStart) {
            cellStartToUse = cellStart
        } else {
            cellStartToUse = nextCellStart
        }
        
        let newOffset = cellStartToUse
        
        scrollView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: true)
        
        let cellIndex = cellStartToUse / totalCellHeight
        
        delegate?.onSnap(cellIndex: max(0, Int(cellIndex)))
    }
    
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            snap(scrollView: scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snap(scrollView: scrollView)
    }
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.onStartScrolling()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return delegate?.cellSize ?? CGSize.zero
    }
}


//
///// Delegate of the collection view in PickerCollectionView
//class PickerCollectionViewCollectionViewDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
//
//    var picker: PickerCollectionView?
//    
//    let boxY: CGFloat
//    let boxCenterY: CGFloat
//    
//    let cellHeight: CGFloat
//    let cellSpacing: CGFloat
//    
//    init(boxY: CGFloat, boxCenterY: CGFloat, cellHeight: CGFloat, cellSpacing: CGFloat) {
//        self.boxY = boxY
//        self.boxCenterY = boxCenterY
//        
//        self.cellHeight = cellHeight
//        self.cellSpacing = cellSpacing
//    }
//   }
