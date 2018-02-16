//
//  FirstViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import MediaPlayer

public protocol relayoutSectionDelegate: class {
    func relayoutSection(section: Int, deleted: CDEpisode, playlist: CDPlaylist, episodesInPlaylist: Int)
    func reloadCollectionView()
}

//public protocol editPlaylistParentDelegate: class {
//    func edit(playlist: CDPlaylist)
//    func edit()
//}

public protocol editPlaylistDelegate: class {
    func edit(playlist: CDPlaylist)
    func edit()
}

class PlaylistsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate,  relayoutSectionDelegate, editPlaylistDelegate { //UITableViewDragDelegate, UITableViewDropDelegate,
    
    struct PlaylistEpisodes {
        var name : CDPlaylist
        var episodes : [CDEpisode]
    }
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)

    var podcasts: [CDPodcast] = []
    var episodes: [CDEpisode] = []
    var misfitEpisodes: [CDEpisode] = []
    var playlists: [CDPlaylist] = []
    var episodesForPlaylists: [CDPlaylist: [CDEpisode]] = [CDPlaylist: [CDEpisode]]()
    var playlistStructArray = [PlaylistEpisodes]()
    var sectionDragging = 0
    var episodesToAddBack = [CDEpisode]()
    var isDragging = false
    //var managedContext: NSManagedObjectContext?
    //var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    private var interactionController: UIPercentDrivenInteractiveTransition?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        //tableView.dragDelegate = self
        //tableView.dropDelegate = self
        
        tableView.dragInteractionEnabled = true
        self.transitioningDelegate = self
        
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognized(gestureRecognizer:)))
        tableView.addGestureRecognizer(longpress)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        managedContext = appDelegate.persistentContainer.viewContext
        
        podcasts = CoreDataHelper.fetchAllPodcasts(in: managedContext!)
        episodes = []
        for podcast in podcasts {
            let episodesForPodcast = CoreDataHelper.getEpisodesForPodcastWithNoPlaylist(podcast: podcast, in: managedContext!)
            for episode in episodesForPodcast {
                episodes.append(episode)
            }
        }
        
        episodesForPlaylists = [:]
        playlistStructArray = [PlaylistEpisodes]()
        playlists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
        
        misfitEpisodes = []
        for playlist in playlists {
            let podcastsForPlaylist = CoreDataHelper.fetchPodcastsFor(playlist: playlist, in: managedContext!)
            var episodesForPlaylist:[CDEpisode] = []
            for podcast in podcastsForPlaylist {
                var episodesForPodcastInPlaylist = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
                for podcastEpisode in episodesForPodcastInPlaylist {
                    if podcastEpisode.playlist != nil {
                        misfitEpisodes.append(podcastEpisode)
                    }
                }
                for episode in misfitEpisodes {
                    if episodesForPodcastInPlaylist.contains(episode) {
                        let index = episodesForPodcastInPlaylist.index(of: episode)
                        episodesForPodcastInPlaylist.remove(at: index!)
                    }
                }
                episodesForPlaylist.append(contentsOf: episodesForPodcastInPlaylist)
            }
            
            episodesForPlaylists[playlist] = episodesForPlaylist
        }
        
        // assign misfit episodes into their proper playlist
        for misfit in misfitEpisodes {
            episodesForPlaylists[misfit.playlist!]?.append(misfit)
        }
        
        for (key, value) in episodesForPlaylists {
            if value.count > 0 {
                playlistStructArray.append(PlaylistEpisodes(name: key, episodes: value))
            }
        }
        
        playlistStructArray.sort(by: { $0.name.sortIndex < $1.name.sortIndex})
        
        //collectionView.backgroundColor = .black
        //collectionView.backgroundView?.backgroundColor = .black
        
        tableView.reloadData()
