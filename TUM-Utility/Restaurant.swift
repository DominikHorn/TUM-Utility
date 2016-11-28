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
    private let nameKey = "name"
    private let shortHandNameKey = "shortHandName"
    private let foodCalendarKey = "foodCalendar"
    private let longditudeKey = "longditude"
    private let latitudeKey = "latitude"
    private let idKey = "id"
    private let addressKey = "address"
    
    /// Restaurant's name
    var name: String
    
    /// Restaurant's shorthand name
    var shortHandName: String
    
    /// Dictionary which holds every dish for each date
    var foodCalendar: [Date:[Dish]]
    
    /// Geographical location of this restaurant
    var longditude: Double
    var latitude: Double
    
    /// id that a restaurant has
    var id: Int
    
    /// Restaurant's address
    var address: String
    
    /// Init Restaurant with a name and no dishes
    convenience init(name: String, shortHandName: String, longditude: Double, latitude: Double, address: String) {
        self.init(name: name, shortHandName: shortHandName, longditude: longditude, latitude: latitude, address: address, id: -1)
    }
    
    /// Convenience init
    init(name: String, shortHandName: String, longditude: Double, latitude: Double, address: String, id: Int) {
        self.name = name
        self.shortHandName = shortHandName
        self.longditude = longditude
        self.latitude = latitude
        self.id = id
        self.address = address
        self.foodCalendar = [:]
        
        // Call super initializer
        super.init()
    }
    
    /// NSCoding initializer
    required init(coder: NSCoder) {
        self.name = coder.decodeObject(forKey: self.nameKey) as! String
        self.shortHandName = coder.decodeObject(forKey: self.shortHandNameKey) as! String
        self.longditude = coder.decodeDouble(forKey: self.longditudeKey)
        self.latitude = coder.decodeDouble(forKey: self.latitudeKey)
        self.foodCalendar = coder.decodeObject(forKey: self.foodCalendarKey) as! [Date : [Dish]]
        self.id = coder.decodeInteger(forKey: self.idKey)
        self.address = coder.decodeObject(forKey: self.addressKey) as! String
    }
    
    /// NSCoding encoder
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.address, forKey: self.addressKey)
        aCoder.encode(self.id, forKey: self.idKey)
        aCoder.encode(self.foodCalendar, forKey: self.foodCalendarKey)
        aCoder.encode(self.latitude, forKey: self.latitudeKey)
        aCoder.encode(self.longditude, forKey: self.longditudeKey)
        aCoder.encode(self.shortHandName, forKey: self.shortHandNameKey)
        aCoder.encode(self.name, forKey: self.nameKey)
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
