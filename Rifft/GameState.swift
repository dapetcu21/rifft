//
//  GameState.swift
//  Rifft
//
//  Created by Marius Petcu on 08/02/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation

class GameState {
    enum Shield: Int {
        case left = 0, right = 1;
    }
    
    struct Note {
        var timestamp: Double
        var shield: Shield
        var x: Float
        var y: Float
    }
    
    var notes: [Note] = []
    var musicUrl: URL!
    var startTimestamp: TimeInterval
    
    init(_ levelName: String) {
        startTimestamp = Date().timeIntervalSince1970
        loadStaticLevel(Bundle.main.url(forResource: levelName, withExtension: "json")!)
    }
    
    func loadStaticLevel(_ url: URL) {
        var json: Dictionary<String, Any>?
        do {
            let jsonData = try Data(contentsOf: url)
            json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions()) as? Dictionary<String, Any>
        } catch {
            print(error)
        }
        
        if json != nil {
            if let musicPath = json!["music"] as? String {
                musicUrl = Bundle.main.resourceURL!.appendingPathComponent(musicPath)
            }
            if let notesDesc = json!["notes"] as? Array<Array<Double>> {
                for noteDesc in notesDesc {
                    let note = Note(
                        timestamp: noteDesc[0],
                        shield: GameState.Shield(rawValue: Int(noteDesc[1]))!,
                        x: Float(noteDesc[2]),
                        y: Float(noteDesc[3])
                    )
                    notes.append(note)
                }
            }
        }
    }
}
