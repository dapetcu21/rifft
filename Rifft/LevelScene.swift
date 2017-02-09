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
    var gridRenderer: BackgroundGrid
    var gameState: GameState
    var audioManager: AudioManager
    
    init(context: inout InitContext) {
        let notePipeline = Note.makePipeline(context: &context)
        noteRenderer = Note(pipeline: notePipeline)
        
        let gridPipeline = BackgroundGrid.makePipeline(context: &context)
        gridRenderer = BackgroundGrid(pipeline: gridPipeline, windowProps: context.windowProps)
        
        let gameState = GameState("oban")
        self.gameState = gameState
        
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
    
    func draw(context: RenderContext, projectionMatrix: float4x4, viewMatrix: float4x4) {
        let windowProps = context.windowProps
        
        let aspectRatio = Float(windowProps.width) / Float(windowProps.height)
        let elapsedTime = context.presentationTimestamp - gameState.startTimestamp
        let noteVelocity: Float = 4.0
        
        gridRenderer.draw(
            context: context,
            projectionMatrix: projectionMatrix,
            viewMatrix: viewMatrix,
            modelMatrix: float4x4(diagonal: float4(1.0))
        )
        
        for note in gameState.notes {
            let noteZ = Float(note.timestamp - elapsedTime) * noteVelocity
            
            let modelMatrix = float4x4.makeTranslation(note.x * aspectRatio, note.y, noteZ)
            
            
            let color = note.shield == .left ? float4(1.0, 0.0, 0.0, 1.0) : float4(0.0, 0.0, 1.0, 1.0)
            
            noteRenderer.draw(
                context: context,
                color: color,
                projectionMatrix: projectionMatrix,
                viewMatrix: viewMatrix,
                modelMatrix: modelMatrix
            )
        }
    }
}
