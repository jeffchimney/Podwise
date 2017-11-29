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

class PlaylistsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct PlaylistEpisodes {
        var name : String!
        var episodes : [CDEpisode]
    }

    var podcasts: [CDPodcast] = []
    var episodes: [CDEpisode] = []
    var misfitEpisodes: [CDEpisode] = []
    var playlists: [CDPlaylist] = []
    var episodesForPlaylists: [String: [CDEpisode]] = [String: [CDEpisode]]()
    var playlistStructArray = [PlaylistEpisodes]()
    var managedContext: NSManagedObjectContext?
    //var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        managedContext = appDelegate.persistentContainer.viewContext
        
        misfitEpisodes = CoreDataHelper.getAllEpisodesWithNoPlaylist(in: managedContext!)
        playlists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
        
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
        return playlists.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 260
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath as IndexPath) as! GroupedViewCell
        
        cell.playlistGroupTableView.register(UINib(nibName: "PlaylistCell", bundle: Bundle.main), forCellReuseIdentifier: "PlaylistCell")
        cell.playlistGroupTableView.frame = cell.bounds
        cell.playlistGroupTableView.playlist = playlists[indexPath.section]
        cell.playlistGroupTableView.loadPlaylist()
        
        cell.layer.cornerRadius = 15
        cell.layer.masksToBounds = true
        
        return cell
    }
    
//    func tableView(_ tableView: UITableView,
//                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
//    {
//        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
//            print("Update action ...")
//            success(true)
//        })
//
//        let deleteEpisodeAction = UIContextualAction(style: .destructive, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
//            print("Delete action ...")
//            var cdEpisode: [CDEpisode]
//            if self.episodes.count > 0 {
//                if indexPath.section == 0 {
//                    cdEpisode = CoreDataHelper.getEpisodeWith(id: self.episodes[indexPath.row].id!, in: self.managedContext!)
//                } else {
//                    cdEpisode = CoreDataHelper.getEpisodeWith(id: self.playlistStructArray[indexPath.section-1].episodes[indexPath.row].id!, in: self.managedContext!)
//                }
//            } else {
//                cdEpisode = CoreDataHelper.getEpisodeWith(id: self.playlistStructArray[indexPath.section].episodes[indexPath.row].id!, in: self.managedContext!)
//            }
//            if cdEpisode.count > 0 {
//                do {
//                    let filemanager = FileManager.default
//                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
//                    let destinationPath = documentsPath.appendingPathComponent(cdEpisode[0].localURL!.lastPathComponent)
//                    if filemanager.fileExists(atPath: destinationPath) {
//                        try! filemanager.removeItem(atPath: destinationPath)
//                        tableView.beginUpdates()
//                        CoreDataHelper.delete(episode: cdEpisode[0], in: self.managedContext!)
//                        if self.episodes.count > 0 {
//                            self.playlistStructArray[indexPath.section-1].episodes.remove(at: indexPath.row)
//                        } else {
//                            self.playlistStructArray[indexPath.section].episodes.remove(at: indexPath.row)
//                        }
//                        tableView.deleteRows(at: [indexPath], with: .automatic)
//                        tableView.endUpdates()
//                    } else {
//                        print("not deleted, couldnt find file.")
//                    }
//                }
//            }
//            success(true)
//        })
//
//        deleteEpisodeAction.image = UIImage(named: "trash")
//        deleteEpisodeAction.backgroundColor = .red
//
//        addToPlaylistAction.image = UIImage(named: "playlist")
//        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
//
//        return UISwipeActionsConfiguration(actions: [deleteEpisodeAction, addToPlaylistAction])
//    }
    
//    func runTimer() {
//        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(checkDownloads)), userInfo: nil, repeats: true)
//    }
//
//    @objc func checkDownloads() {
//        tableView.reloadData()
//    }
    
    @IBAction func addPlaylistButtonPressed(_ sender: Any) {
        tableView.reloadData()
    }
    
}

