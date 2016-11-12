//
//  Utility.swift
//  TUM-Utility
//
//  Created by Dominik Horn on 13.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import Foundation

// Define prefix operator to convert string to regex
prefix operator ^/
prefix func ^/ (pattern:String) throws -> NSRegularExpression {
    return try NSRegularExpression(pattern: pattern, options:
        NSRegularExpression.Options.dotMatchesLineSeparators)
}

precedencegroup constPrecedence {
    associativity: left
    higherThan: AssignmentPrecedence
}

// Define infix operator for regex. This will return true when there are matches
infix operator =~ : constPrecedence
func =~ (string: String, regex: NSRegularExpression) -> Bool {
    return regex.numberOfMatches(in: string, options: [], range: NSMakeRange(0, string.characters.count)) > 0
}

// Define infix operator for regex. This will return the actual matches found
infix operator =~~ : constPrecedence
func =~~ (string: String, regex: NSRegularExpression) -> [NSTextCheckingResult] {
    return regex.matches(in: string, options: [], range: NSMakeRange(0, string.characters.count))
}

// global synchronized function to make up for the lack theirof in swift O.o
func synchronized(_ lock: AnyObject, _ closure: @escaping () -> ()) {
    // lock using object
    objc_sync_enter(lock)
    
    // Execute closure
    closure()
    
    // Make sure this is executed no matter what
    defer { objc_sync_exit(lock) }
}

class Utility: NSObject {
    // TODO: lookup naming convention
    static let REGEX_NUMBEREDLIST = "^(\\d+)\\."
    static let REGEX_LINEENDSWITHPRICE = "\\s([0-9]+)\\.[0-9][0-9]"
    
    class func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    class func getAppGroupDocumentsDirectory() -> URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.tum")!
    }
    
    class func lineIsPartOfNumberedList(string: String) -> Bool {
        return try! string =~ ^/REGEX_NUMBEREDLIST
    }
    
    class func lineEndsWithPrice(line: String) -> Bool {
        return try! line =~ ^/REGEX_LINEENDSWITHPRICE
    }
    
    /// Checks whether the date exists and is within today
    class func isDateInToday(date: Date?) -> Bool {
        guard let date = date else {
            return false
        }
        
        // Return whether date is today or not
        return Calendar.autoupdatingCurrent.isDateInToday(date)
    }
    
    //// TODO: find better way for everything bellow
    
    private class func min(numbers: Int...) -> Int {
        return numbers.reduce(numbers[0], {$0 < $1 ? $0 : $1})
    }
    
    class Array2D {
        var cols:Int, rows:Int
        var matrix: [Int]
        
        
        init(cols:Int, rows:Int) {
            self.cols = cols
            self.rows = rows
            matrix = Array(repeating:0, count:cols*rows)
        }
        
        subscript(col:Int, row:Int) -> Int {
            get {
                return matrix[cols * row + col]
            }
            set {
                matrix[cols*row+col] = newValue
            }
        }
        
        func colCount() -> Int {
            return self.cols
        }
        
        func rowCount() -> Int {
            return self.rows
        }
    }
    
    class func levenshtein(aStr: String, bStr: String) -> Int {
        let a = Array(aStr.utf16)
        let b = Array(bStr.utf16)
        
        let dist = Array2D(cols: a.count + 1, rows: b.count + 1)
        
        for i in 1...a.count {
            dist[i, 0] = i
        }
        
        for j in 1...b.count {
            dist[0, j] = j
        }
        
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i-1] == b[j-1] {
                    dist[i, j] = dist[i-1, j-1]  // noop
                } else {
                    dist[i, j] = min(
                        numbers: dist[i-1, j] + 1,  // deletion
                        dist[i, j-1] + 1,  // insertion
                        dist[i-1, j-1] + 1  // substitution
                    )
                }
            }
        }
        
        return dist[a.count, b.count]
    }
}
