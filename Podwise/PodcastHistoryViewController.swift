//
//  PodcastHistoryViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-17.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import AVFoundation

class PodcastHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, XMLParserDelegate {
    
    var managedContext: NSManagedObjectContext?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var channelLabel: UILabel!
    var channelDescriptionTextView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var subscribeButton: UIButton!
    var subscribeButtonSet: Bool = false
    
    var eName: String = String()
    var episodes: [Episode] = []
    var episodeTitle: String = String()
    var episodeDescription = String()
    var episodeDuration = String()
    var episodeURL: URL!
    var imageSet: Bool = false
    var feedURL: String!
    var url: URL!
    var collectionID: Int!
    var authorName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        channelDescriptionTextView = UITextView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100))
        activityIndicator.startAnimating()
        
        channelLabel.text! = ""
        channelDescriptionTextView.text! = ""
        channelDescriptionTextView.font = UIFont(name: "Helvetica", size: 15)
        
        let urlString: String = feedURL
        url = URL(string: urlString)!
        
        if let parser = XMLParser(contentsOf: url) {
            parser.delegate = self
            parser.parse()
        }
        print("Looking for: \(url)")
        
        subscribeButton.layer.cornerRadius = 15
        subscribeButton.layer.masksToBounds = true
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath as IndexPath) as! EpisodeCell
        
        let episode = episodes[indexPath.row]
        var hours = 0
        var minutes = 0
        if let optionalHours = Int(episode.itunesDuration) {
            hours = (optionalHours/60)/60
        }
        if let optionalMinutes = Int(episode.itunesDuration) {
            minutes = (optionalMinutes/60)%60
        }
        
        cell.titleLabel.text = episode.title
        cell.descriptionLabel.text = episode.itunesSubtitle
        if hours == 0 && minutes == 0 {
            cell.durationLabel.text = ""
        } else if hours == 0 {
            cell.durationLabel.text = "\(minutes)m"
        } else {
            cell.durationLabel.text = "\(hours)h \(minutes)m"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = episodes[indexPath.row]
        downloadFile(at: episode.audioUrl, relatedTo: episode, playNow: true)
    }
    
    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let closeAction = UIContextualAction(style: .normal, title:  "Close", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("OK, marked as Closed")
            success(true)
        })
        closeAction.image = UIImage(named: "tick")
        closeAction.backgroundColor = .purple
        
        return UISwipeActionsConfiguration(actions: [closeAction])
        
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let downloadAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Downloading...")
            self.downloadFile(at: self.episodes[indexPath.row].audioUrl, relatedTo: self.episodes[indexPath.row], playNow: false)
            success(true)
        })
        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Update action ...")
            success(true)
        })
        downloadAction.image = UIImage(named: "downloadIcon")
        downloadAction.backgroundColor = UIColor(displayP3Red: 69/255.0, green: 152/255.0, blue: 152/255.0, alpha: 1.0)
        
        addToPlaylistAction.image = UIImage(named: "playlist")
        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
        
        return UISwipeActionsConfiguration(actions: [downloadAction, addToPlaylistAction])
    }
    
    // XMLParser Delegate Methods
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if !imageSet {
            if elementName == "itunes:image" {
                imageSet = true
                let imgLink = attributeDict["href"]
                let urlString: String = imgLink!
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
        
        if elementName == "enclosure" {
            let audioURL = attributeDict["url"]
            let urlString: String = audioURL!
            let url: URL = URL(string: urlString)!
            print("URL for podcast download: \(url)")
            episodeURL = url
        }
        
        eName = elementName
        if elementName == "item" {
            episodeTitle = String()
            episodeDescription = String()
            episodeDuration = String()
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            
            let episode = Episode()
            episode.title = episodeTitle
            episode.itunesSubtitle = episodeDescription
            episode.itunesDuration = episodeDuration
            episode.audioUrl = episodeURL
            print(collectionID)
            episodes.append(episode)
            if !subscribeButtonSet {
                subscribeButtonSet = true
                let podcast = CoreDataHelper.getPodcastWith(id: collectionID!, in: managedContext!)
                if podcast.count > 0 {
                    if podcast[0].subscribed {
                        subscribeButton.setTitle("  Unubscribe  ", for: .normal)
                        subscribeButton.backgroundColor = .red
                    } else {
                        subscribeButton.setTitle("  Subscribe  ", for: .normal)
                        subscribeButton.backgroundColor = .green
                    }
                } else {
                    subscribeButton.setTitle("  Subscribe  ", for: .normal)
                    subscribeButton.backgroundColor = .green
                }
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)

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
            case "itunes:duration":
                episodeDuration = data
            default:
                break
            }
        } else {
            
        }
    }
    
    func downloadFile(at: URL, relatedTo: Episode, playNow: Bool) {
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(at.lastPathComponent)
        relatedTo.localURL = destinationUrl
        print(destinationUrl)
        
        // to check if it exists before downloading it
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            print("The file already exists at path")
            if playNow {
                self.playDownload(at: destinationUrl)
            }
            // if the file doesn't exist
        } else {
            let podcastsWithId = CoreDataHelper.getPodcastWith(id: collectionID!, in: managedContext!)
            var podcast: CDPodcast!
            let episodeEntity = NSEntityDescription.entity(forEntityName: "CDEpisode", in: managedContext!)!
            let episode = NSManagedObject(entity: episodeEntity, insertInto: managedContext) as! CDEpisode
            if podcastsWithId.count > 0 { // episode belongs to retrieved podcast
                episode.title = relatedTo.title
                episode.subTitle = relatedTo.itunesSubtitle
                episode.audioURL = relatedTo.audioUrl
                episode.localURL = relatedTo.localURL
                episode.duration = relatedTo.itunesDuration
                episode.podcast = podcastsWithId[0]
            } else { // episode doesn't belong to a previously downloaded or subscribed podcast, create new one
                let podcastEntity = NSEntityDescription.entity(forEntityName: "CDPodcast", in: managedContext!)!
                podcast = NSManagedObject(entity: podcastEntity, insertInto: managedContext) as! CDPodcast
                podcast.title = channelLabel.text!
                podcast.subTitle = channelDescriptionTextView.text!
                podcast.image = UIImagePNGRepresentation(imageView.image!)
                podcast.subscribed = false // not subscribed or it would have found the podcast in coredata
                podcast.author = authorName!
                podcast.feedURL = url
                podcast.id = Int64(collectionID)
                
                episode.title = relatedTo.title
                episode.subTitle = relatedTo.itunesSubtitle
                episode.audioURL = relatedTo.audioUrl
                episode.localURL = relatedTo.localURL
                episode.duration = relatedTo.itunesDuration
                episode.podcast = podcast
            }
            
            CoreDataHelper.save(context: managedContext!)
            if downloads == nil {
                downloads = []
            }
            downloads.append(episode)
            
            // you can use NSURLSession.sharedSession to download the data asynchronously
            URLSession.shared.downloadTask(with: at, completionHandler: { (location, response, error) -> Void in
                guard let location = location, error == nil else { return }
                do {
                    // after downloading your file you need to move it to your destination url
                    try FileManager.default.moveItem(at: location, to: destinationUrl)
                    print("File moved to documents folder")
                    if playNow {
                        self.playDownload(at: destinationUrl)
                    }
                    if downloads.contains(episode) {
                        if let episodeIndex = downloads.index(of: episode) {
                            downloads.remove(at: episodeIndex)
                        }
                    }
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }).resume()
        }
    }
    
    func playDownload(at: URL) {
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(at.lastPathComponent)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: destinationUrl)
            guard let player = audioPlayer else { return }
            
            player.prepareToPlay()
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func subscribeButtonPressed(_ sender: Any) {
        if subscribeButton.titleLabel?.text == "  Subscribe  " {
            subscribeButton.setTitle("  Unubscribe  ", for: .normal)
            subscribeButton.backgroundColor = .red
            let podcast = CoreDataHelper.getPodcastWith(id: collectionID!, in: managedContext!)
            if podcast.count > 0 {
                podcast[0].subscribed = true
                CoreDataHelper.save(context: managedContext!)
            } else {
                let podcastEntity = NSEntityDescription.entity(forEntityName: "CDPodcast", in: managedContext!)!
                let podcast = NSManagedObject(entity: podcastEntity, insertInto: managedContext) as! CDPodcast
                podcast.title = channelLabel.text!
                podcast.subTitle = channelDescriptionTextView.text!
                podcast.image = UIImagePNGRepresentation(imageView.image!)
                podcast.subscribed = true // not subscribed or it would have found the podcast in coredata
                podcast.author = authorName
                podcast.feedURL = url
                podcast.id = Int64(collectionID)
                CoreDataHelper.save(context: managedContext!)
            }
        } else {
            subscribeButton.setTitle("  Subscribe  ", for: .normal)
            subscribeButton.backgroundColor = .green
            let podcast = CoreDataHelper.getPodcastWith(id: collectionID!, in: managedContext!)
            if podcast.count > 0 {
                podcast[0].subscribed = false
                CoreDataHelper.save(context: managedContext!)
            } else {
                let podcastEntity = NSEntityDescription.entity(forEntityName: "CDPodcast", in: managedContext!)!
                let podcast = NSManagedObject(entity: podcastEntity, insertInto: managedContext) as! CDPodcast
                podcast.title = channelLabel.text!
                podcast.subTitle = channelDescriptionTextView.text!
                podcast.image = UIImagePNGRepresentation(imageView.image!)
                podcast.subscribed = false // not subscribed or it would have found the podcast in coredata
                podcast.author = authorName
                podcast.feedURL = url
                podcast.id = Int64(collectionID)
                CoreDataHelper.save(context: managedContext!)
            }
        }
    }
}
