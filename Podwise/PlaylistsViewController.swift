//
//  FirstViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
//import AVFoundation
//import MediaPlayer

public protocol relayoutSectionDelegate: class {
    func relayoutSection(section: Int, deleted: CDEpisode, playlist: CDPlaylist, episodesInPlaylist: Int)
    func reloadCollectionView()
}

public protocol editPlaylistDelegate: class {
    func edit(playlist: CDPlaylist)
    func edit()
}

class PlaylistsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate, UITableViewDragDelegate, UITableViewDropDelegate, UIViewControllerPreviewingDelegate, UIGestureRecognizerDelegate, relayoutSectionDelegate, editPlaylistDelegate {
    
    struct PlaylistEpisodes {
        var name : CDPlaylist
        var episodes : [CDEpisode]
    }

    var podcasts: [CDPodcast] = []
    var episodes: [CDEpisode] = []
    var misfitEpisodes: [CDEpisode] = []
    var playlists: [CDPlaylist] = []
    var episodesForPlaylists: [CDPlaylist: [CDEpisode]] = [CDPlaylist: [CDEpisode]]()
    var playlistStructArray = [PlaylistEpisodes]()
    var sectionDragging = 0
    var episodesToAddBack = [CDEpisode]()
    var isDragging = false
    var episodeToShowNotesFor: CDEpisode?
    var nowPlayingCell: PlaylistCell!
    //var managedContext: NSManagedObjectContext?
    //var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    private var interactionController: UIPercentDrivenInteractiveTransition?
    
    @IBOutlet weak var tableView: UITableView!
    var centerHeightConstraint: NSLayoutConstraint!
    var leftHeightConstraint: NSLayoutConstraint!
    var rightHeightConstraint: NSLayoutConstraint!
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.red
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        
        tableView.dragInteractionEnabled = true
        self.transitioningDelegate = self
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        NotificationCenter.default.addObserver(self,selector: #selector(downloadProgress(notification:)),
                                               name: NSNotification.Name(rawValue: "DownloadProgress"),
                                               object: nil)
        
