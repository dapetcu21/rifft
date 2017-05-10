//
//  LevelScene.swift
//  Rifft
//
//  Created by Marius Petcu on 19/01/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import MetalKit

class LevelScene {
    var noteRenderer: Note
    var shieldRenderer: Shield
    var gridRenderer: BackgroundGrid
    var gameState: GameState
    var audioManager: AudioManager
    var touchRecognizer: TouchRecognizer
    
    init(context: InitContext) {
        let notePipeline = Note.makePipeline(context)
        noteRenderer = Note(pipeline: notePipeline)
        
        let shieldPipeline = Shield.makePipeline(context)
        shieldRenderer = Shield(pipeline: shieldPipeline)
        
        let gridPipeline = BackgroundGrid.makePipeline(context)
        gridRenderer = BackgroundGrid(pipeline: gridPipeline, windowProps: context.windowProps)
        
        let gameState = GameState("oban")
        self.gameState = gameState
        
        touchRecognizer = TouchRecognizer(gameState: gameState, target: nil, action: nil)
        context.view.addGestureRecognizer(touchRecognizer)
        
        let delay = 5.0
        gameState.startTimestamp = CACurrentMediaTime() + delay
        
        audioManager = AudioManager(
            url: gameState.musicUrl,
            delay: delay,
            preloadHandler: { (startTime: TimeInterval) in
                gameState.startTimestamp = startTime
            }
        )
    }
    
    func draw(_ context: RenderContext, projectionMatrix: float4x4, viewMatrix: float4x4) {
        let windowProps = context.windowProps
        
        let aspectRatio = Float(windowProps.width) / Float(windowProps.height)
        let elapsedTime = context.presentationTimestamp - gameState.startTimestamp
        let noteVelocity: Float = 10.0
        
        gridRenderer.draw(
            context,
            projectionMatrix: projectionMatrix,
            viewMatrix: viewMatrix,
            modelMatrix: float4x4(diagonal: float4(1.0))
        )
        
        for note in gameState.notes {
            let noteZ = Float(note.timestamp - elapsedTime) * noteVelocity
            if noteZ < -Note.sphereRadius || noteZ > 20.0 + Note.sphereRadius {
                continue
            }
            
            let modelMatrix = float4x4.makeTranslation(note.x * aspectRatio, note.y, noteZ)
            
            var color = note.shield == .left ? float4(1.0, 0.0, 0.0, 1.0) : float4(0.0, 0.0, 1.0, 1.0)
            
            let lightUpDistance = Note.sphereRadius * 4.0
            
            if noteZ < lightUpDistance && gameState.testShieldCollision(note.shield, note: note) {
                let alpha: Float = max(0.0, noteZ / lightUpDistance)
                color = mix(float4(1.0, 1.0, 1.0, 1.0), color, t: alpha)
            }
            
            noteRenderer.draw(
                context,
                color: color,
                projectionMatrix: projectionMatrix,
                viewMatrix: viewMatrix,
                modelMatrix: modelMatrix
            )
        }
        
        for shield in GameState.Shield.allValues {
            let state = gameState.shields[shield.rawValue]
            if !state.active { continue }
            
            let modelMatrix = float4x4.makeTranslation(state.position.x * aspectRatio, state.position.y, 0.0)
            
            let color = shield == .left ? float4(1.0, 0.0, 0.0, 0.5) : float4(0.0, 0.0, 1.0, 0.5)
            
            shieldRenderer.draw(
                context,
                color: color,
                projectionMatrix: projectionMatrix,
                viewMatrix: viewMatrix,
                modelMatrix: modelMatrix
            )
        }
    }
}
