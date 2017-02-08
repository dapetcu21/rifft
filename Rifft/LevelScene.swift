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
    var noteRenderer: Sprite
    var gameState: GameState
    var audioManager: AudioManager
    
    init(context: inout InitContext) {
        let textureURL = Bundle.main.url(forResource: "Mushroom", withExtension: "png")!
        let testTexture = try! MTKTextureLoader(device: context.device).newTexture(withContentsOf: textureURL, options: [:])
        
        let spritePipeline = Sprite.makePipeline(context: &context)
        noteRenderer = Sprite(pipeline: spritePipeline, texture: testTexture)
        
        let gameState = GameState("oban")
        self.gameState = gameState
        
        let delay = 2.0
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
        let noteVelocity: Float = 2.0
        
        
        for note in gameState.notes {
            let noteZ = Float(note.timestamp - elapsedTime) * noteVelocity
            
            let modelMatrix = float4x4.makeTranslation(note.x * aspectRatio, note.y, noteZ) *
                float4x4.makeScale(0.001, 0.001, 0.001)
            
            noteRenderer.draw(context: context, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix, modelMatrix: modelMatrix)
        }
    }
}
