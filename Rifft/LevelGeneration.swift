//
//  LevelGeneration.swift
//  Rifft
//
//  Created by Marius Petcu on 25/06/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import GameplayKit
import simd

let velocity: Float = 1.5
let modeChangeRate: Float = 0.75 // Chance to change per second
let resetRate: Float = 0.5 // Chance to reset position
let forceStrength: Float = 5.0

func linearToTanSpace(_ vec: float2) -> float2 {
    return float2(
        tan(vec.x * Float.pi * 0.5) * 0.5,
        tan(vec.y * Float.pi * 0.5) * 0.5
    )
}

func tanToLinearSpace(_ vec: float2) -> float2 {
    return float2(
        atan(vec.x * 2.0) * (2.0 / Float.pi),
        atan(vec.y * 2.0) * (2.0 / Float.pi)
    )
}

enum GenerationModes {
    case left
    case right
    case symmetryFull
}
let allGenerationModes: [GenerationModes] = [.left, .right, .symmetryFull]

func generateNotesFromOnsets(_ onsets: [Onset]) -> [GameState.Note] {
    var notes: [GameState.Note] = []
    
    let rng = GKRandomSource.sharedRandom()
    
    var lastTime: Double = 0.0
    var lastPosition: float2 = float2(Float.nan, Float.nan)
    var lastDirection: float2 = float2(Float.nan, Float.nan)
    var mode: GenerationModes = .left
    var symmetryTick: Int = 0
    
    for onset in onsets {
        let t = onset.timestamp
        let dt = t - lastTime
        
        var position: float2
        var direction: float2
        
        if rng.nextUniform() <= 1.0 - pow((1.0 - modeChangeRate), Float(dt)) {
            mode = allGenerationModes[rng.nextInt(upperBound: allGenerationModes.count)]
            
            if rng.nextUniform() <= resetRate {
                lastPosition = float2(Float.nan, Float.nan)
                lastDirection = float2(Float.nan, Float.nan)
            }
        }
        
        if lastPosition.x.isNaN {
            position = float2(rng.nextUniform() * 2.0 - 1.0, rng.nextUniform() * 2.0 - 1.0)
            direction = vector_normalize(float2(rng.nextUniform() * 2.0 - 1.0, rng.nextUniform() * 2.0 - 1.0)) * velocity
        } else {
            let force = float2(-pow(lastPosition.x, 5.0), -pow(lastPosition.y, 5.0))
            direction = lastDirection + force * Float(dt) * forceStrength
            
            let delta = direction * Float(dt)
            position = tanToLinearSpace(linearToTanSpace(lastPosition) + delta)
            
        }
        
        lastTime = t
        lastPosition = position
        lastDirection = direction
        
        func makeNote(_ note: GameState.Shield, _ pos: float2) {
            notes.append(GameState.Note(
                timestamp: t,
                shield: note,
                x: (pos.x * 0.5 - 0.5) * (note == .left ? 1.0 : -1.0),
                y: note == .left ? pos.y : -pos.y
            ))
        }
        
        switch mode {
        case .left:
            makeNote(.left, position)
        case .right:
            makeNote(.right, position)
        case .symmetryFull:
            symmetryTick = 1 - symmetryTick
            makeNote(GameState.Shield(rawValue: symmetryTick)!, position)
        }
        
    }

    return notes
}
