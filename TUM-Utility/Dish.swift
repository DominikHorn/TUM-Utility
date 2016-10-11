//
//  Dish.swift
//  TUM-Utility
//
//  Created by Dominik Horn on 13.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import Foundation

/// Storage class for a single dish
@objc(Dish)
class Dish: NSObject, NSCoding {
    /// NSCoding keys
    private let descriptionTextKey = "descriptionText"
    private let priceKey = "price"
    
    /// Description of this dish
    var descriptionText: String
    
    /// Price of this dish
    var price: Double
    
    // TODO: add/parse ingredients and categorisation (Vegetarian etc)
    
    //// Initialize with a description and a price
    init(descriptionText: String, price: Double) {
        self.descriptionText = descriptionText
        self.price = price
    }
    
    /// NSCoding initializer
    required init(coder: NSCoder) {
        self.descriptionText = coder.decodeObject(forKey: descriptionTextKey) as! String
        self.price = coder.decodeDouble(forKey: priceKey)
    }
    
    /// NSCoding encoder
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.descriptionText, forKey: descriptionTextKey)
        aCoder.encode(self.price, forKey: priceKey)
    }
    
    func containsEqualContentAs(otherDish: Dish) -> Bool {
        return otherDish.descriptionText == self.descriptionText && otherDish.price == self.price
    }
}
