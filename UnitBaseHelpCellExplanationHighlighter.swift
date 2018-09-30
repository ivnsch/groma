//
//  UnitBaseHelpCellExplanationHighlighter.swift
//  groma
//
//  Created by Ivan Schuetz on 10.02.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import Providers

struct UnitBaseHelpCellExplanationHighlighter {

    func generateAttributedString(colorDict: [BaseUnitHelpItemType: UIColor], text: String, font: UIFont) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font: font])
        for placeholder in [1, 2, 3, 4, 5] {
            if let (range, color) = highlight(placeholderNumber: placeholder, text: text, colors: colorDict) {
                attributedString.setAttributes([NSAttributedString.Key.foregroundColor: color], range: range)
            }
        }
        attributedString.mutableString.replaceOccurrences(of: "%%\\d+", with: "", options: NSString.CompareOptions.regularExpression, range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }

    // markers have the form %%n...%%n
    fileprivate func highlight(placeholderNumber: Int, text: String, colors: [BaseUnitHelpItemType: UIColor]) -> (range: NSRange, color: UIColor)? {
        let itemType: BaseUnitHelpItemType = {
            switch placeholderNumber {
            case 1: return .unit
            case 2: return .base
            case 3: return .secondBase
            case 4: return .refQuantity
            case 5: return .price
            default:
                logger.e("Not supported placeholder: \(placeholderNumber). Returning a default.", .ui)
                return .unit // just return something
            }
        } ()

        guard let color = colors[itemType] else {
            logger.e("Invalid state: dictionary should have colors for all possible item types.", .ui)
            return nil
        }

        if let range = findRangeForPlaceholder(number: placeholderNumber, text: text) {
            return (range, color)
        }

        return nil
    }

    fileprivate func findRangeForPlaceholder(number: Int, text: String) -> NSRange? {
        do {
            let delimiter = "%%\(number)"
            let regex = try NSRegularExpression(pattern: "\(delimiter)(.*)\(delimiter)", options:[.caseInsensitive])
            let results = regex.matches(in: text, options: [], range: NSMakeRange(0, text.count))

            guard !results.isEmpty else {
//                logger.d("Results for placeholder: \(number) is empty", .ui) // better just don't show anything
                return nil
            }

            guard results.count == 1 else {
                logger.e("Unexpected: results count is not 1: \(results.count)", .ui)
                return nil
            }

            for result in results {
                guard result.numberOfRanges >= 1 else {
                    logger.e("Unexpected: results doesn't contain range. Number of ranges: \(result.numberOfRanges)", .ui)
                    return nil
                }
                return result.range(at: 1)  //< Ex: 'AA01'
            }

            return nil

        } catch (let e) {
            logger.e("Error creating regex. Can't highlight color in label: \(e)", .ui)
            return nil
        }
    }
}

