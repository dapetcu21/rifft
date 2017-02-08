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
    
    init(context: inout InitContext) {
        gameState = GameState("oban")
        
        let textureURL = Bundle.main.url(forResource: "Mushroom", withExtension: "png")!
        let testTexture = try! MTKTextureLoader(device: context.device).newTexture(withContentsOf: textureURL, options: [:])
        
        let spritePipeline = Sprite.makePipeline(context: &context)
        noteRenderer = Sprite(pipeline: spritePipeline, texture: testTexture)
    }
    
    func draw(context: RenderContext, projectionMatrix: float4x4, viewMatrix: float4x4) {
        let windowProps = context.windowProps
        
        let aspectRatio = Float(windowProps.width) / Float(windowProps.height)
        let elapsedTime = context.presentationTimestamp - gameState.startTimestamp
        
        
        for note in gameState.notes {
            let noteZ = Float(note.timestamp - elapsedTime)
            
            let modelMatrix = float4x4.makeTranslation(note.x * aspectRatio, note.y, noteZ) *
                float4x4.makeScale(0.001, 0.001, 0.001)
            
            noteRenderer.draw(context: context, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix, modelMatrix: modelMatrix)
        }
    }
}
