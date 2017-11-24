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

class EpisodesForPodcastViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, XMLParserDelegate {
    
    var managedContext: NSManagedObjectContext?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var channelLabel: UILabel!
    var channelDescriptionTextView: UITextView!
    @IBOutlet weak var subscribeButton: UIButton!
    var subscribeButtonSet: Bool = false
    
    var podcast: CDPodcast!
    var eName: String = String()
    var downloadedEpisodes: [CDEpisode] = []
    var unDownloadedEpisodes: [Episode] = []
    var episodeTitle: String = String()
    var episodeDescription = String()
    var episodeDuration = String()
    var episodeURL: URL!
    var imageSet: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        downloadedEpisodes = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
        
        channelLabel.text! = ""
        
        if let parser = XMLParser(contentsOf: podcast.feedURL!) {
            parser.delegate = self
            parser.parse()
        }
        print("Looking for: \(podcast.feedURL!)")
        
        subscribeButton.layer.cornerRadius = 15
        subscribeButton.layer.masksToBounds = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableHeaderView = channelDescriptionTextView
        imageView.image = UIImage(data: podcast.image!)
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        
        if podcast.subscribed {
            subscribeButton.setTitle("  Unubscribe  ", for: .normal)
            subscribeButton.backgroundColor = .red
        } else {
            subscribeButton.setTitle("  Subscribe  ", for: .normal)
            subscribeButton.backgroundColor = .green
        }
    }
    
    // Table View Delegate Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadedEpisodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath as IndexPath) as! EpisodeCell
        
        let episode = downloadedEpisodes[indexPath.row]
        var hours = 0
        var minutes = 0
        if let optionalHours = Int(episode.duration!) {
            hours = (optionalHours/60)/60
        }
        if let optionalMinutes = Int(episode.duration!) {
            minutes = (optionalMinutes/60)%60
        }
        
        cell.titleLabel.text = episode.title
        cell.descriptionLabel.text = episode.subTitle

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
        let episode = downloadedEpisodes[indexPath.row]
        startAudioSession()
        playDownload(at: episode.localURL!)
        nowPlayingArt = UIImage(data: (self.podcast.image)!)
        baseViewController.miniPlayerView.artImageView.image = nowPlayingArt
        //downloadFile(at: episode.audioURL!, relatedTo: episode, playNow: true)
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
//        let downloadAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
//            print("Downloading...")
//            self.downloadFile(at: self.episodes[indexPath.row].audioUrl, relatedTo: self.episodes[indexPath.row], playNow: false)
//            success(true)
//        })
        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Update action ...")
            success(true)
        })
//        downloadAction.image = UIImage(named: "downloadIcon")
//        downloadAction.backgroundColor = UIColor(displayP3Red: 69/255.0, green: 152/255.0, blue: 152/255.0, alpha: 1.0)
        
        addToPlaylistAction.image = UIImage(named: "playlist")
        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
        
        return UISwipeActionsConfiguration(actions: [addToPlaylistAction])
    }
    
    // XMLParser Delegate Methods
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
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

            unDownloadedEpisodes.append(episode)
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
                startAudioSession()
                self.playDownload(at: destinationUrl)
                nowPlayingArt = UIImage(data: (self.podcast.image)!)
                baseViewController.miniPlayerView.artImageView.image = nowPlayingArt
            }
            // if the file doesn't exist
        } else {
            let episodeEntity = NSEntityDescription.entity(forEntityName: "CDEpisode", in: managedContext!)!
            let episode = NSManagedObject(entity: episodeEntity, insertInto: managedContext) as! CDEpisode

            episode.title = relatedTo.title
            episode.subTitle = relatedTo.itunesSubtitle
            episode.audioURL = relatedTo.audioUrl
            episode.localURL = relatedTo.localURL
            episode.duration = relatedTo.itunesDuration
            episode.podcast = podcast

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
                        self.startAudioSession()
                        self.playDownload(at: destinationUrl)
                        nowPlayingArt = UIImage(data: (self.podcast.image)!)
                        baseViewController.miniPlayerView.artImageView.image = nowPlayingArt
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
            
            baseViewController.miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            baseViewController.showMiniPlayer(animated: true)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func subscribeButtonPressed(_ sender: Any) {
        if podcast.subscribed {
            podcast.subscribed = false
            subscribeButton.setTitle("  Subscribe  ", for: .normal)
            subscribeButton.backgroundColor = .green
            CoreDataHelper.save(context: managedContext!)
        } else {
            podcast.subscribed = true
            subscribeButton.setTitle("  Unubscribe  ", for: .normal)
            subscribeButton.backgroundColor = .red
            CoreDataHelper.save(context: managedContext!)
        }
    }
    
    func startAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .interruptSpokenAudioAndMixWithOthers)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
}