        if( traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self, sourceView: view)
        }
        
        tableView.separatorColor = tableView.backgroundColor
        tableView.register(UINib(nibName: "FooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "footerView")
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0.1))
        tableView.addSubview(self.refreshControl)
        
        NotificationCenter.default.addObserver(self,selector: #selector(episodeEnded(notification:)),
                                               name: NSNotification.Name(rawValue: "EpisodeEnded"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,selector: #selector(playNextEpisodeAnimation(notification:)),
                                               name: NSNotification.Name(rawValue: "PlayNextEpisodeAnimation"),
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        episodeToShowNotesFor = nil
        
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
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return playlistStructArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section != playlistStructArray.count && playlistStructArray[section].name.isCollapsed {
            return 1
        } else {
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
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 40
        } else {
            return 80
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        print(indexPath.section)
        print(playlistStructArray.count)
        if indexPath.section != playlistStructArray.count - 1{
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section != playlistStructArray.count {
            if let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "footerView") as? PlaylistFooterView  {
                let playlistColour = NSKeyedUnarchiver.unarchiveObject(with: playlistStructArray[section].name.colour!)
                footerView.footerBackgroundView.backgroundColor = playlistColour as? UIColor
                
                footerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30)
                footerView.center = CGPoint(x: tableView.center.x, y: footerView.center.y)
                
                // round top left and right corners
                let cornerRadius: CGFloat = 5
                let maskLayer = CAShapeLayer()
                
                maskLayer.path = UIBezierPath(
                    roundedRect: footerView.bounds,
                    byRoundingCorners: [.bottomLeft, .bottomRight],
                    cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                    ).cgPath
                
                footerView.layer.mask = maskLayer
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
                tap.delegate = self
                footerView.addGestureRecognizer(tap)
                
                if playlistStructArray[section].name.isCollapsed {
                    let image = UIImage(named: "down_arrow_24")
                    footerView.collapseExpandButton.setImage(image, for: .normal)
                } else {
                    let image = UIImage(named: "up_arrow_24")
                    footerView.collapseExpandButton.setImage(image, for: .normal)
                }
                footerView.collapseExpandButton.transform = .identity
                let tapButton = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
                tapButton.delegate = self
                footerView.collapseExpandButton.addGestureRecognizer(tapButton)
                
                return footerView
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let playlstCell = cell as? PlaylistCell {
            let thisEpisode: CDEpisode = playlistStructArray[indexPath.section].episodes[indexPath.row-1]
            playlstCell.titleLabel.text = thisEpisode.title
            playlstCell.activityIndicator.isHidden = true
            if downloads != nil {
                for download in downloads {
                    if download.episode == thisEpisode {
                        playlstCell.activityIndicator.startAnimating()
                        playlstCell.activityIndicator.isHidden = false
                    }
                }
            }
            
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
            
            playlstCell.titleLabel.text = thisEpisode.title
            playlstCell.durationLabel.text = thisEpisode.subTitle
            playlstCell.percentDowloadedLabel.isHidden = true
            if hours == 0 && minutes == 0 {
                playlstCell.durationLabel.text = ""
            } else if hours == 0 {
                playlstCell.durationLabel.text = "\(minutes)m"
            } else {
                playlstCell.durationLabel.text = "\(hours)h \(minutes)m"
            }
            
            DispatchQueue.main.async {
                playlstCell.artImageView.image = UIImage.image(with: thisEpisode.podcast!.image!)
                
                playlstCell.artImageView.layer.cornerRadius = 3
                playlstCell.artImageView.layer.masksToBounds = true
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < playlistStructArray.count {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath as IndexPath) as! PlaylistTitleCell
                
                cell.editDelegate = self
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
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath as IndexPath) as! PlaylistCell
                
                cell.isUserInteractionEnabled = true
                
                if playlistStructArray[indexPath.section].episodes[indexPath.row-1] == nowPlayingEpisode {
                    nowPlayingCell = cell
                    if nowPlayingCell.nowPlayingView.isHidden == true {
                        leftHeightConstraint = nowPlayingCell.leftEQHeightConstraint
                        centerHeightConstraint = nowPlayingCell.centerEQHeightConstraint
                        rightHeightConstraint = nowPlayingCell.rightEQHeightConstraint
                        nowPlayingCell.nowPlayingView.play()
                        startNowPlayingAnimations()
                    }
                } else {
                    cell.nowPlayingView.isHidden = true
                    cell.nowPlayingView.alpha = 0
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != 0 {
            let thisEpisode: CDEpisode = playlistStructArray[indexPath.section].episodes[indexPath.row-1]
            let podcast = thisEpisode.podcast!
            if nowPlayingEpisode != nil {
                if audioPlayer != nil {
                    nowPlayingEpisode.progress = Int64(audioPlayer.currentTime)
                } else {
                    nowPlayingEpisode.progress = 0
                }
            }
            CoreDataHelper.save(context: managedContext)
            nowPlayingEpisode = thisEpisode
            //let playlistColour = NSKeyedUnarchiver.unarchiveObject(with: (podcast.playlist?.colour!)!) as? UIColor
            let cell = tableView.cellForRow(at: indexPath) as! PlaylistCell
            nowPlayingCell = cell
            
            // check needed b/c weird stuff was happening with the animations if the cell was tapped twice.
            if nowPlayingCell.nowPlayingView.isHidden == true {
                leftHeightConstraint = nowPlayingCell.leftEQHeightConstraint
                centerHeightConstraint = nowPlayingCell.centerEQHeightConstraint
                rightHeightConstraint = nowPlayingCell.rightEQHeightConstraint
                
                self.centerHeightConstraint.constant = 2
                self.leftHeightConstraint.constant = 1
                self.rightHeightConstraint.constant = 1
                
                startNowPlayingAnimations()
                
                cell.nowPlayingView.play()
            }
            let nowPlayingImage = UIImage.image(with: nowPlayingEpisode.podcast!.image!)
            baseViewController.miniPlayerView.artImageView.image = nowPlayingImage
            baseViewController.setProgressBarColor(red: CGFloat(podcast.backgroundR), green: CGFloat(podcast.backgroundG), blue: CGFloat(podcast.backgroundB))
            AudioHelper.playDownload(for: thisEpisode)
            playlistQueue = playlistStructArray[indexPath.section].episodes
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.row != 0 {
            if let cell = tableView.cellForRow(at: indexPath) as? PlaylistCell {
                cell.nowPlayingView.stopPlaying()
            }
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
//                let filemanager = FileManager.default
//                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
//                let destinationPath = documentsPath.appendingPathComponent(cdEpisode.localURL!.lastPathComponent)
//                print("Deleting From: \(destinationPath)")
//                if filemanager.fileExists(atPath: destinationPath) {
//                    try! filemanager.removeItem(atPath: destinationPath)
//                } else {
//                    print("not deleted, couldnt find file.")
//                }
                tableView.beginUpdates()
                if cdEpisode == nowPlayingEpisode {
                    audioPlayer.pause()
                    baseViewController.hideMiniPlayer(animated: true)
                }
                CoreDataHelper.delete(episode: cdEpisode, in: managedContext!)
                self.playlistStructArray[indexPath.section].episodes.remove(at: indexPath.row-1)
                
                if self.playlistStructArray[indexPath.section].episodes.count == 0 {
                    tableView.deleteRows(at: [IndexPath(row: 0, section: indexPath.section),indexPath], with: .automatic)
                    let indexSet = NSMutableIndexSet()
                    indexSet.add(indexPath.section)
                     self.playlistStructArray.remove(at: indexPath.section)
                    tableView.deleteSections(indexSet as IndexSet, with: .automatic)
                } else {
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.relayoutSection(section: indexPath.section, deleted: cdEpisode, playlist: cdPlaylist, episodesInPlaylist:self.playlistStructArray[indexPath.section].episodes.count)
                }
                tableView.endUpdates()
                
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
    
    func stopEQAnimations() {
        nowPlayingCell.centerEQView.layer.removeAllAnimations()
        nowPlayingCell.leftEQView.layer.removeAllAnimations()
        nowPlayingCell.rightEQView.layer.removeAllAnimations()
    }
    
    func startNowPlayingAnimations() {
        stopEQAnimations()
        
        // Center bar animation
        UIView.animate(withDuration: 1, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 2.0, options: [.autoreverse, .repeat], animations: {
            let constant = 10
            self.centerHeightConstraint.constant = CGFloat(constant)
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        // left bar animation
        UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1.0, options: [.autoreverse, .repeat], animations: {
            let constant = 7
            self.leftHeightConstraint.constant = CGFloat(constant)
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        // right bar animation
        UIView.animate(withDuration: 0.75, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.5, options: [.autoreverse, .repeat], animations: {
            let constant = 8
            self.rightHeightConstraint.constant = CGFloat(constant)
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func add(episode: CDEpisode, to playlist: CDPlaylist) {
        episode.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
        
    func relayoutSection(section: Int, deleted: CDEpisode, playlist: CDPlaylist, episodesInPlaylist: Int) {
        if playlistStructArray[section].episodes.contains(deleted) {
            let indexToDelete = playlistStructArray[section].episodes.index(of: deleted)
            playlistStructArray[section].episodes.remove(at: indexToDelete!)
            
            if episodesInPlaylist == 0 {
                playlistStructArray.remove(at: section)
                tableView.deleteRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
                let indexSet = NSMutableIndexSet()
                indexSet.add(section)
                tableView.reloadSections(indexSet as IndexSet, with: .fade)
                return
            }
            
            tableView.reloadRows(at: [IndexPath(row: 0, section: section)], with: .automatic)
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: tableView.layoutSubviews, completion: nil)
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
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // stop illegal drags before they happen
        let impact = UIImpactFeedbackGenerator()
        impact.prepare()
        if indexPath.row == 0 || indexPath.section == playlistStructArray.count{ // drag section
            impact.impactOccurred()
            let item = playlistStructArray[indexPath.section]
            let itemProvider = NSItemProvider(object: item.name.name! as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            return [dragItem]
        } else { // drag row
            impact.impactOccurred()
            let item = playlistStructArray[indexPath.section].episodes[indexPath.row-1]
            let itemProvider = NSItemProvider(object: item.title! as NSString)
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            return [dragItem]
        }
    }
    
    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        let item = playlistStructArray[indexPath.section]
        let itemProvider = NSItemProvider(object: item.name.name! as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if session.localDragSession != nil
        {
            if tableView.hasActiveDrag
            {
                return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
            else
            {
                return UITableViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        }
        else
        {
            return UITableViewDropProposal(operation: .forbidden)
        }
    }
    
//    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
//    {
//        let item = playlistStructArray[sourceIndexPath.section]
//        self.playlistStructArray.remove(at: sourceIndexPath.section)
//        self.playlistStructArray.insert(item, at: destinationIndexPath.section)
//    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        var destinationIndexPath: IndexPath
        var sourceIndexPath = coordinator.items[0].sourceIndexPath
        if let indexPath = coordinator.destinationIndexPath
        {
            if sourceIndexPath?.row == 0 {
                destinationIndexPath = indexPath
            } else {
                if indexPath.row == 0 { // if trying to insert at row 0, insert at last row of previous section
                    if indexPath.section == 0 { // insert in first row of first section
                        destinationIndexPath = IndexPath(row: 1, section: 0)
                    } else { // insert in last row of previous section
                        destinationIndexPath = IndexPath(row: playlistStructArray[indexPath.section-1].episodes.count, section: indexPath.section-1)
                    }
                } else {
                    destinationIndexPath = indexPath
                }
            }
        }
        else
        {
            // Get last index path of table view. (not including + button)
            let section = tableView.numberOfSections - 2
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        switch coordinator.proposal.operation
        {
        case .move:
            if sourceIndexPath != nil {
                if sourceIndexPath!.row == 0 { // move section
                    if destinationIndexPath.section == playlistStructArray.count {
                        destinationIndexPath = sourceIndexPath!
                    }
                    print(sourceIndexPath)
                    //Add the code to reorder items
                    let item = playlistStructArray[sourceIndexPath!.section]
                    tableView.beginUpdates()
                    playlistStructArray.remove(at: sourceIndexPath!.section)
                    playlistStructArray.insert(item, at: destinationIndexPath.section)
                    
                    tableView.moveSection(sourceIndexPath!.section, toSection: destinationIndexPath.section)
                    tableView.endUpdates()
                } else { // move row(s)
                    print(sourceIndexPath)
                    //Add the code to reorder items
                    let item = playlistStructArray[sourceIndexPath!.section]
                    tableView.beginUpdates()
                    let itemToadd = playlistStructArray[sourceIndexPath!.section].episodes[sourceIndexPath!.row-1]
                    itemToadd.playlist = playlistStructArray[destinationIndexPath.section].name
                    CoreDataHelper.save(context: managedContext)
                    playlistStructArray[sourceIndexPath!.section].episodes.remove(at: sourceIndexPath!.row-1)
                    playlistStructArray[destinationIndexPath.section].episodes.insert(itemToadd, at: destinationIndexPath.row-1)
    
                    tableView.moveRow(at: sourceIndexPath!, to: destinationIndexPath)
                    // check if there are any episodes left in that section
                    if  playlistStructArray[sourceIndexPath!.section].episodes.count == 0 {
                        // if there are none left, remove the section
                        playlistStructArray.remove(at: sourceIndexPath!.section)
                        let indexSet = NSMutableIndexSet()
                        indexSet.add(sourceIndexPath!.section)
                        tableView.deleteSections(indexSet as IndexSet, with: .automatic)
                    }
                    tableView.endUpdates()
                    refreshPlaylistQueue()
                }
            }
            break
            
        case .copy:
            //Add the code to copy items
            break
            
        default:
            return
        }
    }
    
    func refreshPlaylistQueue() {
        if nowPlayingEpisode != nil {
            for section in playlistStructArray {
                if section.episodes.contains(nowPlayingEpisode) {
                    playlistQueue = section.episodes
                    break
                }
            }
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    @objc func handleTap(gesture: UIGestureRecognizer) {
        // convert point from position in self.view to position in warrantiesTableView
        let position = gesture.location(in: tableView)
        
        for section in 0...tableView.numberOfSections-1 {
            let footerView = tableView.footerView(forSection: section)
            
            // nil check for sections that are currently off screen
            if footerView != nil && (footerView?.frame.contains(position))! {
                let unwrappedFooterView = footerView as! PlaylistFooterView
                if playlistStructArray[section].name.isCollapsed {
                    expand(section: section)
                } else {
                    collapse(section: section)
                }
                
                UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: [], animations: {
                    if unwrappedFooterView.collapseExpandButton.transform.isIdentity {
                        unwrappedFooterView.collapseExpandButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                    } else {
                        unwrappedFooterView.collapseExpandButton.transform = .identity
                    }
                }, completion: nil)
                break
            }
        }
    }
    
    func collapse(section: Int) {
        playlistStructArray[section].name.isCollapsed = true
        CoreDataHelper.save(context: managedContext)
        
        let numberOfRows = tableView.numberOfRows(inSection: section)
        var indicesToDelete: [IndexPath] = []
        for row in 1...numberOfRows-1 {
            let indexPath = IndexPath(row: row, section: section)
            indicesToDelete.append(indexPath)
        }
        
        tableView.deleteRows(at: indicesToDelete, with: .fade)
    }
    
    func expand(section: Int) {
        playlistStructArray[section].name.isCollapsed = false
        CoreDataHelper.save(context: managedContext)
        
        let numberOfRows = playlistStructArray[section].episodes.count
        var indicesToAppend: [IndexPath] = []
        for row in 1...numberOfRows {
            let indexPath = IndexPath(row: row, section: section)
            indicesToAppend.append(indexPath)
        }
        
        tableView.insertRows(at: indicesToAppend, with: .fade)
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
    
    @objc func downloadProgress(notification: NSNotification){
        let downloadObject: Download = notification.object as! Download
        
        var section = 0
        var row = 0
        for playlist in playlistStructArray {
            if playlist.episodes.contains(downloadObject.episode!) {
                row = playlist.episodes.index(of: downloadObject.episode!)! + 1
                break
            } else {
                section += 1
            }
        }
        
        DispatchQueue.main.async {
            
            if let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: section)) as? PlaylistCell {
                if cell.activityIndicator.isAnimating {
                    cell.activityIndicator.stopAnimating()
                }
                cell.activityIndicator.isHidden = true
                cell.percentDowloadedLabel.text = "\(Int(downloadObject.percentDown * 100))%"
                cell.percentDowloadedLabel.isHidden = false
                
                if downloadObject.percentDown == 1.0 {
                    cell.percentDowloadedLabel.isHidden = true
                }
            }
        }
    }
    
    @objc func episodeEnded(notification: NSNotification){
        let episodeToRemove = notification.object as! CDEpisode
        
        var rowToDelete: Int?
        var sectionToDelete = 0
        for section in playlistStructArray {
            if section.episodes.contains(episodeToRemove) {
                rowToDelete = section.episodes.index(of: episodeToRemove)
                break
            }
            sectionToDelete += 1
        }
        
        if rowToDelete != nil {
            playlistStructArray[sectionToDelete].episodes.remove(at: rowToDelete!)
            
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                if self.playlistStructArray[sectionToDelete].episodes.count == 0 {
                    self.playlistStructArray.remove(at: sectionToDelete)
                    let indexSet = NSMutableIndexSet()
                    indexSet.add(sectionToDelete)
                    self.tableView.deleteSections(indexSet as IndexSet, with: .fade)
                } else {
                    self.tableView.deleteRows(at: [IndexPath(row: rowToDelete! + 1, section: sectionToDelete)], with: .fade)
                }
                
                self.tableView.endUpdates()
            }
        }
    }
    
    @objc func playNextEpisodeAnimation(notification: NSNotification) {
        var thisSection = 0
        for section in playlistStructArray {
            var thisRow = 0
            for episode in section.episodes {
                if episode == nowPlayingEpisode {
                    if let cell = tableView.cellForRow(at: IndexPath(row: thisRow + 2, section: thisSection)) as? PlaylistCell {
                        nowPlayingCell = cell
                        leftHeightConstraint = nowPlayingCell.leftEQHeightConstraint
                        centerHeightConstraint = nowPlayingCell.centerEQHeightConstraint
                        rightHeightConstraint = nowPlayingCell.rightEQHeightConstraint
                        nowPlayingCell.nowPlayingView.play()
                        startNowPlayingAnimations()
                    }
                }
                thisRow += 1
            }
            thisSection += 1
        }
    }
    
    // MARK: - Preview Delegate Methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // convert point from position in self.view to position in warrantiesTableView
        let cellPosition = tableView.convert(location, from: self.view)
        
        guard let indexPath = tableView.indexPathForRow(at: cellPosition),
            let cell = (tableView.cellForRow(at: indexPath) as? PlaylistCell) else {
                return nil
        }
        
        guard let targetViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "showNotesViewController") as?
            ShowNotesViewController else {
                return nil
        }
        
        var selectedEpisode: CDEpisode!
        if indexPath.row != 0 {
            selectedEpisode = playlistStructArray[indexPath.section].episodes[indexPath.row-1]
        } else {
            return nil
        }
        
        targetViewController.episode = selectedEpisode
        episodeToShowNotesFor = selectedEpisode
        targetViewController.preferredContentSize =
            CGSize(width: 0.0, height: 500)

        previewingContext.sourceRect = view.convert(cell.frame, from: tableView)
        
        return targetViewController
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toShowNotes") {
            
            let showNotesViewController = segue.destination as! ShowNotesViewController
            //you can pass parameters like project id
            showNotesViewController.episode = episodeToShowNotesFor
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
//        present(viewControllerToCommit, animated: true, completion: nil)
        //navigationController!.pushViewController(viewControllerToCommit, animated: true)
        //show(viewControllerToCommit, sender: self)
        performSegue(withIdentifier: "toShowNotes", sender: self)
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType:  NSAttributedString.DocumentType.html], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

