//
//  RestaurantTableViewCell.swift
//  TUM-Utility
//
//  Created by Dominik Horn on 19.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import UIKit

class RestaurantTableViewCell: UITableViewCell {
    @IBOutlet weak var restaurantNameLabel: UILabel?
    
    @IBOutlet weak var dishesView: UITextView?
    
    func add(dishes: [Dish]) {
        // Reset text
        dishesView?.text = ""
        
        // Convenience
        let mutableAttrString = NSMutableAttributedString(string: "")
        
        // Add each dish
        for i in 0..<dishes.count {
            // Don't print \n on first line (no need for it!)
            if (i > 0) {
                mutableAttrString.append(NSAttributedString(string: "\n"))
            }
            
            let dish = dishes[i]
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment =  NSTextAlignment.right
            
            let dishPriceString = String(format: "%.2f €", dish.price)
            let dishText = NSMutableAttributedString(string: "\(i+1). \(dish.descriptionText)")
            dishText.addAttributes([NSForegroundColorAttributeName:UIColor.darkText], range: NSRange(0..<dishText.string.characters.count))
            let dishPrice = NSMutableAttributedString(string: "\(dishPriceString)")
            dishPrice.addAttributes([NSFontAttributeName : UIFont.systemFont(ofSize: 12, weight: UIFontWeightBold), NSParagraphStyleAttributeName : paragraphStyle, NSForegroundColorAttributeName : UIColor.darkText], range: NSRange(0..<6)) // TODO: right align + get propper range (dynamic end index)
            mutableAttrString.append(dishText)
            mutableAttrString.append(NSAttributedString(string: "\n"))
            mutableAttrString.append(dishPrice)
        }
        
        dishesView?.attributedText = mutableAttrString
    }
}
