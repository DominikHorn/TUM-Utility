//
//  Restaurant.swift
//  TUM-Utility
//
//  Created by Dominik Horn on 13.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import Foundation

/// Stores all information to be had for each restaurant available
@objc(Restaurant)
class Restaurant: NSObject, NSCoding {
    /// userdefaults keys
    let nameKey = "name"
    let foodCalendarKey = "foodCalendar"
    
    /// Restaurant's name
    var name: String
    
    /// Dictionary which holds every dish for each date
    var foodCalendar: [Date:[Dish]]
    
    /// Init Restaurant with a name and no dishes
    init(name: String) {
        self.name = name
        self.foodCalendar = [:]
    }
    
    /// NSCoding initializer
    required init(coder: NSCoder) {
        self.name = coder.decodeObject(forKey: nameKey) as! String
        self.foodCalendar = coder.decodeObject(forKey: foodCalendarKey) as! [Date : [Dish]]
    }
    
    /// NSCoding encoder
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: nameKey)
        aCoder.encode(self.foodCalendar, forKey: foodCalendarKey)
    }
    
    /// Sets dishes for this restaurant for given Date
    func set(dishes: [Dish], date: Date) {
        // Check for nil and allocate array if needed
        if self.foodCalendar[date] == nil {
            self.foodCalendar[date] = []
        }
        
        self.foodCalendar[date] = dishes
    }
    
    /// Adds dishes to this restaurant for given Date
    func add(dishes: [Dish], date: Date) {
        // Check for nil and allocate array if needed
        if self.foodCalendar[date] == nil {
            self.foodCalendar[date] = []
        }
        
        for dish in dishes {
            self.foodCalendar[date]?.append(dish)
        }
    }
    
    /// Retrieves a list of dishes for a certain date
    func getDishesFor(date: Date) -> [Dish] {
        let calendar = NSCalendar.current
        for storedFoodKVPair in foodCalendar {
            if calendar.isDate(date, equalTo: storedFoodKVPair.key, toGranularity: .day) {
                return storedFoodKVPair.value
            }
        }
        
        return [Dish]()
    }
}
