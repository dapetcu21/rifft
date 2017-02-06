//
//  LevelScene.swift
//  Rifft
//
//  Created by Marius Petcu on 19/01/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import MetalKit

class Sprite {
    var vertexBuffer: MTLBuffer
    var indexBuffer: MTLBuffer
    var texture: MTLTexture
    
    
    init(device: MTLDevice, texture: MTLTexture) {
        let halfW = Float(texture.width) * 0.5
        let halfH = Float(texture.height) * 0.5
        
        let vertexData: [Float] = [
            -halfW, -halfH, 0,  0, 1,
            halfW, -halfH, 0,   1, 1,
            -halfW, halfH, 0,   0, 0,
            halfW, halfH, 0,    1, 0
        ]
        let indexData: [Int16] = [
            0, 1, 3,
            0, 3, 2
        ]
        
        self.vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        self.indexBuffer = device.makeBuffer(bytes: indexData, length: indexData.count * MemoryLayout<Int16>.size, options: [])
        self.texture = texture
    }
    
    func draw(context: RenderContext, projectionMatrix: float4x4, viewMatrix: float4x4, modelMatrix: float4x4) {
        let commandEncoder = context.commandEncoder
        
        struct SpriteUniforms {
            var projectionMatrix: float4x4
            var viewMatrix: float4x4
            var modelMatrix: float4x4
        }
        
        
        let uniforms = SpriteUniforms(
            projectionMatrix: projectionMatrix,
            viewMatrix: viewMatrix,
            modelMatrix: modelMatrix
        )
        let uniformBuffer = context.constantBufferPool.createBuffer(data: uniforms)
        
        commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, at: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
        commandEncoder.setFragmentTexture(texture, at: 0)
        commandEncoder.drawIndexedPrimitives(type: MTLPrimitiveType.triangle, indexCount: 6, indexType: MTLIndexType.uint16, indexBuffer: self.indexBuffer, indexBufferOffset: 0)
    }
}

class LevelScene {
    var spritePipeline: MTLRenderPipelineState
    var testSprite: Sprite
    
    init(device: MTLDevice, windowProps: WindowProperties) {
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "spriteFragment")!
        let vertexProgram = defaultLibrary.makeFunction(name: "spriteVertex")!
        
        let spritePipelineDescriptor = MTLRenderPipelineDescriptor()
        spritePipelineDescriptor.vertexFunction = vertexProgram
        spritePipelineDescriptor.fragmentFunction = fragmentProgram
        spritePipelineDescriptor.colorAttachments[0].pixelFormat = windowProps.colorPixelFormat
        spritePipelineDescriptor.sampleCount = windowProps.sampleCount
        
        spritePipeline = try! device.makeRenderPipelineState(descriptor: spritePipelineDescriptor)
        
        let textureURL = Bundle.main.url(forResource: "Mushroom", withExtension: "png")!
        let testTexture = try! MTKTextureLoader(device: device).newTexture(withContentsOf: textureURL, options: [:])
        testSprite = Sprite(device: device, texture: testTexture)
    }
    
    func draw(context: RenderContext, projectionMatrix: float4x4, viewMatrix: float4x4) {
        let commandEncoder = context.commandEncoder
        let windowProps = context.windowProps
        
        let modelMatrix = float4x4.makeTranslation(
            Float(windowProps.width) * 0.5,
            Float(windowProps.height) * 0.5,
            0
        ) * float4x4.makeScale(0.5, 0.5, 0.5)
        
        commandEncoder.setRenderPipelineState(spritePipeline)
        testSprite.draw(context: context, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix, modelMatrix: modelMatrix)
    }
}
