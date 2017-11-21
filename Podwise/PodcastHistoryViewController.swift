//
//  PodcastHistoryViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-17.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class PodcastHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, XMLParserDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var channelLabel: UILabel!
    var channelDescriptionTextView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var eName: String = String()
    var episodes: [Episode] = []
    var episodeTitle: String = String()
    var episodeDescription = String()
    var imageSet: Bool = false
    
    var feedURL: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        channelDescriptionTextView = UITextView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50))
        activityIndicator.startAnimating()
        print(feedURL)
        
        channelLabel.text! = ""
        channelDescriptionTextView.text! = ""
        
        let urlString: String = feedURL
        let url: URL = URL(string: urlString)!
        
        if let parser = XMLParser(contentsOf: url) {
            parser.delegate = self
            parser.parse()
        }
        print("Looking for: \(url)")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableHeaderView = channelDescriptionTextView
    }
    
    // Table View Delegate Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath as IndexPath)
        
        let episode = episodes[indexPath.row]
        
        cell.textLabel?.text = episode.title
        cell.detailTextLabel?.text = episode.description
        
        return cell
    }
    
    // XMLParser Delegate Methods
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if !imageSet {
            if elementName == "itunes:image" {
                imageSet = true
                let imgLink = attributeDict["href"] as! String
                let urlString: String = imgLink
                let url: URL = URL(string: urlString)!
                let request: URLRequest = URLRequest(url: url)
                let session: URLSession = URLSession.shared
                let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
                    // Download representation of the image as NSData at the URL
                    do {
                        let imageData: Data = try Data.init(contentsOf: url, options: .mappedIfSafe)
                        DispatchQueue.main.async {
                            self.imageView.image = UIImage(data: imageData)
                            self.imageView.layer.cornerRadius = 10
                            self.imageView.layer.masksToBounds = true
                            
                            self.activityIndicator.isHidden = true
                            self.activityIndicator.stopAnimating()
                        }
                    } catch {
                        print("Could not load art thumbnail")
                    }
                })
                print("URL for searching iTunes API \(url)")
                task.resume()
            }
        }
        
        eName = elementName
        if elementName == "item" {
            episodeTitle = String()
            episodeDescription = String()
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            
            let episode = Episode()
            episode.title = episodeTitle
            episode.description = episodeDescription
            
            episodes.append(episode)
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        print(eName)
        if (!data.isEmpty) {
            switch eName {
            case "title":
                if channelLabel.text! == "" {
                    channelLabel.text! = data
                } else {
                    episodeTitle += data
                }
            case "description":
                if channelDescriptionTextView.text! == "" {
                    channelDescriptionTextView.text! = data
                } else {
                    episodeDescription += data
                }
            default:
                break
            }
        } else {
            
        }
    }
}
