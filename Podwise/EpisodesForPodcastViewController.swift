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
    weak var reloadTableViewDelegate: reloadTableViewDelegate?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var channelLabel: UILabel!
    var channelDescriptionTextView: UITextView!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var playlistButton: UIButton!
    @IBOutlet weak var segmentedViewController: UISegmentedControl!
    var subscribeButtonSet: Bool = false
    var hasParsedXML = false
    var skippedChannelDescription = false
    
    var podcast: CDPodcast!
    var eName: String = String()
    var downloadedEpisodes: [CDEpisode] = []
    var unDownloadedEpisodes: [Episode] = []
    var episodeID: String = String()
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
        
        channelLabel.text! = podcast.title!
        
        subscribeButton.layer.cornerRadius = 15
        subscribeButton.layer.masksToBounds = true
        
        playlistButton.layer.cornerRadius = 15
        playlistButton.layer.masksToBounds = true
        playlistButton.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
        
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
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        downloadedEpisodes = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
        
        if let playlist = podcast.playlist {
            playlistButton.setTitle("  \(playlist.name!)  ", for: .normal)
        }
        
        tableView.reloadData()
    }
    
    // Table View Delegate Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedViewController.selectedSegmentIndex == 0 {
            return downloadedEpisodes.count
        } else {
            return unDownloadedEpisodes.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath as IndexPath) as! EpisodeCell
        var hours = 0
        var minutes = 0
        if segmentedViewController.selectedSegmentIndex == 0 { // already downloaded
            let episode = downloadedEpisodes[indexPath.row]
            if let optionalHours = Int(episode.duration!) {
                hours = (optionalHours/60)/60
            }
            if let optionalMinutes = Int(episode.duration!) {
                minutes = (optionalMinutes/60)%60
            }
            
            cell.titleLabel.text = episode.title
            cell.descriptionLabel.text = episode.subTitle
            
            cell.titleLabel.textColor = .black
            cell.descriptionLabel.textColor = .black
            cell.durationLabel.textColor = .black
        } else { // all episodes in feed
            let episode = unDownloadedEpisodes[indexPath.row]
            if let optionalHours = Int(episode.itunesDuration) {
                hours = (optionalHours/60)/60
            }
            if let optionalMinutes = Int(episode.itunesDuration) {
                minutes = (optionalMinutes/60)%60
            }
            
            cell.titleLabel.text = episode.title
            cell.descriptionLabel.text = episode.itunesSubtitle
            
            let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            // lets create your destination file url
            let destinationUrl = documentsDirectoryURL.appendingPathComponent(episode.audioUrl.lastPathComponent)
            
            // to check if it exists before downloading it
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
        }

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
        nowPlayingArt = UIImage(data: (self.podcast.image)!)
        baseViewController.miniPlayerView.artImageView.image = nowPlayingArt
        baseViewController.setProgressBarColor(red: CGFloat(podcast.backgroundR), green: CGFloat(podcast.backgroundG), blue: CGFloat(podcast.backgroundB))
        playDownload(at: episode.localURL!)
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
            self.downloadFile(at: self.unDownloadedEpisodes[indexPath.row].audioUrl, relatedTo: self.unDownloadedEpisodes[indexPath.row], addTo: nil, playNow: false, cellIndexPath: indexPath)
            success(true)
        })
        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Adding to playlist...")
            let alert = UIAlertController(title: "Add To Playlist", message: "", preferredStyle: .actionSheet)
            
            let playlists = CoreDataHelper.fetchAllPlaylists(in: self.managedContext!)
            
            for eachPlaylist in playlists {
                if self.segmentedViewController.selectedSegmentIndex == 0 {
                    alert.addAction(UIAlertAction(title: eachPlaylist.name, style: .default, handler: { (action) in
                        //execute some code when this option is selected
                        self.add(episode: self.downloadedEpisodes[indexPath.row], to: eachPlaylist)
                    }))
                } else {
                    alert.addAction(UIAlertAction(title: eachPlaylist.name, style: .default, handler: { (action) in
                        //execute some code when this option is selected
                        self.downloadFile(at: self.unDownloadedEpisodes[indexPath.row].audioUrl, relatedTo: self.unDownloadedEpisodes[indexPath.row], addTo: eachPlaylist, playNow: false, cellIndexPath: indexPath)
                    }))
                }
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            success(true)
        })
        
        let deleteFromDownloadedEpisodeAction = UIContextualAction(style: .destructive, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Delete action ...")
            let cdEpisode = CoreDataHelper.getEpisodeWith(id: self.downloadedEpisodes[indexPath.row].id!, in: self.managedContext!)
            if cdEpisode.count > 0 {
                do {
                    let filemanager = FileManager.default
                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
                    let destinationPath = documentsPath.appendingPathComponent(cdEpisode[0].localURL!.lastPathComponent)
                    if filemanager.fileExists(atPath: destinationPath) {
                        try! filemanager.removeItem(atPath: destinationPath)
                        tableView.beginUpdates()
                        CoreDataHelper.delete(episode: cdEpisode[0], in: self.managedContext!)
                        self.downloadedEpisodes.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        tableView.endUpdates()
                    } else {
                        print("not deleted, couldnt find file.")
                    }
                }
            }
            success(true)
        })
        
        let deleteFromUndownloadedEpisodeAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Delete action ...")
            let cdEpisode = CoreDataHelper.getEpisodeWith(id: self.unDownloadedEpisodes[indexPath.row].id, in: self.managedContext!)
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
                    CoreDataHelper.delete(episode: cdEpisode[0], in: self.managedContext!)
                    if self.downloadedEpisodes.contains(cdEpisode[0]) {
                        let indexToDelete = self.downloadedEpisodes.index(of: cdEpisode[0])
                        self.downloadedEpisodes.remove(at: indexToDelete!)
                    }
                }
            }
            
            let cell = tableView.cellForRow(at: indexPath) as! EpisodeCell
            cell.titleLabel.textColor = .lightGray
            cell.descriptionLabel.textColor = .lightGray
            cell.durationLabel.textColor = .lightGray
            self.unDownloadedEpisodes[indexPath.row].downloaded = false
            success(true)
        })
        
        downloadAction.image = UIImage(named: "downloadIcon")
        downloadAction.backgroundColor = UIColor(displayP3Red: 69/255.0, green: 152/255.0, blue: 152/255.0, alpha: 1.0)
        
        deleteFromUndownloadedEpisodeAction.image = UIImage(named: "trash")
        deleteFromUndownloadedEpisodeAction.backgroundColor = .red
        
        deleteFromDownloadedEpisodeAction.image = UIImage(named: "trash")
        deleteFromDownloadedEpisodeAction.backgroundColor = .red
        
        addToPlaylistAction.image = UIImage(named: "playlist")
        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
        
        if segmentedViewController.selectedSegmentIndex == 0 {
            return UISwipeActionsConfiguration(actions: [deleteFromDownloadedEpisodeAction, addToPlaylistAction])
        } else {
            if unDownloadedEpisodes[indexPath.row].downloaded {
                return UISwipeActionsConfiguration(actions: [deleteFromUndownloadedEpisodeAction, addToPlaylistAction])
            } else {
                return UISwipeActionsConfiguration(actions: [downloadAction, addToPlaylistAction])
            }
        }
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
            episodeID = String()
            episodeTitle = String()
            episodeDescription = String()
            episodeDuration = String()
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

            unDownloadedEpisodes.append(episode)
            tableView.reloadData()
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
                if skippedChannelDescription == false {
                    skippedChannelDescription = true
                } else {
                    episodeDescription += data
                }
            case "guid":
                episodeID = data
            case "itunes:duration":
                episodeDuration = data
            default:
                break
            }
        } else {
            
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
            unSortedPlaylist = playlistObject
        }
        
        // to check if it exists before downloading it
        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            print("The file already exists at path")
            if playNow {
                startAudioSession()
                nowPlayingArt = UIImage(data: (self.podcast.image)!)
                baseViewController.miniPlayerView.artImageView.image = nowPlayingArt
                baseViewController.setProgressBarColor(red: CGFloat(podcast.backgroundR), green: CGFloat(podcast.backgroundG), blue: CGFloat(podcast.backgroundB))
                self.playDownload(at: destinationUrl)
            }
            // if the file doesn't exist
        } else {
            let episodeEntity = NSEntityDescription.entity(forEntityName: "CDEpisode", in: managedContext!)!
            let episode = NSManagedObject(entity: episodeEntity, insertInto: managedContext) as! CDEpisode
            
            episode.id = relatedTo.id
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
            if let playlistToAddTo = addTo {
                add(episode: episode, to: playlistToAddTo)
            }
            
            if podcast != nil {
                if podcast.playlist == nil {
                    add(podcast: podcast, to: unSortedPlaylist)
                }
            }
            
            // you can use NSURLSession.sharedSession to download the data asynchronously
            URLSession.shared.downloadTask(with: at, completionHandler: { (location, response, error) -> Void in
                guard let location = location, error == nil else { return }
                do {
                    // after downloading your file you need to move it to your destination url
                    print("Target Path: \(destinationUrl)")
                    try FileManager.default.moveItem(at: location, to: destinationUrl)
                    print("File moved to documents folder")
                    if playNow {
                        self.startAudioSession()
                        nowPlayingArt = UIImage(data: (self.podcast.image)!)
                        baseViewController.miniPlayerView.artImageView.image = nowPlayingArt
                        baseViewController.setProgressBarColor(red: CGFloat(self.podcast.backgroundR), green: CGFloat(self.podcast.backgroundG), blue: CGFloat(self.podcast.backgroundB))
                        self.playDownload(at: destinationUrl)
                    }
                    if downloads.contains(episode) {
                        if let episodeIndex = downloads.index(of: episode) {
                            downloads.remove(at: episodeIndex)
                        }
                    }
                    
                    if let indexPath = cellIndexPath {
                        DispatchQueue.main.async {
                            let cell = self.tableView.cellForRow(at: indexPath) as! EpisodeCell
                            cell.titleLabel.textColor = .lightGray
                            cell.descriptionLabel.textColor = .lightGray
                            cell.durationLabel.textColor = .lightGray
                            self.unDownloadedEpisodes[indexPath.row].downloaded = true
                            self.tableView.reloadData()
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
    
    func add(podcast: CDPodcast, to playlist: CDPlaylist) {
        podcast.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
    
    func add(episode: CDEpisode, to playlist: CDPlaylist) {
        episode.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
    
    @IBAction func playlistButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Add To Playlist", message: "", preferredStyle: .actionSheet)
        
        let playlists = CoreDataHelper.fetchAllPlaylists(in: self.managedContext!)
        
        for eachPlaylist in playlists {
            alert.addAction(UIAlertAction(title: eachPlaylist.name, style: .default, handler: { (action) in
                //execute some code when this option is selected
                self.add(podcast: self.podcast!, to: eachPlaylist)
                DispatchQueue.main.async {
                    self.playlistButton.setTitle("  \(eachPlaylist.name!)  ", for: .normal)
                }
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func segmentChanged(_ sender: Any) {
        if segmentedViewController.selectedSegmentIndex == 0 {
            
            tableView.reloadData()
        } else {
            if !hasParsedXML {
                if let parser = XMLParser(contentsOf: podcast.feedURL!) {
                    parser.delegate = self
                    parser.parse()
                }
                print("Looking for: \(podcast.feedURL!)")
                hasParsedXML = true
            }
            tableView.reloadData()
        }
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let playlists = CoreDataHelper.fetchAllPlaylists(in: self.managedContext!)
        var playlistActionList: [UIPreviewAction] = []
        for eachPlaylist in playlists {
            let addToPlaylist = UIPreviewAction(title: "\(eachPlaylist.name!)", style: .default, handler: {_,_ in
                self.add(podcast: self.podcast, to: eachPlaylist)
            })
            playlistActionList.append(addToPlaylist)
        }
        
        let subscribe: UIPreviewAction!
        if podcast.subscribed {
            subscribe = UIPreviewAction(title: "Unsubscribe", style: .default, handler: {_,_ in
                self.podcast.subscribed = false
                CoreDataHelper.save(context: self.managedContext!)
                self.reloadTableViewDelegate?.reloadTableView()
            })
        } else {
            subscribe = UIPreviewAction(title: "Subscribe", style: .default, handler: {_,_ in
                self.podcast.subscribed = true
                CoreDataHelper.save(context: self.managedContext!)
                self.reloadTableViewDelegate?.reloadTableView()
            })
        }
        
        let cancel = UIPreviewAction(title: "Cancel", style: .destructive) { (action, controller) in
            print("Cancel Action Selected")
        }
        
        let playlistGroup = UIPreviewActionGroup(title: "Add to Playlist", style: .default, actions: playlistActionList)
        playlistActionList.append(subscribe)
        playlistActionList.append(cancel)
        
        return [playlistGroup, subscribe, cancel]
    }
}

