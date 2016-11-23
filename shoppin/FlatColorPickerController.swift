//
//  FlatColorPickerController.swift
//  shoppin
//
//  Created by ischuetz on 10/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework

protocol FlatColorPickerControllerDelegate: class {
    func onColorPicked(_ color: UIColor)
    func onDismiss()
}

class FlatColorPickerController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let flatColors: [UIColor] = [
        UIColor.flatRedDark,
        UIColor.flatOrangeDark,
        UIColor.flatYellowDark,
        UIColor.flatSandDark,
        UIColor.flatNavyBlueDark,
        UIColor.flatBlackDark,
        UIColor.flatMagentaDark,
        UIColor.flatTealDark,
        UIColor.flatSkyBlueDark,
        UIColor.flatGreenDark,
        UIColor.flatMintDark,
        UIColor.flatWhiteDark,
        UIColor.flatGrayDark,
        UIColor.flatForestGreenDark,
        UIColor.flatPurpleDark,
        UIColor.flatBrownDark,
        UIColor.flatPlumDark,
        UIColor.flatWatermelonDark,
        UIColor.flatPinkDark,
        UIColor.flatMaroonDark,
        UIColor.flatCoffeeDark,
        UIColor.flatPowderBlueDark,
        UIColor.flatBlueDark
    ]
    
    weak var delegate: FlatColorPickerControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIXME dismiss by tapping on outer borders - doesn't work, this consumes the tap on the cells despite view it's behind
//        let tap = UITapGestureRecognizer(target: self, action: "onTapCollectionViewBG:")
//        view.addGestureRecognizer(tap)
    }
    
    func onTapCollectionViewBG(_ sender: UIView) {
        delegate?.onDismiss()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flatColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        let color = flatColors[(indexPath as NSIndexPath).row]
        let circleSize = DimensionsManager.colorCircleSize
        let padding = (DimensionsManager.colorCircleCellSize - circleSize) / 2
        let circleView = CircleView(frame: CGRect(x: padding, y: padding, width: circleSize, height: circleSize))
        circleView.color = color
        circleView.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.white
        cell.contentView.addSubview(circleView)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let color = flatColors[(indexPath as NSIndexPath).row]
        delegate?.onColorPicked(color)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return CGSize(width: DimensionsManager.colorCircleCellSize, height: DimensionsManager.colorCircleCellSize)
    }
}


private class CircleView: UIView {
    
    var color = UIColor.clear
    
    fileprivate override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.addEllipse(in: rect)
        ctx?.setFillColor(color.cgColor.components!)
        ctx?.fillPath()
    }
}
