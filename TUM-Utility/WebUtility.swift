//
//  Webutility.swift
//  TUM-Utility
//
//  Created by Dominik Horn on 11.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import Foundation
import UIKit

class WebUtility : NSObject {
    func download(url: URL, to localUrl: URL, completion: @escaping (URL) -> ()) {
//        // Enable network indicator
//        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        // Configure session
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url)
        
        // Setup download task
        let task = session.downloadTask(with: request) { (location, response, error) in
            if let location = location, error == nil {
                do {
                    try FileManager.default.copyItem(at: location, to: localUrl)
                    completion(localUrl)
                } catch (let writeError) {
                    print("Error writing file \(localUrl.relativePath) :\n\n: \(writeError)")
                }
                
            } else {
                print("Failure: %@", error?.localizedDescription ?? "Da isch wat janz, janz schlimm kaputt!");
            }
            
//            // Disable networking indicator again
//            DispatchQueue.main.async() {
//                UIApplication.shared.isNetworkActivityIndicatorVisible = false
//            }
        }
        task.resume()
    }
    
    func crawlForPDFURLs(url: String) -> [String] {
//        // Enable network indicator
//        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        var array: [String] = [String]()
        
        // Craft url object from string url
        guard let mensaLinksURL = URL(string: url) else {
            print("Error: \(url) doesn't seem to be a valid URL")
            return array
        }
        
        do {
            // download html from url
            let mensaHTMLString = try String(contentsOf: mensaLinksURL, encoding: .ascii)
            
            // Extract all links
            let linkMatches = matches(for: "href=\"([^\"]*)\"", in: mensaHTMLString)
            
            for match in linkMatches {
                if match.contains(".pdf") {
                    let start = match.index(match.startIndex, offsetBy: 6)
                    let end = match.index(match.endIndex, offsetBy: -1)
                    array.append(match[start..<end])
                }
            }
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
        
//        // Disable networking indicator again
//        DispatchQueue.main.async() {
//            UIApplication.shared.isNetworkActivityIndicatorVisible = false
//        }
        
        return array
    }
    
    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("Invalid Regex: \(error.localizedDescription)")
            return []
        }
    }
}
