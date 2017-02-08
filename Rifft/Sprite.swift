//
//  Sprite.swift
//  Rifft
//
//  Created by Marius Petcu on 08/02/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import Metal
import simd

class Sprite {
    var vertexBuffer: MTLBuffer
    var indexBuffer: MTLBuffer
    var texture: MTLTexture
    var spritePipeline: MTLRenderPipelineState
    
    init(device: MTLDevice, windowProps: WindowProperties, texture: MTLTexture) {
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
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "spriteFragment")!
        let vertexProgram = defaultLibrary.makeFunction(name: "spriteVertex")!
        
        let spritePipelineDescriptor = MTLRenderPipelineDescriptor()
        spritePipelineDescriptor.vertexFunction = vertexProgram
        spritePipelineDescriptor.fragmentFunction = fragmentProgram
        spritePipelineDescriptor.colorAttachments[0].pixelFormat = windowProps.colorPixelFormat
        spritePipelineDescriptor.sampleCount = windowProps.sampleCount
        
        spritePipeline = try! device.makeRenderPipelineState(descriptor: spritePipelineDescriptor)
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
        
        commandEncoder.setRenderPipelineState(spritePipeline)
        commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, at: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
        commandEncoder.setFragmentTexture(texture, at: 0)
        commandEncoder.drawIndexedPrimitives(type: MTLPrimitiveType.triangle, indexCount: 6, indexType: MTLIndexType.uint16, indexBuffer: self.indexBuffer, indexBufferOffset: 0)
    }
}
