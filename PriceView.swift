//
//  PriceView.swift
//  groma
//
//  Created by Ivan Schuetz on 03.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit

class PriceView: HandlingView {

    @IBOutlet weak var priceLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    fileprivate func sharedInit() {
        let view = Bundle.loadView("PriceView", owner: self)!
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.fillSuperview()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.borderColor = Theme.midGrey.cgColor
        layer.backgroundColor = UIColor.white.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 4
    }

    func configure(onTap: (() -> Void)?) {
        touchHandler = {
            onTap?()
        }
    }

    func show(price: Float) {
        priceLabel.text = price.toLocalCurrencyString()
        priceLabel.sizeToFit()
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: priceLabel.intrinsicContentSize.width + 2 * 10, height: priceLabel.intrinsicContentSize.height + 2 * 4)
    }
}
