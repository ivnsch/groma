//
//  IngredientDataController.swift
//  groma
//
//  Created by Ivan Schuetz on 16.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class IngredientDataController: UITableViewController {

    weak var controller: QuickAddListItemViewController?

    fileprivate var unitsManager = IngredientUnitCollectionViewManager()

    fileprivate var quantityView: IngredientQuantityView!

    var cellCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        unitsManager.configure(controller: self)
        initQuantityView()

        cellCount = 3
        reload()
    }


    fileprivate func initQuantityView() {
        quantityView = IngredientQuantityView.createView()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = SelectIngredientDataHeader.createView()
        header.backgroundColor = UIColor.flatRed
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.selectionStyle = .none

        cell.contentView.removeSubviews()

        switch indexPath.row {
        case 0:
            let view = unitsManager.view
            cell.contentView.addSubview(view)
            view.frame = cell.contentView.bounds // appears to be necessary
            view.fillSuperview()
            return cell
        case 1:
            cell.contentView.addSubview(quantityView)
            quantityView.frame = cell.contentView.bounds // appears to be necessary
            quantityView.fillSuperview()

            if let units = unitsManager.units {
                let moundUnit = units.findFirst { $0.id == .spoon}
                quantityView.configure(unit: moundUnit!, fraction: Fraction(numerator: 1, denominator: 2))
            }
            return cell
        case 2: return cell
        default: fatalError("Only 3 cells supported")
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0: return unitsManager.unitContentsHeight
        case 1: return 300
        case 2: return 300
        default: fatalError("Only 3 cells supported")
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        controller?.scrollableBottomAttacher?.onBottomViewDidScroll(scrollView)
    }
}

