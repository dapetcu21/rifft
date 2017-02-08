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
    var testSprite: Sprite
    var gameState: GameState
    
    init(device: MTLDevice, windowProps: WindowProperties) {
        gameState = GameState("oban")
        
        let textureURL = Bundle.main.url(forResource: "Mushroom", withExtension: "png")!
        let testTexture = try! MTKTextureLoader(device: device).newTexture(withContentsOf: textureURL, options: [:])
        testSprite = Sprite(device: device, windowProps: windowProps, texture: testTexture)
    }
    
    func draw(context: RenderContext, projectionMatrix: float4x4, viewMatrix: float4x4) {
        let windowProps = context.windowProps
        
        let modelMatrix = float4x4.makeTranslation(
            Float(windowProps.width) * 0.5,
            Float(windowProps.height) * 0.5,
            0
        ) * float4x4.makeScale(0.5, 0.5, 0.5)
        
        testSprite.draw(context: context, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix, modelMatrix: modelMatrix)
    }
}
