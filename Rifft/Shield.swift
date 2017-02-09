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
    
    static func makePipeline(context: InitContext) -> MTLRenderPipelineState {
        let device = context.device
        let windowProps = context.windowProps
        
        let fragmentProgram = context.functionCache.getFunction(name: "noteFragment")
        let vertexProgram = context.functionCache.getFunction(name: "noteVertex")
        
        let spritePipelineDescriptor = MTLRenderPipelineDescriptor()
        spritePipelineDescriptor.vertexFunction = vertexProgram
        spritePipelineDescriptor.fragmentFunction = fragmentProgram
        spritePipelineDescriptor.colorAttachments[0].pixelFormat = windowProps.colorPixelFormat
        spritePipelineDescriptor.sampleCount = windowProps.sampleCount
        spritePipelineDescriptor.depthAttachmentPixelFormat = windowProps.depthPixelFormat
        
        return try! device.makeRenderPipelineState(descriptor: spritePipelineDescriptor)
    }
    
    init(pipeline: MTLRenderPipelineState) {
        let longitudeSegments = 20
        let latitudeSegments = 10
        
        var vertexData: [Float] = []
        var indexData: [Int16] = []
        var currentVertex: Int16 = 0
        
        for i in 0...latitudeSegments {
            let omega: Float = Float(i) * (Float(M_PI) / Float(latitudeSegments)) - Float(M_PI_2)
            let sinOmega = sinf(omega)
            let cosOmega = cosf(omega)
            
            if i > 1 {
                // Add a break in the triangle strip
                indexData += [ indexData.last!, currentVertex ]
            }
            
            for j in 0...longitudeSegments {
                let alpha: Float = Float(j) * (2.0 * Float(M_PI) / Float(longitudeSegments))
                let sinAlpha = sinf(alpha)
                let cosAlpha = cosf(alpha)
                let vertex = float3(
                    cosOmega * cosAlpha,
                    cosOmega * sinAlpha,
                    sinOmega
                ) * Note.sphereRadius
                
                vertexData += [vertex.x, vertex.y, vertex.z]
                if i != 0 {
                    indexData += [ currentVertex, currentVertex - longitudeSegments - 1 ]
                }
                currentVertex += 1
            }
        }
        indexCount = indexData.count
        
        let device = pipeline.device
        
        self.vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        self.indexBuffer = device.makeBuffer(bytes: indexData, length: indexData.count * MemoryLayout<Int16>.size, options: [])
        self.pipeline = pipeline
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthDescriptor.isDepthWriteEnabled = true
        self.depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }
    
    func draw(context: RenderContext, color: float4, projectionMatrix: float4x4, viewMatrix: float4x4, modelMatrix: float4x4) {
        let commandEncoder = context.commandEncoder
        
        struct Uniforms {
            var mvpMatrix: float4x4
            var color: float4
        }
        
        let uniforms = Uniforms(
            mvpMatrix: projectionMatrix * viewMatrix * modelMatrix,
            color: color
        )
        let uniformBuffer = context.constantBufferPool.createBuffer(data: uniforms)
        
        commandEncoder.setRenderPipelineState(pipeline)
        commandEncoder.setDepthStencilState(depthState)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
        commandEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: 0)
        commandEncoder.drawIndexedPrimitives(type: MTLPrimitiveType.triangleStrip, indexCount: indexCount, indexType: MTLIndexType.uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }
}
