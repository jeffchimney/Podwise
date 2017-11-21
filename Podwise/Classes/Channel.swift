//
//  Channel.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-20.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation

class Channel {
    var title: String = String()
    var link: String = String()
    var pubDate: String = String()
    var description: String = String()
    var language: String = String()
    var copyright: String = String()
    var itunesAuthor: String = String()
    var itunesKeywords: String = String()
    var itunesExplicit: String = String()
    var itunesImageURL: String = String()
    var itunesCategory: String = String()
    var episodes: [Episode] = []
}
