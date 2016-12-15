//
//  SpeakersViewModel.swift
//  codemash
//
//  Created by Kim Arnett on 10/15/16.
//  Copyright © 2016 karnett. All rights reserved.
//

import Foundation

class SpeakersViewModel {
    var rest: RestController!
    var coreData: CoreDataController!
    
    var speakers: [SpeakerObj] = []
    var filtered: [SpeakerObj] = []
    
    var isFiltering = false
    var loadingSpeakers = false
    
    let prefs = UserDefaults.standard
    let updateKey = "speakerServerUpdate"

    init(rest: RestController, coreData: CoreDataController) {
        self.rest = rest
        self.coreData = coreData
    }
    
    func loadSpeakers() {
        self.speakers = self.coreData.getSpeakers()
        
        let needToLoad: Bool = (speakers.count == 0 && !loadingSpeakers)
        
        let dateRefreshed = self.getLastUpdateFromServer()
        let needToRefresh: Bool = (dateRefreshed == nil || numOfDays(first: dateRefreshed!, second: Date()) > 0)
        
        if needToLoad || needToRefresh {
            loadingSpeakers = true
            requestSpeakers()
        }
    }
    
    func requestSpeakers() {
        //move to core data
        self.rest.loadSpeakers(completionHandler: { result in
            
            switch result {
                
            case .success(let data):
                
                for entry in data {
                    self.coreData.saveSpeaker(json: entry)
                }
                self.setLastUpdateFromServer()
                
                self.speakers = self.coreData.getSpeakers()
                
                //send notification to reload table
                NotificationCenter.default.post(name: NotificationName.speakersLoaded, object: nil)

            case .failure(let error):
                //alert
                print(error)
            }
            
            
            
            self.loadingSpeakers = false
            
            
        })
    }
    
    func numOfDays(first: Date, second: Date) -> Int {
        let calendar = Calendar.current
        
        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: first)
        let date2 = calendar.startOfDay(for: second)
        
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        
        
        return components.day ?? 5 //default needs to be more than 1
    }
    
    func setLastUpdateFromServer() {
        prefs.set(Date(), forKey: updateKey)
    }
    
    func getLastUpdateFromServer() -> Date? {
        return prefs.object(forKey: updateKey) as? Date ?? nil
    }
    
    func numberOfRowsInSection(section: Int) -> Int {
        
        if isFiltering {
            return filtered.count
        }
        
        return speakers.count
    }
    
    func getSpeakerAtIndex(row: Int) -> SpeakerObj? {
        if isFiltering && row < filtered.count {
            return filtered[row]
            
        }
        if !isFiltering && row < speakers.count {
            return speakers[row]
        }
        return nil
    }
    
    func getSessionsForSpeaker(id: String) -> [SessionObj] {
        return []
        //return self.coreData.getSessionsForSpeaker(id: id)
    }
    
    func filterSpeakers(text: String)
    {
        filtered = speakers.filter { speaker in
            let first = speaker.firstName?.lowercased() ?? ""
            let last = speaker.lastName?.lowercased() ?? ""
            
            return first.contains(text.lowercased()) || last.contains(text.lowercased())
        }
    }
}
