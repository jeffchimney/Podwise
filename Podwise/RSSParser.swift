//
//  RSSParser.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-17.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation

class RSSParser: NSObject, XMLParserDelegate {
    
    var xmlParser: XMLParser!
    var currentElement = ""
    var foundCharacters = ""
    var currentData = [String: String]()
    var parsedData = [[String:String]]()
    var isHeader = true
    
    let elementArray = ["guid","itunes:author","itunes:subtitle","itunes:summary","itunes:explicit","itunes:duration", "content:encoded", "itunes:image","item", "title", "description", "pubDate", "enclosure", "link"]
    
    func startParsingContentsOfURL(rssURL: URL, with completion: (Bool) -> ()) {
        let xmlParser = XMLParser(contentsOf: rssURL)

        xmlParser?.delegate = self
        if let flag = xmlParser?.parse() {
            parsedData.append(currentData)
            completion(flag)
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        print("\(currentElement): \(currentData)")
        
        if elementArray.contains(currentElement) {
            if !isHeader {
                parsedData.append(currentData)
            }
            isHeader = false
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !isHeader {
            if elementArray.contains(currentElement) {
            foundCharacters += string
            }
        }
        print(foundCharacters)
    }
}