//        if !isTimerRunning {
//            runTimer()
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return playlistStructArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isDragging && section == sectionDragging {
            return 1
        } else {
            if section < playlistStructArray.count {
                if playlistStructArray[section].episodes.count == 0 {
                    return playlistStructArray[section].episodes.count
                } else {
                    return playlistStructArray[section].episodes.count + 1
                }
            } else {
                return 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 50
        } else {
            return 80
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .white
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (cell.responds(to: #selector(getter: UIView.tintColor))) {
            let cornerRadius: CGFloat = 10
            //cell.backgroundColor = UIColor.clear
            let layer: CAShapeLayer  = CAShapeLayer()
            let pathRef: CGMutablePath  = CGMutablePath()
            let bounds: CGRect  = cell.bounds
            var addLine: Bool  = false
            if (indexPath.row == 0 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1) {
                //pathRef.__addRoundedRect(transform: nil, rect: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
            } else if (indexPath.row == 0) {
                // do basically nothing
            } else if (indexPath.row == tableView.numberOfRows(inSection: indexPath.section)-1) {
                
                pathRef.move(to: CGPoint(x:bounds.minX,y:bounds.minY))
                pathRef.addArc(tangent1End: CGPoint(x:bounds.minX,y:bounds.maxY), tangent2End: CGPoint(x:bounds.midX,y:bounds.maxY), radius: cornerRadius)
                
                pathRef.addArc(tangent1End: CGPoint(x:bounds.maxX-4,y:bounds.maxY), tangent2End: CGPoint(x:bounds.maxX-4,y:bounds.midY), radius: cornerRadius)
                pathRef.addLine(to: CGPoint(x:bounds.maxX-4,y:bounds.minY))
            } else {
                pathRef.addRect(CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width-4, height: bounds.height))
                addLine = true
            }
            layer.path = pathRef
            //set the border color
            layer.strokeColor = UIColor.lightGray.cgColor;
            //set the border width
            layer.lineWidth = 1
            layer.fillColor = UIColor(white: 1, alpha: 1.0).cgColor
            
            
            if (addLine == true) {
                let lineLayer: CALayer = CALayer()
                let lineHeight: CGFloat  = (1 / UIScreen.main.scale)
                lineLayer.frame = CGRect(x:bounds.minX, y:bounds.size.height-lineHeight, width:bounds.size.width, height:lineHeight)
                lineLayer.backgroundColor = tableView.separatorColor!.cgColor
                layer.addSublayer(lineLayer)
            }
            
            let testView: UIView = UIView(frame:bounds)
            testView.layer.insertSublayer(layer, at: 0)
            testView.backgroundColor = UIColor.clear
            cell.backgroundView = testView
        }
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if (cell.responds(to: #selector(getter: UIView.tintColor))) {
//            let cornerRadius: CGFloat = 0;
//            //cell.backgroundColor = .clear
//            let layer: CAShapeLayer  = CAShapeLayer()
//            let pathRef: CGMutablePath  = CGMutablePath()
//            let bounds: CGRect  = cell.bounds
//            var addLine: Bool = false
//            if (indexPath.section != tableView.numberOfSections-1) {
//                pathRef.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
//                pathRef.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
//                let playlistColour: UIColor = NSKeyedUnarchiver.unarchiveObject(with: playlistStructArray[indexPath.section].name.colour!) as! UIColor
//                layer.strokeColor = playlistColour.cgColor
//                addLine = true
//
//                layer.path = pathRef;
//                //set the border color
//                layer.fillColor = UIColor(white: 1, alpha: 1.0).cgColor;
//                //set the border width
//                layer.lineWidth = 2;
//
//
//                if (addLine == true) {
//                    //                let lineLayer: CALayer = CALayer();
//                    //                let lineHeight: CGFloat  = (1 / UIScreen.main.scale);
//                    //                lineLayer.frame = CGRect(x: bounds.minX, y: bounds.size.height-lineHeight, width: bounds.size.width, height: lineHeight);
//                    //                lineLayer.backgroundColor = tableView.separatorColor!.cgColor;
//                    //layer.addSublayer(lineLayer);
//                }
//
//                cell.layer.insertSublayer(layer, at: 100)
//            }
//        }
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isDragging && indexPath.section == sectionDragging {
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath as IndexPath) as! PlaylistTitleCell
            
            cell.editDelegate = self
            if let podcastPlaylist = episodesToAddBack[0].podcast?.playlist {
                cell.playlist = podcastPlaylist
                
                let playlistColour = NSKeyedUnarchiver.unarchiveObject(with: podcastPlaylist.colour!)
                
                cell.backgroundColor = playlistColour as? UIColor
                
                cell.titleTextField.text = podcastPlaylist.name!
                if podcastPlaylist.name! == "Unsorted" {
                    cell.editPlaylistButton.isHidden = true
                } else {
                    cell.editPlaylistButton.isHidden = false
                }
            }
            
            cell.isUserInteractionEnabled = true
            
            // round top left and right corners
            let cornerRadius: CGFloat = 15
            let maskLayer = CAShapeLayer()
            
            maskLayer.path = UIBezierPath(
                roundedRect: cell.bounds,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                ).cgPath
            
            cell.layer.mask = maskLayer
            return cell
        } else {
            if indexPath.section < playlistStructArray.count {
                if indexPath.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath as IndexPath) as! PlaylistTitleCell
                    
                    cell.editDelegate = self
                    if playlistStructArray[indexPath.section].episodes.count > 0 {
                        if let podcastPlaylist = playlistStructArray[indexPath.section].episodes[0].podcast?.playlist {
                            cell.playlist = podcastPlaylist
                            
                            let playlistColour = NSKeyedUnarchiver.unarchiveObject(with: podcastPlaylist.colour!)
                            
                            cell.backgroundColor = playlistColour as? UIColor
                            
                            cell.titleTextField.text = podcastPlaylist.name!
                            if podcastPlaylist.name! == "Unsorted" {
                                cell.editPlaylistButton.isHidden = true
                            } else {
                                cell.editPlaylistButton.isHidden = false
                            }
                        }
                        
                        cell.isUserInteractionEnabled = true
                        return cell
                    } else {
                        // Shouldnt ever hit this.
                        return UITableViewCell()
                    }
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath as IndexPath) as! PlaylistCell
                    let thisEpisode: CDEpisode = playlistStructArray[indexPath.section].episodes[indexPath.row-1]
                    cell.titleLabel.text = thisEpisode.title
                    
                    var hours = 0
                    var minutes = 0
                    if let optionalHours = Int(thisEpisode.duration!) {
                        hours = (optionalHours/60)/60
                    }  else {
                        let durationArray = thisEpisode.duration?.split(separator: ":")
                        if durationArray?.count ?? 0 > 0 {
                            if let optionalHours = Int(durationArray![0]) {
                                hours = optionalHours
                            }
                        }
                    }
                    if let optionalMinutes = Int(thisEpisode.duration!) {
                        minutes = (optionalMinutes/60)%60
                    }  else {
                        let durationArray = thisEpisode.duration!.split(separator: ":")
                        if durationArray.count > 0 {
                            if let optionalMinutes = Int(durationArray[1]) {
                                minutes = optionalMinutes
                            }
                        }
                    }
                    
                    cell.titleLabel.text = thisEpisode.title
                    cell.durationLabel.text = thisEpisode.subTitle
                    if hours == 0 && minutes == 0 {
                        cell.durationLabel.text = ""
                    } else if hours == 0 {
                        cell.durationLabel.text = "\(minutes)m"
                    } else {
                        cell.durationLabel.text = "\(hours)h \(minutes)m"
                    }
                    
                    DispatchQueue.main.async {
                        if let imageData = thisEpisode.podcast?.image {
                            cell.artImageView.image = UIImage(data: imageData)
                        }
                        
                        cell.artImageView.layer.cornerRadius = 10
                        cell.artImageView.layer.masksToBounds = true
                    }
                    
                    if downloads != nil {
                        for download in downloads {
                            if download.episode == thisEpisode {
                                cell.isUserInteractionEnabled = false
                                break
                            } else {
                                cell.isUserInteractionEnabled = true
                            }
                        }
                    }
                    
                    if indexPath.row == playlistStructArray[indexPath.section].episodes.count {
                        // round top left and right corners
                        let cornerRadius: CGFloat = 10
                        let maskLayer = CAShapeLayer()
                        
                        maskLayer.path = UIBezierPath(
                            roundedRect: cell.bounds,
                            byRoundingCorners: [.bottomLeft, .bottomRight],
                            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                            ).cgPath
                        
                        cell.layer.mask = maskLayer
                    }
                    
                    return cell
                }
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "addPlaylistCell", for: indexPath) as! AddPlaylistCell
                
                cell.playlistButton.backgroundColor = UIColor.white
                cell.playlistButton.layer.cornerRadius = 15
                cell.playlistButton.layer.masksToBounds = true
                cell.editDelegate = self
                
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != 0 {
            let thisEpisode: CDEpisode = playlistStructArray[indexPath.section].episodes[indexPath.row-1]
            let podcast = thisEpisode.podcast!
            if nowPlayingEpisode != nil {
                nowPlayingEpisode.progress = Int64(audioPlayer.currentTime)
            }
            CoreDataHelper.save(context: managedContext)
            nowPlayingEpisode = thisEpisode
            let nowPlayingImage = UIImage(data: nowPlayingEpisode.podcast!.image!)
            baseViewController.miniPlayerView.artImageView.image = nowPlayingImage
            baseViewController.setProgressBarColor(red: CGFloat(podcast.backgroundR), green: CGFloat(podcast.backgroundG), blue: CGFloat(podcast.backgroundB))
            playDownload(for: thisEpisode)
            playlistQueue = playlistStructArray[indexPath.section].episodes
        }
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        if indexPath.row != 0 {
            let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                let alert = UIAlertController(title: "Add To Playlist", message: "", preferredStyle: .actionSheet)
                
                let playlists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
                
                for eachPlaylist in playlists {
                    alert.addAction(UIAlertAction(title: eachPlaylist.name, style: .default, handler: { (action) in
                        self.add(episode: self.playlistStructArray[indexPath.section].episodes[indexPath.row-1], to: eachPlaylist)
                    }))
                }
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: {
                    self.tableView.reloadData()
                })
                success(true)
            })
            
            let deleteEpisodeAction = UIContextualAction(style: .destructive, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                print("Delete action ...")
                let cdEpisode: CDEpisode = self.playlistStructArray[indexPath.section].episodes[indexPath.row-1]
                let cdPlaylist: CDPlaylist = cdEpisode.playlist ?? (cdEpisode.podcast?.playlist)!
                let filemanager = FileManager.default
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
                let destinationPath = documentsPath.appendingPathComponent(cdEpisode.localURL!.lastPathComponent)
                print("Deleting From: \(destinationPath)")
                if filemanager.fileExists(atPath: destinationPath) {
                    try! filemanager.removeItem(atPath: destinationPath)
                } else {
                    print("not deleted, couldnt find file.")
                }
                tableView.beginUpdates()
                CoreDataHelper.delete(episode: cdEpisode, in: managedContext!)
                self.playlistStructArray[indexPath.section].episodes.remove(at: indexPath.row-1)
                
                if self.playlistStructArray[indexPath.section].episodes.count == 0 {
                    tableView.deleteRows(at: [IndexPath(row: 0, section: indexPath.section),indexPath], with: .automatic)
                } else {
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
                tableView.endUpdates()
                
                self.relayoutSection(section: indexPath.section, deleted: cdEpisode, playlist: cdPlaylist, episodesInPlaylist:self.playlistStructArray[indexPath.section].episodes.count)
                success(true)
            })
            
            deleteEpisodeAction.image = UIImage(named: "trash")
            deleteEpisodeAction.backgroundColor = .red
            
            addToPlaylistAction.image = UIImage(named: "playlist")
            addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
            
            return UISwipeActionsConfiguration(actions: [deleteEpisodeAction, addToPlaylistAction])
        } else {
            return UISwipeActionsConfiguration(actions: [])
        }
    }
    
    func add(episode: CDEpisode, to playlist: CDPlaylist) {
        episode.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
    
    func playDownload(for episode: CDEpisode) {
        startAudioSession()
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(episode.localURL!.lastPathComponent)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: destinationUrl)
            guard let player = audioPlayer else { return }
            audioPlayer.delegate = baseViewController
            player.currentTime = TimeInterval(episode.progress)
            player.prepareToPlay()
            //startAudioSession()
            player.play()
            autoPlay = true
            
            let artworkImage = UIImage(data: episode.podcast!.image!)
            let artwork = MPMediaItemArtwork.init(boundsSize: artworkImage!.size, requestHandler: { (size) -> UIImage in
                return artworkImage!
            })
            
            let mpic = MPNowPlayingInfoCenter.default()
            mpic.nowPlayingInfo = [MPMediaItemPropertyTitle:episode.title!,
                                   MPMediaItemPropertyArtist:episode.podcast!.title!,
                                   MPMediaItemPropertyArtwork: artwork,
                                   MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
                                   MPMediaItemPropertyPlaybackDuration: player.duration
            ]
            
            baseViewController.miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            baseViewController.showMiniPlayer(animated: true)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func startAudioSession() {
        // set up background audio capabilities
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeDefault, options: .interruptSpokenAudioAndMixWithOthers)
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
    
    func relayoutSection(section: Int, deleted: CDEpisode, playlist: CDPlaylist, episodesInPlaylist: Int) {
        if playlistStructArray[section].episodes.contains(deleted) {
            let indexToDelete = playlistStructArray[section].episodes.index(of: deleted)
            playlistStructArray[section].episodes.remove(at: indexToDelete!)
            
            if episodesInPlaylist == 0 {
                playlistStructArray.remove(at: section)
                tableView.deleteRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
                return
            }
            
            tableView.reloadRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: tableView.layoutSubviews, completion: nil)
        }
    }
    
    func reloadCollectionView() {
        viewWillAppear(true)
    }
    
    func edit(playlist: CDPlaylist) {
        // Safe Push VC
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "playlistCreationViewController") as? PlaylistCreationTableViewController {
            
            viewController.playlist = playlist
            viewController.transitioningDelegate = self
            viewController.modalPresentationStyle = .custom
            viewController.relayoutSectionDelegate = self
            
            navigationController?.present(viewController, animated: true, completion: nil)
        }
    }
    
    func edit() {
        // Safe Push VC
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "playlistCreationViewController") as? PlaylistCreationTableViewController {
          
            viewController.transitioningDelegate = self
            viewController.modalPresentationStyle = .custom
            viewController.relayoutSectionDelegate = self
            
            navigationController?.present(viewController, animated: true, completion: nil)
        }
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentation = PresentationController.init(presentedViewController: presented, presenting: presenting)
        
        return presentation;
    }

    var cellSnapshot : UIView? = nil
    var initialIndexPath : IndexPath? = nil
    @objc func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        let longPress = gestureRecognizer as! UILongPressGestureRecognizer
        let state = longPress.state
        let locationInView = longPress.location(in: tableView)
        var indexPath = tableView.indexPathForRow(at: locationInView)
        let impact = UIImpactFeedbackGenerator()
        impact.prepare()
        switch state {
        case .began:
            if indexPath != nil {
                if indexPath!.row == 0 {
                    impact.impactOccurred()
                    initialIndexPath = indexPath
                    let cell = tableView.cellForRow(at: indexPath!) as UITableViewCell!
                    cellSnapshot = snapshopOfCell(inputView: cell!)
                    var center = cell?.center
                    cellSnapshot!.center = center!
                    cellSnapshot!.alpha = 0.0
                    tableView.addSubview(cellSnapshot!)
                    
                    UIView.animate(withDuration: 0.25, animations: { () -> Void in
                        center?.y = locationInView.y
                        self.cellSnapshot!.center = center!
                        self.cellSnapshot!.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
                        self.cellSnapshot!.alpha = 0.98
                        cell?.alpha = 0.0
                        
                    }, completion: { (finished) -> Void in
                        if finished {
                            cell?.isHidden = true
                        }
                    })
                }
            }
        case .changed:
            if cellSnapshot != nil {
                var center = cellSnapshot!.center
                center.y = locationInView.y
                cellSnapshot!.center = center
                
                if ((indexPath != nil) && (indexPath?.section != initialIndexPath?.section) && (indexPath?.row == 0)) {
                    impact.impactOccurred()
                    if indexPath!.section < playlistStructArray.count {
                        tableView.beginUpdates()
                        let original = playlistStructArray[initialIndexPath!.section]
                        let target = playlistStructArray[indexPath!.section]
                        
                        playlistStructArray[indexPath!.section] = original
                        playlistStructArray[initialIndexPath!.section] = target
                        
                        tableView.moveSection(initialIndexPath!.section, toSection: indexPath!.section)
                        initialIndexPath = indexPath
                        tableView.endUpdates()
                        
                        playlistStructArray[indexPath!.section].name.sortIndex = Int64(indexPath!.section)
                        playlistStructArray[initialIndexPath!.section].name.sortIndex = Int64(initialIndexPath!.section)
                        
                        var index = 0
                        for playlist in playlistStructArray {
                            playlist.name.sortIndex = Int64(index)
                            index += 1
                        }
                        CoreDataHelper.save(context: managedContext)
                    }
                }
            }
        default:
            if cellSnapshot != nil {
                let adjustedIndexPath = IndexPath(row: 0, section: initialIndexPath!.section)
                let cell = tableView.cellForRow(at: adjustedIndexPath) as! PlaylistTitleCell
                cell.isHidden = false
                cell.alpha = 0.0
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.cellSnapshot!.center = (cell.center)
                    self.cellSnapshot!.transform = CGAffineTransform.identity
                    self.cellSnapshot!.alpha = 0.0
                    cell.alpha = 1.0
                }, completion: { (finished) -> Void in
                    if finished {
                        self.initialIndexPath = nil
                        self.cellSnapshot!.removeFromSuperview()
                        self.cellSnapshot = nil
                    }
                })
            }
        }
    }
        
    func snapshopOfCell(inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let cellSnapshot : UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }
}

