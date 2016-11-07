//
//  BetriebsParser.swift
//  TUM-Utility
//
//  Created by Dominik Horn on 07.11.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import Foundation

class BetriebsParser {
    /// Parser used for parsing pdf
    private let pdfParser: PDFParser
    
    /// Used to keep trac of parsed restaurants
    private var parsedRestaurants: [Restaurant]
    
    init() {
        self.pdfParser = PDFParser()
        self.parsedRestaurants = []
    }
    
    func parseFiles(at path: String) -> [Restaurant] {
        // Reset parsed restaurants
        self.parsedRestaurants = []
        
        do {
            // For every file at path, parse
            try FileManager.default.contentsOfDirectory(atPath: path).forEach() { (file) in
                // Parse file
                self.parse(URL(string: path)?.appendingPathComponent(file))
            }
            
            // Sort through every parsed restaurant and do post processing
            // Merge FMI and IPP menus (everything available at fmi can be taken away from ipp menu)
            let fmiRestaurant = self.getRestaurantFor(name:"FMI")
            fmiRestaurant?.name = "FMI\n+\nIPP"
            let ippRestaurant = self.getRestaurantFor(name: "IPP")
            
            // remove all dishes from IPP that occure at the same date in FMI
            for ippPair in (ippRestaurant?.foodCalendar)! {
                ippRestaurant?.foodCalendar[ippPair.key] = ippPair.value.filter() {
                    for fmiDish in (fmiRestaurant?.getDishesFor(date: ippPair.key))! {
                        if Utility.levenshtein(aStr: fmiDish.descriptionText, bStr: $0.descriptionText) <= lenDiff(str1: $0.descriptionText, str2: fmiDish.descriptionText) + 10 {
                            return false
                        }
                    }
                    
                    return true
                }
            }
        } catch {
            print("Error parsing files!")
        }
        
        // Return restaurants
        return self.parsedRestaurants
    }
    
    private func parse(_ url: URL?) {
        guard let url = url else {
            return
        }
        
        // Init
        let pdfContent: String = pdfParser.getPdfString(url)
        var parsedLines: [String] = pdfContent.characters.split{$0 == "\n"}.map(String.init)
        
        // Retrieve restaurant for name
        guard let restaurant = self.getRestaurantFor(name: parsedLines[1]) else {
            return
        }
        
        // Trim first few lines (Unnecessary data that we should have parse by now)
        parsedLines = Array(parsedLines[4..<(parsedLines.count-1)])
        while (parsedLines.count > 2) {
            // Parse one food date
            let result = try! parseFoodCalendarForDate(lines: parsedLines)
            
            // If no lines were consumed the pdf is out of foodCalendarDates and dishes -> break
            guard result.usedCount >= 1 else {
                break
            }
            
            // Add dishes to restaurant
            restaurant.set(dishes: result.dishes, date: result.date!)
            
            // Remove new parsed lines
            parsedLines = Array(parsedLines[result.usedCount..<(parsedLines.count-1)])
        }
        
        return
    }
    
    private func parseFoodCalendarForDate(lines: [String]) throws -> (usedCount: Int, date: Date?, dishes: [Dish]) {
        // Sanity checks
        guard lines.count > 0 else {
            print("Error: no lines were fed into parseFoodCalendarForDate")
            throw InvalidArgumentError()
        }
        
        // Used counter to keep track of which lines we consumned
        var usedCounter = 0
        
        // dish list we build in this method
        var dishList: [Dish] = []
        
        // Parse date (should be on first line)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "EEEE, 'den' dd.MM.yyyy"
        let date = dateFormatter.date(from: lines[0])
        
        // Did we obtain a date? No -> return since we can't parse further
        guard date != nil else {
            return (0, nil, dishList)
        }
        
        // We consumed the dateline
        usedCounter += 1
        
        // SWIFT FUCKA YOOOUUAU!! TODO: may we PLEAASE CHANGE THIS SHIT
        var iOffset = 0
        
        // Parse all the dishes (signified by number the at start the of line)
        for i in (1..<lines.count) {
            // Fetch line
            let dishStart = lines[i + iOffset]
            
            // Check if this is still a dish line (e.g. part of a numbered line)
            if !Utility.lineIsPartOfNumberedList(string: dishStart) {
                if (i + iOffset + 1 < lines.count) && lineStartsWithSpecialDate(line: lines[i + iOffset + 1]) {
                    // Consume trash line
                    usedCounter += 1
                }
                
                break
            }
            
            var currentLine = dishStart
            var dishText = ""
            // Check if we need to consume even more lines (line break in dish title)
            repeat {
                // Increase consumedLines counter depending on how many lines we need to consume for one dish
                usedCounter+=1
                
                // Reassign current line
                currentLine = lines[i + iOffset]
                
                // Append string to dishText
                dishText += " " + currentLine
                
                // increase j
                iOffset += 1
            } while !(Utility.lineEndsWithPrice(line: currentLine))
            
            // Account for consumed lines in repeat
            iOffset -= 1
            
            // Trim trailing and preceeding whitespaces and newlines etc
            dishText = dishText.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            
            // Extract price via infix operator
            let priceMatch = try! (dishText =~~ /Utility.REGEX_LINEENDSWITHPRICE)[0]
            let priceText: NSString = (dishText as NSString).substring(with: priceMatch.range) as NSString
            let price = priceText.doubleValue
            
            // Parse "Vegetarisch" as symbol:
            dishText = dishText.replacingOccurrences(of: ".V ", with: ".♻️")
            dishText = dishText.replacingOccurrences(of: " V ", with: "♻️")
            
            // Cut number and price from dishText
            dishText = dishText.substring(with: dishText.index(dishText.startIndex, offsetBy: 2)..<dishText.index(dishText.endIndex, offsetBy: -priceMatch.range.length))
            
            // Create dish and append to list for this date
            dishList.append(Dish(descriptionText: dishText, price: price))
        }
        
        return (usedCounter, date, dishList)
    }
    
    private func lenDiff(str1: String, str2: String) -> Int {
        let len1 = str1.characters.count
        let len2 = str2.characters.count
        if len1 > len2 {
            return len1 - len2
        } else {
            return len2 - len1
        }
    }
    
    private func lineStartsWithSpecialDate(line: String) -> Bool {
        /// TODO: factor this code out since it's used multiple times
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "EEEE, 'den' dd.MM.yyyy"
        let date = dateFormatter.date(from: line)
        
        return date != nil
    }

    private func getRestaurantFor(name: String?) -> Restaurant? {
        // Return if string is nil
        guard let name = name else {
            return nil
        }
        
        // Return first occurence of restaurant with that name
        for rest in self.parsedRestaurants.filter({$0.name == name}) {
            return rest
        }
        
        // If we haven't returned, there is no restaurant with that name yet. Create one!
        self.parsedRestaurants.append(Restaurant(name: name))
        
        // Recursively return because this is fancy
        return self.getRestaurantFor(name: name)
    }
}
