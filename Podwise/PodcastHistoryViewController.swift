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
import MediaPlayer

class PodcastHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, XMLParserDelegate, UISearchBarDelegate, URLSessionDownloadDelegate {
    
    //weak var managedContext: NSManagedObjectContext?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var channelLabel: UILabel!
    var channelDescriptionTextView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var subscribeButton: UIButton!
    var subscribeButtonSet: Bool = false
    var searchBar:UISearchBar = UISearchBar(frame: CGRect(x: 0,y: 0,width: 200,height: 20))
    
    var eName: String = String()
    var episodes: [Episode] = []
    var filteredEpisodes: [Episode] = []
    var episodeID: String = String()
    var episodeTitle: String = String()
    var episodeDescription = String()
    var episodeDuration = String()
    var episodeShowNotes = String()
    var episodeURL: URL!
    var imageSet: Bool = false
    var feedURL: String!
    var url: String!
    var collectionID: Int!
    var authorName: String!
    var searchActive: Bool = false
    var lastTitle = ""
    var thisTitle = ""
    
    var downloadTask: URLSessionDownloadTask!
    var backgroundSession: URLSession!
    
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
        
        searchBar.searchBarStyle = .minimal
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        let searchBarButtonItem = UIBarButtonItem(customView: searchBar)
        navigationItem.rightBarButtonItem = searchBarButtonItem
        
        url = feedURL
        let rssURL = URL(string: url)!
        
        if let parser = XMLParser(contentsOf: rssURL) {
            parser.delegate = self
            parser.parse()
        }
        print("Looking for: \(url)")
        
        subscribeButton.layer.cornerRadius = 15
        subscribeButton.layer.masksToBounds = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableHeaderView = channelDescriptionTextView
        
        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
        backgroundSession = Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tableView.reloadData()
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
        
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(episode.audioUrl.lastPathComponent)
        
        // to check if it exists
        if !FileManager.default.fileExists(atPath: destinationUrl.path) {
            // File doesn't exist in data, make fonts grey
            cell.titleLabel.textColor = .lightGray
            cell.descriptionLabel.textColor = .lightGray
            cell.durationLabel.textColor = .lightGray
            episode.downloaded = false
        } else {
            cell.titleLabel.textColor = .black
            cell.descriptionLabel.textColor = .black
            cell.durationLabel.textColor = .black
            episode.downloaded = true
        }

        cell.downloadProgressView.alpha = 0.3
        cell.downloadProgressView.transform = cell.downloadProgressView.transform.scaledBy(x: 1, y: cell.frame.height/2)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let episode = episodes[indexPath.row]
        var hours = 0
        var minutes = 0
        if let optionalHours = Int(episode.itunesDuration) {
            hours = (optionalHours/60)/60
        }  else {
            let durationArray = episode.itunesDuration.split(separator: ":")
            if durationArray.count > 0 {
                if let optionalHours = Int(durationArray[0]) {
                    hours = optionalHours
                }
            }
        }
        if let optionalMinutes = Int(episode.itunesDuration) {
            minutes = (optionalMinutes/60)%60
        }  else {
            let durationArray = episode.itunesDuration.split(separator: ":")
            if durationArray.count > 1 {
                if let optionalMinutes = Int(durationArray[1]) {
                    minutes = optionalMinutes
                }
            }
        }
        
