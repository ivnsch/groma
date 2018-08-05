//
// Created by Ivan Schuetz on 05.08.18.
//

import Foundation

enum MostCompleteItemMatch {
    case listItem(listItem: ListItem)
    case storeProduct(storeProduct: StoreProduct)
    case quantifiableProduct(quantifiablProduct: QuantifiableProduct)
    case product(product: Product)
    case item(item: Item)
    case none
}
