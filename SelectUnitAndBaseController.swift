//
//  SelectUnitAndBaseController.swift
//  groma
//
//  Created by Ivan Schuetz on 20.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class SelectUnitAndBaseController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    fileprivate var unitsManager = IngredientUnitCollectionViewManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(UINib(nibName: "IngredientDataSubHeaderCell", bundle: nil), forCellReuseIdentifier: "subHeaderCell")
        tableView.register(UINib(nibName: "AddNewItemInputCell", bundle: nil), forCellReuseIdentifier: "inputCell")
    }
}
extension SelectUnitAndBaseController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        func dequeueDefaultCell() -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.selectionStyle = .none
            cell.contentView.removeSubviews()
            return cell
        }

        switch indexPath.row {
        case 1:
            let cell = dequeueDefaultCell()
            let view = unitsManager.view
            cell.contentView.addSubview(view)
            view.frame = cell.contentView.bounds // appears to be necessary
            view.fillSuperview()
            return cell
        case 4:
            let cell = dequeueDefaultCell()
            let view = unitsManager.view
            cell.contentView.addSubview(view)
            view.frame = cell.contentView.bounds // appears to be necessary
            view.fillSuperview()
            return cell
        case 0, 3: // headers
            let header = tableView.dequeueReusableCell(withIdentifier: "subHeaderCell", for: indexPath) as! IngredientDataSubHeaderCell
            header.title.text = indexPath.row == 0 ? trans("select_ingredient_data_header_units") : trans("select_ingredient_data_header_quantity")
            return header
        case 2, 5: // inputs
//            let unitInputCell = tableView.dequeueReusableCell(withIdentifier: "unitInputCell", for: indexPath) as! AddNewItemInputCell
//            unitInputCell.configure(placeholder: trans("enter_custom_unit_placeholder"), onInputUpdate: { [weak self] unitInput in
//                self?.inputs.newUnitInput = unitInput.isEmpty ? nil : unitInput
//                if !unitInput.isEmpty {
//                    self?.inputs.unit = nil
//                    self?.unitsManager.clearSelectedUnits() // Input overwrites possible selection
//                    self?.unitsManager.clearToDeleteUnits() // Clear delete state too
//                }
//            })
//            return unitInputCell
            fatalError("TODO")
        default: fatalError("Not supported index: \(indexPath.row)")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        fatalError("TODO")
    }
}
