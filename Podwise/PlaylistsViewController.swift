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
    func relayoutSection(row: Int, deleted: CDEpisode, playlist: CDPlaylist, episodesInPlaylist: Int)
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

class PlaylistsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, relayoutSectionDelegate, editPlaylistDelegate {
    
    struct PlaylistEpisodes {
        var name : CDPlaylist
        var episodes : [CDEpisode]
    }
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)

    var podcasts: [CDPodcast] = []
    var episodes: [CDEpisode] = []
    var misfitEpisodes: [CDEpisode] = []
    var playlists: [CDPlaylist] = []
    var headers: [PlaylistHeaderView] = []
    var episodesForPlaylists: [CDPlaylist: [CDEpisode]] = [CDPlaylist: [CDEpisode]]()
    var playlistStructArray = [PlaylistEpisodes]()
    var sectionDragging: Int!
    var temporarilyRemovedEpisodes: [CDEpisode] = []
    //var managedContext: NSManagedObjectContext?
    //var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    private var interactionController: UIPercentDrivenInteractiveTransition?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        
        collectionView.dragInteractionEnabled = true
        
        self.transitioningDelegate = self
        
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
        
        headers = []
        
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
        
        collectionView.reloadData()
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        
//        if !isTimerRunning {
//            runTimer()
//        }
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        podcasts = []
//        episodes = []
//        misfitEpisodes = []
//        playlists = []
//        episodesForPlaylists = [:]
//        playlistStructArray = []
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    @objc func checkDownloads() {
//        tableView.reloadData()
//    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return playlistStructArray.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if sectionDragging != nil {
            if section == sectionDragging {
                return 1
            }
        }
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row == 0 {
            return CGSize(width: collectionView.frame.width-16, height: 50)
        } else {
            return CGSize(width: collectionView.frame.width-16, height: 80)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row > 0 {
            let episode = playlistStructArray[indexPath.section].episodes[indexPath.row-1]// episodesInPlaylist[indexPath.row]
            let podcast = episode.podcast!
            if nowPlayingEpisode != nil {
                nowPlayingEpisode.progress = Int64(audioPlayer.currentTime)
            }
            CoreDataHelper.save(context: managedContext)
            nowPlayingEpisode = episode
            let nowPlayingImage = UIImage(data: nowPlayingEpisode.podcast!.image!)
            baseViewController.miniPlayerView.artImageView.image = nowPlayingImage
            baseViewController.setProgressBarColor(red: CGFloat(podcast.backgroundR), green: CGFloat(podcast.backgroundG), blue: CGFloat(podcast.backgroundB))
            playDownload(for: episode)
        }
        //baseViewController.setupNowPlaying(episode: episode)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section < playlistStructArray.count {
            if indexPath.row == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeaderViewCell", for: indexPath as IndexPath) as! PlaylistHeaderView
                
                cell.editDelegate = self
                if playlistStructArray[indexPath.section].episodes.count > 0 {
                    if let podcastPlaylist = playlistStructArray[indexPath.section].episodes[0].podcast?.playlist {
                        cell.playlist = podcastPlaylist
                        
                        let playlistColour = NSKeyedUnarchiver.unarchiveObject(with: podcastPlaylist.colour!)
                        
                        cell.cellBackgroundView.backgroundColor = playlistColour as? UIColor
                        
                        cell.label.text = podcastPlaylist.name!
                        if podcastPlaylist.name! == "Unsorted" {
                            cell.button.isHidden = true
                        } else {
                            cell.button.isHidden = false
                        }
                    }
                    
                    cell.isUserInteractionEnabled = true
                    
                    headers.append(cell)
                    
                    // round top left and right corners
                    let cornerRadius: CGFloat = 10
                    let maskLayer = CAShapeLayer()
                    
                    maskLayer.path = UIBezierPath(
                        roundedRect: cell.bounds,
                        byRoundingCorners: [.topLeft, .topRight],
                        cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                        ).cgPath
                    
                    cell.layer.mask = maskLayer
                    
                    return cell
                } else {
                    // Shouldnt ever hit this.
                    return UICollectionViewCell()
                }
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaylistCell", for: indexPath as IndexPath) as! PlaylistCollectionViewCell
                let thisEpisode: CDEpisode = playlistStructArray[indexPath.section].episodes[indexPath.row-1]
                cell.titleLabel.text = thisEpisode.title
                
                var hours = 0
                var minutes = 0
                if let optionalHours = Int(thisEpisode.duration!) {
                    hours = (optionalHours/60)/60
                }  else {
                    print(thisEpisode.duration!)
                    let durationArray = thisEpisode.duration?.split(separator: ":")
                    if let optionalHours = Int(durationArray![0]) {
                        hours = optionalHours
                    }
                }
                if let optionalMinutes = Int(thisEpisode.duration!) {
                    minutes = (optionalMinutes/60)%60
                }  else {
                    let durationArray = thisEpisode.duration!.split(separator: ":")
                    if let optionalMinutes = Int(durationArray[1]) {
                        minutes = optionalMinutes
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
                    cell.activityIndicator.isHidden = true
                }
                
                if downloads != nil {
                    for download in downloads {
                        if download.episode == thisEpisode {
                            cell.activityIndicator.startAnimating()
                            cell.activityIndicator.isHidden = false
                            cell.isUserInteractionEnabled = false
                            break
                        } else {
                            cell.activityIndicator.isHidden = true
                            cell.activityIndicator.stopAnimating()
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addPlaylistCell", for: indexPath) as! AddPlaylistCell
            
            cell.playlistButton.backgroundColor = UIColor.white
            cell.playlistButton.layer.cornerRadius = 15
            cell.playlistButton.layer.masksToBounds = true
            cell.editDelegate = self
            
            return cell
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
            
            player.currentTime = TimeInterval(episode.progress)
            player.prepareToPlay()
            startAudioSession()
            player.play()
            
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
    
    func relayoutSection(row: Int, deleted: CDEpisode, playlist: CDPlaylist, episodesInPlaylist: Int) {
        if playlistStructArray[row].episodes.contains(deleted) {
            let indexToDelete = playlistStructArray[row].episodes.index(of: deleted)
            playlistStructArray[row].episodes.remove(at: indexToDelete!)
            
            if episodesInPlaylist == 0 {
                playlistStructArray.remove(at: row)
                collectionView.deleteItems(at: [IndexPath(row: row, section: 0)])
                return
            }
            
            collectionView.reloadItems(at: [IndexPath(row: row, section: 0)])
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: collectionView.layoutSubviews, completion: nil)
        }
    }
    
    func reloadCollectionView() {
        viewDidLoad()
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
    
    // MARK: collection view Drag and Drop Delegate methods
    
    // Drag
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        var item: String
        var dragItems: [UIDragItem] = []
        if indexPath.row == 0 && indexPath.section != playlistStructArray.count {
            sectionDragging = indexPath.section
            item = playlistStructArray[indexPath.section].name.name!
            let itemProvider = NSItemProvider(object: item as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = playlistStructArray[indexPath.section]
            dragItems.append(dragItem)
//            var row = 1
//            for episode in playlistStructArray[indexPath.section].episodes {
//                let episodeItemProvider = NSItemProvider(object: episode.title! as NSString)
//                let episodeDragItem = UIDragItem(itemProvider: episodeItemProvider)
//                episodeDragItem.localObject = episode
//                dragItems.append(episodeDragItem)
//                row += 1
//            }
            
            
//            temporarilyRemovedEpisodes = []
//            var indexPathsToDelete: [IndexPath] = []
//            // remove dragging items
//            collectionView.performBatchUpdates({
//                var row = 1
//                print(playlistStructArray[indexPath.section].episodes.count)
//                for episode in playlistStructArray[indexPath.section].episodes {
//                    temporarilyRemovedEpisodes.append(episode)
//                    playlistStructArray[indexPath.section].episodes.removeFirst()
//                    indexPathsToDelete.append(IndexPath(row: row, section: indexPath.section))
//                    row += 1
//                }
//
//                collectionView.deleteItems(at: indexPathsToDelete)
//            })
            
            return dragItems
        } else {
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        let itemProvider = NSItemProvider(object: playlistStructArray[indexPath.section].episodes[indexPath.row-1].title! as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = playlistStructArray[indexPath.section].episodes[indexPath.row-1]
        return [dragItem]
    }
    
    // Drop
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if session.localDragSession != nil
        {
            if collectionView.hasActiveDrag
            {
                return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
            }
            else
            {
                return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        }
        else
        {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath
        {
            destinationIndexPath = indexPath
        }
        else
        {
            // Get index path of original playlist
            destinationIndexPath = IndexPath(row: 0, section: playlistStructArray.count)
        }
        
        switch coordinator.proposal.operation
        {
        case .move:
            // remove dragging items
            let indexSetToDelete = NSMutableIndexSet()
            indexSetToDelete.add(sectionDragging)
            
            let indexSetToAdd = NSMutableIndexSet()
            indexSetToAdd.add(destinationIndexPath.section)
            
            collectionView.performBatchUpdates({
                // remove dragged section
                let sectionToInsert = playlistStructArray[sectionDragging]
                
                playlistStructArray.remove(at: sectionDragging)
                collectionView.deleteSections(indexSetToDelete as IndexSet)
                
                // add in dropped section
                playlistStructArray.insert(sectionToInsert, at: destinationIndexPath.section)
                collectionView.insertSections(indexSetToAdd as IndexSet)
                
                var sortIndex = 0
                for item in playlistStructArray {
                    let thisPlaylist = CoreDataHelper.fetchAllPlaylists(with: item.name.id!, in: managedContext!)
                    if thisPlaylist.count > 0 {
                        thisPlaylist[0].sortIndex = Int64(sortIndex)
                    }
    
                    item.name.sortIndex = Int64(sortIndex)
                    CoreDataHelper.save(context: managedContext!)
                    sortIndex += 1
                }
            })
            var dIndexPath = destinationIndexPath
            if dIndexPath.row >= collectionView.numberOfItems(inSection: 0)
            {
                dIndexPath.row = collectionView.numberOfItems(inSection: 0) - 1
            }
            let item = coordinator.items[0]
            coordinator.drop(item.dragItem, toItemAt: dIndexPath)
            sectionDragging = nil
            
//            let indexSetToReload = NSMutableIndexSet()
//            indexSetToReload.add(indexSetToAdd as IndexSet)
//            indexSetToReload.add(indexSetToDelete as IndexSet)
            
            //collectionView.reloadSections(indexSetToReload as IndexSet)
            break
        case .copy:
            //Add the code to copy items
            break
            
        default:
            sectionDragging = nil
            return
        }
    }
}

