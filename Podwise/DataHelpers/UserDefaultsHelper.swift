//
//  UserDefaultsHelper.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2017-04-12.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation

let defaults = UserDefaults.standard

class UserDefaultsHelper {
    
    // Delete episode when completed listening
    // Get
    static func getDeleteAfterEpisodeFinishes() -> Bool {
        if let toDelete = defaults.object(forKey: "deleteAfterPlayed") as? Bool {
            return toDelete
        }
        return true
    }
    // Set
    static func setDeleteAfterEpisodeFinishes(to: Bool) {
        defaults.set(to, forKey: "deleteAfterPlayed")
    }
    
    // Delete episode when completed listening
    // Get
    static func getAutoPlayNextEpisode() -> Bool {
        if let toDelete = defaults.object(forKey: "autoPlay") as? Bool {
            return toDelete
        }
        return true
    }
    // Set
    static func setAutoPlayNextEpisode(to: Bool) {
        defaults.set(to, forKey: "autoPlay")
    }
}
