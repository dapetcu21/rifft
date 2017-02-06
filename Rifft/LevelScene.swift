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
    var uniformBuffer: MTLBuffer
    var uniformBufferRotation: Int = 4
    var uniformBufferIndex: Int = 0
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
        self.uniformBuffer = device.makeBuffer(length: self.uniformBufferRotation * 256, options: [])
        self.texture = texture
    }
    
    func draw(commandEncoder: MTLRenderCommandEncoder, projectionMatrix: Matrix4, viewMatrix: Matrix4, modelMatrix: Matrix4) {
        let uniformIndex = self.uniformBufferIndex
        let matrixSize = 16 * MemoryLayout<Float>.size
        let uniformOffset = 256
        let uniformMemory = self.uniformBuffer.contents() + uniformIndex * uniformOffset
        memcpy(uniformMemory, projectionMatrix.toArray(), matrixSize)
        memcpy(uniformMemory + matrixSize, viewMatrix.toArray(), matrixSize)
        memcpy(uniformMemory + 2 * matrixSize, modelMatrix.toArray(), matrixSize)
        self.uniformBufferIndex = (uniformIndex + 1) % self.uniformBufferRotation
        
        commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, at: 0)
        commandEncoder.setVertexBuffer(self.uniformBuffer, offset: uniformOffset * uniformIndex, at: 1)
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
    
    func draw(commandEncoder: MTLRenderCommandEncoder, windowProps: WindowProperties, projectionMatrix: Matrix4, viewMatrix: Matrix4) {
        let modelMatrix = Matrix4(translation: Vector3(
            Float(windowProps.width) * 0.5,
            Float(windowProps.height) * 0.5,
            0
        )) * Matrix4(scale: Vector3(0.5, 0.5, 0.5))
        
        commandEncoder.setRenderPipelineState(spritePipeline)
        testSprite.draw(commandEncoder: commandEncoder, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix, modelMatrix: modelMatrix)
    }
}
