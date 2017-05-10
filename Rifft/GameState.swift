//
//  GameState.swift
//  Rifft
//
//  Created by Marius Petcu on 08/02/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import simd
import MetalKit
import GameplayKit

class GameState {
    enum Shield: Int {
        case left = 0, right = 1;
        static let allValues = [left, right]
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
    
    struct ShieldState {
        var position = float2()
        var active: Bool = false
        var timestamp: TimeInterval = 0.0
    }
    var shields = [ShieldState(), ShieldState()]
    static let shieldRadius: Float = 0.5
    
    init(_ levelName: String) {
        startTimestamp = 0.0
//        loadStaticLevel(Bundle.main.url(forResource: levelName, withExtension: "json")!)
        
        let musicUrl = Bundle.main.url(forResource: "oban", withExtension: "mp3")!
        loadGeneratedLevel(musicUrl)
    }
    
    func loadGeneratedLevel(_ url: URL) {
        do {
            self.musicUrl = url
            let onsetList = try getOnsetListFromMusic(url)
            
            var i = 0
            for onset in onsetList {
                i = 1 - i
                let note = Note(
                    timestamp: Double(onset.timestamp),
                    shield: /* GameState.Shield(rawValue: i)!, */ GameState.Shield(rawValue: GKRandomSource.sharedRandom().nextInt(upperBound: 2))!,
                    x: /* 0.0, */ GKRandomSource.sharedRandom().nextUniform() * 2.0 - 1.0,
                    y: /* -1.0 */ GKRandomSource.sharedRandom().nextUniform() * 2.0 - 1.0
                )
                notes.append(note)
            }
        } catch {
            print(error)
        }
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
    
    func testShieldCollision(_ shield: Shield, note: Note) -> Bool {
        let state = shields[shield.rawValue]
        let radiusSquared = GameState.shieldRadius * GameState.shieldRadius
        return state.active && simd.distance_squared(float2(note.x, note.y), state.position) <= radiusSquared
    }
    
    func updateShield(_ shield: Shield, active: Bool, position: float2, timestamp: TimeInterval) {
        let state = ShieldState(position: position, active: active, timestamp: timestamp)
        shields[shield.rawValue] = state
    }
}
