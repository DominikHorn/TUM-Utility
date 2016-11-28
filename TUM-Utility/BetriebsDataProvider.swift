//
//  BetriebsPDFHandler.swift
//  TUM-Utility
//
//  Created by Dominik Horn on 13.10.16.
//  Copyright © 2016 Dominik Horn. All rights reserved.
//

import Foundation

class BetriebsDataProvider : RestaurantDataProvider {
    /// URL for betriebsrestaurant page
    private let baseURL = "http://www.betriebsrestaurant-gmbh.de/"
    
    /// URL component for "speiseplaene" site
    private let speiseplanLinkPage = "index.php?id=91"
    
    /// subdirectory within application's documents that pdfs are stored in
    private let betriebsPDFSaveDirectory = Utility.getAppGroupDocumentsDirectory().appendingPathComponent("betriebsrestaurant-gmbh/")
    
    /// Web utility used to download and store the pdfs
    private let webUtility: WebUtility = WebUtility()
    
    /// Callback invoked when we are refreshed
    private var callback: (([Restaurant]?, RestaurantDataProvider) -> ())?
    
    /// Amount of running downloads
    private var runningDownloads: Int
    
    /// Parser used for parsing data
    private var betriebsParser: BetriebsParser
    
    init() {
        self.runningDownloads = 0
        self.betriebsParser = BetriebsParser()
    
        // Create our directory if it's not present
        if !(FileManager.default.fileExists(atPath: betriebsPDFSaveDirectory.path)) {
            do {
                // Create directory
                try FileManager.default.createDirectory(at: betriebsPDFSaveDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Error: Could not create BetriebsPDF directory: \(error)")
                return
            }
        }
    }
    
    func refreshData(completionHandler: @escaping ([Restaurant]?, RestaurantDataProvider) -> ()) {
        // make sure we are only refreshing when definitely needed
        guard self.callback == nil else {
            print("Error: can not refresh BetriebsPDFHandler while it is being refreshed!")
            return
        }
        
        // Reset everything for new refresh
        self.callback = completionHandler
        self.runningDownloads = 0
        
        // Crawl for pdf links
        let pdfURLs = webUtility.crawlForPDFURLs(url: baseURL + speiseplanLinkPage)
        
        // Download all files that are not present locally
        pdfURLs.forEach() { (pdf) in
            do {
                // If no local file with the same name exists
                if try FileManager.default.contentsOfDirectory(atPath: betriebsPDFSaveDirectory.path).filter({ getName(fromPath: $0) == getName(fromPath: pdf) }).count == 0 {
                    asyncDownload(baseURL + pdf) // TODO: implement as blocking download so that we can be sure that we are done downloading at the end of this method. it is automatically parallised by RestaurantManager
                }
            } catch {
                print("Error comparing local to remote pdfs")
                return
            }
        }
        
        // Clear out every pdf that is not available online (prevent unreasonable storage consumption)
        do {
            try FileManager.default.contentsOfDirectory(atPath: betriebsPDFSaveDirectory.path).forEach() {
                (localFile) in
                // If file name doesn't match any pdf name, delete as it must be too old
                if pdfURLs.filter({ getName(fromPath: $0) == getName(fromPath: localFile) }).count == 0 {
                    try FileManager.default.removeItem(at: betriebsPDFSaveDirectory.appendingPathComponent(localFile))
                }
            }
        } catch {
            print("Error: could not remove old files from betriebsProvider's data")
            return
        }
        
        // if we have no running downloads at this point, trigger a content update
        if runningDownloads == 0 {
            finishRefresh()
        }
    }
    
    func clearCache() {
        do {
            try FileManager.default.contentsOfDirectory(atPath: betriebsPDFSaveDirectory.path).forEach() {
                print("Delete cached file \($0)")
                try FileManager.default.removeItem(at: betriebsPDFSaveDirectory.appendingPathComponent($0))
            }
        } catch {
            print("Error clearing cache directory")
        }
    }
    
    private func getName(fromPath path: String) -> String {
        return (URL(string: path)?.lastPathComponent)!
    }
    
    private func finishRefresh() {
        // Callback
        self.callback?(self.betriebsParser.parseFiles(at: betriebsPDFSaveDirectory.path), self)

        // Allow further refreshes
        self.callback = nil
    }
    
    private func asyncDownload(_ pdfLink: String) {
        // Add one more download to the queue
        self.runningDownloads += 1
        
        // Asynchronously trigger pdf download
        DispatchQueue.global(qos: .default).async {
            // Download PDF
            if let url = URL(string: pdfLink) {
                let pdfUrl = self.betriebsPDFSaveDirectory.appendingPathComponent(url.lastPathComponent)
                self.webUtility.download(url: url, to: pdfUrl, completion: self.asyncDownloadFinished)
            }
        }
    }
    
    private func asyncDownloadFinished(url: URL) {
        // TODO: remove
        // Verbose statement for debug
        print("downloaded \(url.lastPathComponent)")
        
        // One download finished
        self.runningDownloads -= 1
        
        // Update our conent when all downloads finished
        if runningDownloads == 0 {
            // Trigger callback
            self.finishRefresh()
        }
    }
}
