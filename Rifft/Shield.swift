//
//  Note.swift
//  Rifft
//
//  Created by Marius Petcu on 08/02/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import Metal
import simd

class Shield {
    var vertexBuffer: MTLBuffer
    var indexBuffer: MTLBuffer
    var pipeline: MTLRenderPipelineState
    var depthState: MTLDepthStencilState
    var indexCount: Int
    
    static let sphereRadius: Float = 0.3
    
    static func makePipeline(_ context: InitContext) -> MTLRenderPipelineState {
        let device = context.device
        let windowProps = context.windowProps
        
        let fragmentProgram = context.functionCache.getFunction("noteFragment")
        let vertexProgram = context.functionCache.getFunction("noteVertex")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexProgram
        pipelineDescriptor.fragmentFunction = fragmentProgram
        pipelineDescriptor.sampleCount = windowProps.sampleCount
        pipelineDescriptor.depthAttachmentPixelFormat = windowProps.depthPixelFormat
        
        let renderbufferAttachment = pipelineDescriptor.colorAttachments[0]!
        renderbufferAttachment.pixelFormat = windowProps.colorPixelFormat
        renderbufferAttachment.isBlendingEnabled = true
        renderbufferAttachment.rgbBlendOperation = .add
        renderbufferAttachment.alphaBlendOperation = .add
        renderbufferAttachment.sourceRGBBlendFactor = .sourceAlpha
        renderbufferAttachment.sourceAlphaBlendFactor = .sourceAlpha
        renderbufferAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderbufferAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        return try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    init(pipeline: MTLRenderPipelineState) {
        let longitudeSegments = 40
        
        var vertexData: [Float] = [0.0, 0.0, 0.0]
        var indexData: [Int16] = []
        var currentVertex: Int16 = 1
        
        for i in 0...longitudeSegments {
            let alpha: Float = Float(i) * (2.0 * Float(M_PI) / Float(longitudeSegments))
            let vertex = float3(sinf(alpha), cosf(alpha), 0.0)
            let outVertex = vertex * GameState.shieldRadius
            let inVertex = vertex * (GameState.shieldRadius - 0.1)
            
            vertexData += [
                outVertex.x, outVertex.y, outVertex.z,
                inVertex.x, inVertex.y, inVertex.z
            ]
            indexData += [currentVertex, 0]
            currentVertex += 2
        }
        indexData += [0, 1]
        for i in 0...longitudeSegments {
            indexData += [Int16(i * 2 + 1), Int16(i * 2 + 2)]
        }
        indexCount = indexData.count
        
        let device = pipeline.device
        
        self.vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        self.indexBuffer = device.makeBuffer(bytes: indexData, length: indexData.count * MemoryLayout<Int16>.size, options: [])
        self.pipeline = pipeline
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = MTLCompareFunction.always
        depthDescriptor.isDepthWriteEnabled = false
        self.depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }
    
    func draw(_ context: RenderContext, color: float4, projectionMatrix: float4x4, viewMatrix: float4x4, modelMatrix: float4x4) {
        let commandEncoder = context.commandEncoder
        
        struct Uniforms {
            var mvpMatrix: float4x4
            var color: float4
        }
        
        let uniforms = Uniforms(
            mvpMatrix: projectionMatrix * viewMatrix * modelMatrix,
            color: color
        )
        let uniformBuffer = context.constantBufferPool.createBuffer(uniforms)
        
        commandEncoder.setRenderPipelineState(pipeline)
        commandEncoder.setDepthStencilState(depthState)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
        commandEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: 0)
        commandEncoder.drawIndexedPrimitives(type: MTLPrimitiveType.triangleStrip, indexCount: indexCount, indexType: MTLIndexType.uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }
}