        (cell as! EpisodeCell).titleLabel.text = episode.title
        (cell as! EpisodeCell).descriptionLabel.text = episode.itunesSubtitle
        if hours == 0 && minutes == 0 {
            (cell as! EpisodeCell).durationLabel.text = ""
        } else if hours == 0 {
            (cell as! EpisodeCell).durationLabel.text = "\(minutes)m"
        } else {
            (cell as! EpisodeCell).durationLabel.text = "\(hours)h \(minutes)m"
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = episodes[indexPath.row]
        
        downloadFile(at: episode.audioUrl, relatedTo: episode, addTo: nil, playNow: true, cellIndexPath: indexPath)
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
            self.downloadFile(at: self.episodes[indexPath.row].audioUrl, relatedTo: self.episodes[indexPath.row], addTo: nil, playNow: false, cellIndexPath: indexPath)
            success(true)
        })
        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Adding to playlist...")
            let alert = UIAlertController(title: "Add To Playlist", message: "", preferredStyle: .actionSheet)
            
            let playlists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
            
            for eachPlaylist in playlists {
                alert.addAction(UIAlertAction(title: eachPlaylist.name, style: .default, handler: { (action) in
                    //execute some code when this option is selected
                    self.downloadFile(at: self.episodes[indexPath.row].audioUrl, relatedTo: self.episodes[indexPath.row], addTo: eachPlaylist, playNow: false, cellIndexPath: indexPath)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            
            success(true)
        })
        let deleteEpisodeAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Delete action ...")
            let cdEpisode = CoreDataHelper.getEpisodeWith(id: self.episodes[indexPath.row].id, in: managedContext!)
            if cdEpisode.count > 0 {
                do {
                    let filemanager = FileManager.default
                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
                    let destinationPath = documentsPath.appendingPathComponent(cdEpisode[0].localURL!.lastPathComponent)
                    if filemanager.fileExists(atPath: destinationPath) {
                        try! filemanager.removeItem(atPath: destinationPath)
                    } else {
                        print("not deleted, couldnt find file.")
                    }
                    CoreDataHelper.delete(episode: cdEpisode[0], in: managedContext!)
                }
            }
            
            let cell = tableView.cellForRow(at: indexPath) as! EpisodeCell
            cell.titleLabel.textColor = .lightGray
            cell.descriptionLabel.textColor = .lightGray
            cell.durationLabel.textColor = .lightGray
            self.episodes[indexPath.row].downloaded = false
            success(true)
        })
        
        if !episodes[indexPath.row].downloaded{
            downloadAction.image = UIImage(named: "downloadIcon")
            downloadAction.backgroundColor = UIColor(displayP3Red: 69/255.0, green: 152/255.0, blue: 152/255.0, alpha: 1.0)
            
            addToPlaylistAction.image = UIImage(named: "playlist")
            addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
            return UISwipeActionsConfiguration(actions: [downloadAction, addToPlaylistAction])
        } else {
            deleteEpisodeAction.image = UIImage(named: "trash")
            deleteEpisodeAction.backgroundColor = .red
            
            addToPlaylistAction.image = UIImage(named: "playlist")
            addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
            return UISwipeActionsConfiguration(actions: [deleteEpisodeAction, addToPlaylistAction])
        }
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
                            self.setSubscribeButton()
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
            episodeID = String()
            episodeTitle = String()
            episodeDescription = String()
            episodeDuration = String()
            episodeShowNotes = String()
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            
            let episode = Episode()
            episode.id = episodeID
            episode.title = episodeTitle
            episode.itunesSubtitle = episodeDescription
            episode.itunesDuration = episodeDuration
            episode.audioUrl = episodeURL
            print(episodeShowNotes)
            if episodeShowNotes != "" {
                episode.contentEncoded = episodeShowNotes
            } else {
                episode.contentEncoded = episodeDescription
            }
            print(collectionID)
            episodes.append(episode)
            if !subscribeButtonSet {
                subscribeButtonSet = true
                setSubscribeButton()
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
                    lastTitle = thisTitle
                    thisTitle = episodeTitle
                }
            case "description":
                if thisTitle == "" { //channelDescriptionTextView.text! == ""
                    channelDescriptionTextView.text! += data
                }
            case "itunes:subtitle":
                if lastTitle == thisTitle || lastTitle == "" {
                    episodeDescription += data
                } else {
                    episodeDescription = data
                }
            case "guid":
                episodeID = data
            case "itunes:duration":
                episodeDuration = data
            case "content:encoded":
                if lastTitle == thisTitle || lastTitle == "" {
                    episodeShowNotes += data
                } else {
                    episodeShowNotes = data
                }
                
            default:
                break
            }
        } else {
            
        }
    }
    
    func setSubscribeButton() {
        if activityIndicator.isAnimating {
            let podcast = CoreDataHelper.getPodcastWith(id: collectionID!, in: managedContext!)
            if podcast.count > 0 {
                if podcast[0].subscribed {
                    subscribeButton.setTitle("  Unubscribe  ", for: .normal)
                    subscribeButton.backgroundColor = .gray
                } else {
                    subscribeButton.setTitle("  Subscribe  ", for: .normal)
                    subscribeButton.backgroundColor = .gray
                }
            } else {
                subscribeButton.setTitle("  Subscribe  ", for: .normal)
                subscribeButton.backgroundColor = .gray
            }
            subscribeButton.isEnabled = false
        } else {
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
            
            subscribeButton.isEnabled = true
        }
    }
    
    func downloadFile(at: URL, relatedTo: Episode, addTo: CDPlaylist?, playNow: Bool, cellIndexPath: IndexPath?) {
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(at.lastPathComponent)
        relatedTo.localURL = destinationUrl
        print(destinationUrl)
        
        let unSortedPlaylists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
        var unSortedPlaylist: CDPlaylist!
        for playlist in unSortedPlaylists {
            if playlist.id == "unsorted123" {
                unSortedPlaylist = playlist
            }
        }
        if unSortedPlaylist == nil {
            let playlistEntity = NSEntityDescription.entity(forEntityName: "CDPlaylist", in: managedContext!)!
            let playlistObject = NSManagedObject(entity: playlistEntity, insertInto: managedContext) as! CDPlaylist
            
            playlistObject.id = "unsorted123"
            playlistObject.name = "Unsorted"
            playlistObject.sortIndex = 0
            
            let colourData = NSKeyedArchiver.archivedData(withRootObject: UIColor(displayP3Red: 142/255, green: 142/255, blue: 147/255, alpha: 1.0))
            
            playlistObject.colour = colourData
            unSortedPlaylist = playlistObject
        }
        
        var podcast: CDPodcast!
        // to check if it exists before downloading it
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            print("The file already exists at path")
            if playNow {
                startAudioSession()
                let episodesToPlay = CoreDataHelper.getEpisodeWith(id: relatedTo.id, in: managedContext!)
                if episodesToPlay.count > 0 {
                    let episodeToPlay = episodesToPlay[0]
                    
                    let podcastImage = UIImage(data: episodeToPlay.podcast!.image!)
                    baseViewController.miniPlayerView.artImageView.image = podcastImage
                    
                    let backgroundColor = baseViewController.getAverageColorOf(image: (podcastImage?.cgImage!)!)
                    baseViewController.sliderView.minimumTrackTintColor = backgroundColor
                    self.playDownload(for: episodeToPlay)
                    nowPlayingEpisode = episodeToPlay
                }
            } else { // add to playlist
                let episodeWithID = CoreDataHelper.getEpisodeWith(id: relatedTo.id, in: managedContext!)
                if let playlistToAddTo = addTo {
                    if episodeWithID.count > 0 {
                        add(episode: episodeWithID[0], to: playlistToAddTo)
                    }
                }
            }
            // if the file doesn't exist
        } else {
            let podcastsWithId = CoreDataHelper.getPodcastWith(id: collectionID!, in: managedContext!)
            let episodeEntity = NSEntityDescription.entity(forEntityName: "CDEpisode", in: managedContext!)!
            let episode = NSManagedObject(entity: episodeEntity, insertInto: managedContext) as! CDEpisode
            if podcastsWithId.count > 0 { // episode belongs to retrieved podcast
                episode.id = relatedTo.id
                episode.title = relatedTo.title
                episode.subTitle = relatedTo.itunesSubtitle
                episode.audioURL = relatedTo.audioUrl
                episode.localURL = relatedTo.localURL
                episode.duration = relatedTo.itunesDuration
                episode.showNotes = relatedTo.contentEncoded
                episode.podcast = podcastsWithId[0]
                podcast = podcastsWithId[0]
                episode.progress = 0
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
                
                let backgroundColor = baseViewController.getAverageColorOf(image: (imageView.image?.cgImage)!)
                let backgroundCIColor = backgroundColor.coreImageColor
                podcast.backgroundR = Float(backgroundCIColor.components[0])
                podcast.backgroundG = Float(backgroundCIColor.components[1])
                podcast.backgroundB = Float(backgroundCIColor.components[2])
                
                episode.id = relatedTo.id
                episode.title = relatedTo.title
                episode.subTitle = relatedTo.itunesSubtitle
                episode.audioURL = relatedTo.audioUrl
                episode.localURL = relatedTo.localURL
                episode.duration = relatedTo.itunesDuration
                episode.showNotes = relatedTo.contentEncoded
                episode.podcast = podcast
                episode.progress = 0
            }
            
            CoreDataHelper.save(context: managedContext!)
            if downloads == nil {
                downloads = []
            }
            
            let thisDownload = Download(url: destinationUrl, audioUrl: relatedTo.audioUrl, episode: episode, parsedEpisode: relatedTo, playNow: playNow, indexPath: cellIndexPath!, addTo: addTo ?? unSortedPlaylist)

            if downloads.isEmpty {
                thisDownload.setIsDownloading()
                downloads.append(thisDownload)
                downloadTask = backgroundSession.downloadTask(with: at)
                downloadTask.resume()
            } else {
                if downloads[0].isDownloading {
                    downloads.append(thisDownload)
                } else {
                    downloads[0].setIsDownloading()
                    downloadTask = backgroundSession.downloadTask(with: downloads[0].audioUrl)
                    downloadTask.resume()
                }
            }
            
            if let playlistToAddTo = addTo {
                print(playlistToAddTo.name!)
                add(episode: episode, to: playlistToAddTo)
            }
            
            if podcast != nil {
                if podcast.playlist == nil {
                    add(podcast: podcast, to: unSortedPlaylist)
                }
            }
        }
    }
    
    func playDownload(for episode: CDEpisode) {
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(episode.localURL!.lastPathComponent)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: destinationUrl)
            guard let player = audioPlayer else { return }
            player.delegate = baseViewController
            player.currentTime = TimeInterval(episode.progress)
            player.prepareToPlay()
            player.play()
            autoPlay = false
            playlistQueue = []
            
            let artworkImage = UIImage(data: episode.podcast!.image!)
            let artwork = MPMediaItemArtwork.init(boundsSize: artworkImage!.size, requestHandler: { (size) -> UIImage in
                return artworkImage!
            })
            
            let mpic = MPNowPlayingInfoCenter.default()
            mpic.nowPlayingInfo = [MPMediaItemPropertyTitle:episode.title!, MPMediaItemPropertyArtist:episode.podcast!.title!, MPMediaItemPropertyArtwork: artwork]
            
            DispatchQueue.main.async {
                baseViewController.miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
                baseViewController.showMiniPlayer(animated: true)
            }
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
                podcast.subscribed = true
                podcast.author = authorName
                podcast.feedURL = url
                podcast.id = Int64(collectionID)
                
                let backgroundColor = baseViewController.getAverageColorOf(image: (imageView.image?.cgImage)!)
                let backgroundCIColor = backgroundColor.coreImageColor
                podcast.backgroundR = Float(backgroundCIColor.components[0])
                podcast.backgroundG = Float(backgroundCIColor.components[1])
                podcast.backgroundB = Float(backgroundCIColor.components[2])
                CoreDataHelper.save(context: managedContext!)
            }
            if episodes.count > 0 {
                downloadFile(at: episodes[0].audioUrl, relatedTo: episodes[0], addTo: nil, playNow: false, cellIndexPath: IndexPath(row: 0, section: 0))
            }
            CloudKitDataHelper.subscribeToPodcastWith(title: channelLabel.text!, rssFeed: url)
        } else {
            
            subscribeButton.setTitle("  Subscribe  ", for: .normal)
            subscribeButton.backgroundColor = .green
            let podcast = CoreDataHelper.getPodcastWith(id: collectionID!, in: managedContext!)
            if podcast.count > 0 {
                podcast[0].subscribed = false
                CoreDataHelper.save(context: managedContext!)
                AzureDBDataHelper.handle(subscribe: false, to: podcast[0])
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
                
                let backgroundColor = baseViewController.getAverageColorOf(image: (imageView.image?.cgImage)!)
                let backgroundCIColor = backgroundColor.coreImageColor
                podcast.backgroundR = Float(backgroundCIColor.components[0])
                podcast.backgroundG = Float(backgroundCIColor.components[1])
                podcast.backgroundB = Float(backgroundCIColor.components[2])
                CoreDataHelper.save(context: managedContext!)
                AzureDBDataHelper.handle(subscribe: false, to: podcast)
            }
            CloudKitDataHelper.unsubscribeFromPodcastWith(title: channelLabel.text!, rssFeed: url)
        }
    }
    
    func add(podcast: CDPodcast, to playlist: CDPlaylist) {
        podcast.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
    
    func add(episode: CDEpisode, to playlist: CDPlaylist) {
        episode.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
    
    func startAudioSession() {
        // set up background audio capabilities
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)//, with: .interruptSpokenAudioAndMixWithOthers
            print("AVAudioSession Category Playback OK")
            do {
                try audioSession.setActive(true)
                print("AVAudioSession is Active")
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
    
    // Search Bar Methods
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: Search bar delegate functions
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredEpisodes = []
        for episode in episodes {
            if episode.title.lowercased().contains(searchText.lowercased()) {
                filteredEpisodes.append(episode)
            }
        }
        
        if (searchText == "") {
            searchActive = false;
        } else {
            searchActive = true;
        }
        //tableView.reloadData()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if downloads.count > 0 {
            if tableView.cellForRow(at: downloads[0].indexPath!) != nil {
                let cell = tableView.cellForRow(at: downloads[0].indexPath!) as! EpisodeCell
                let progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
                print("downloaded \(progress)%")
                downloads[0].setPercentDown(to: progress)
                DispatchQueue.main.async {
                    cell.downloadProgressView.setProgress(progress, animated: true)
                    //self.tableView.reloadRows(at: [downloads[0].indexPath!], with: .none)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("completed: error: \(String(describing: error))")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            // after downloading your file you need to move it to your destination url
            if downloads != nil {
                try FileManager.default.moveItem(at: location, to: downloads[0].url)
                print("File moved to documents folder")
                
                if downloads[0].playNow {
                    self.startAudioSession()
                    nowPlayingEpisode = downloads[0].episode
                    let nowPlayingArt = UIImage(data: downloads[0].episode.podcast!.image!)
                    baseViewController.miniPlayerView.artImageView.image = nowPlayingArt

                    let backgroundColor = baseViewController.getAverageColorOf(image: nowPlayingArt!.cgImage!)
                    baseViewController.sliderView.minimumTrackTintColor = backgroundColor
                    
                    if nowPlayingEpisode != nil {
                        nowPlayingEpisode.progress = Int64(audioPlayer.currentTime)
                    }
                    
                    CoreDataHelper.save(context: managedContext!)
                    
                    self.playDownload(for: downloads[0].episode)
                }
                
                if let indexPath = downloads[0].indexPath {
                    DispatchQueue.main.async {
                        if self.tableView.cellForRow(at: indexPath) != nil {
                            let cell = self.tableView.cellForRow(at: indexPath) as! EpisodeCell
                            cell.titleLabel.textColor = .lightGray
                            cell.descriptionLabel.textColor = .lightGray
                            cell.durationLabel.textColor = .lightGray
                            cell.downloadProgressView.progress = 0
                            self.episodes[indexPath.row].downloaded = true
                            self.tableView.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                }
                print(downloads.count)
                downloads = Array(downloads.dropFirst())
                print(downloads.count)
                if downloads.count > 0 {
                    self.downloadFile(at: downloads[0].audioUrl, relatedTo: downloads[0].parsedEpisode, addTo: downloads[0].addTo, playNow: downloads[0].playNow, cellIndexPath: downloads[0].indexPath)
                }
            } else {
                print("Downloads array has no items in it")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}

extension UIColor {
    var coreImageColor: CIColor {
        return CIColor(color: self)
    }
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let coreImageColor = self.coreImageColor
        return (coreImageColor.red, coreImageColor.green, coreImageColor.blue, coreImageColor.alpha)
    }
}
