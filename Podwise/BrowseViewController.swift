//
//  BrowseViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class BrowseViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        iTunesSearch(term: searchBar.text!)
    }
    
    //
    func iTunesSearch (term: String) {
        // replace spaces with + symbol.
        let iTunesTerm = term.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.caseInsensitive, range: nil)
        // anything that is URL friendly should be escaped
        let escapedTerm = iTunesTerm.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        //stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let path = "https://itunes.apple.com/search?term=\(escapedTerm ?? "")&media=podcast"
        let url: URL = URL(string: path)!
        let request: URLRequest = URLRequest(url: url)//NSURLRequest(URL: url as URL)
        let session: URLSession = URLSession.shared // NSURLConnection(request: rqst, delegate: self, startImmediately: false)!
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
        })
        print("URL for searching iTunes API \(url)")
        task.resume()
    }
    

    func ctnFinishedLoading(data: Data) {
        // self.d should hold the resulting info, request is complete
        // received data is converted into an object through JSON deserialization
        do {
            let jResult: Dictionary<String, Any> = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, Any>
            if jResult.count > 0 {
                let results = jResult["results"] as? [[String: Any]]
                if results!.count > 0 {
                    var results: NSArray = jResult["results"] as! NSArray
                    self.tData = results
                    self.appsTableView.reloadData()
                }
            }
        } catch {
            
        }
    }
    
    Read more at http://technotif.com/connect-your-apps-to-itunes-search-api/#fC7VuBhzWqR8IcLe.99
}
