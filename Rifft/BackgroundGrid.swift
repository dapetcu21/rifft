//
//  BackgroundGrid.swift
//  Rifft
//
//  Created by Marius Petcu on 08/02/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import Metal
import simd
import QuartzCore

class BackgroundGrid {
    var vertexBuffer: MTLBuffer
    var indexBuffer: MTLBuffer
    var pipeline: MTLRenderPipelineState
    var depthState: MTLDepthStencilState
    var indexCount: Int
    var startTime: Double
    
    static func makePipeline(context: InitContext) -> MTLRenderPipelineState {
        let device = context.device
        let windowProps = context.windowProps
        
        let fragmentProgram = context.functionCache.getFunction(name: "gridFragment")
        let vertexProgram = context.functionCache.getFunction(name: "gridVertex")
        
        let spritePipelineDescriptor = MTLRenderPipelineDescriptor()
        spritePipelineDescriptor.vertexFunction = vertexProgram
        spritePipelineDescriptor.fragmentFunction = fragmentProgram
        spritePipelineDescriptor.colorAttachments[0].pixelFormat = windowProps.colorPixelFormat
        spritePipelineDescriptor.sampleCount = windowProps.sampleCount
        spritePipelineDescriptor.depthAttachmentPixelFormat = windowProps.depthPixelFormat
        
        return try! device.makeRenderPipelineState(descriptor: spritePipelineDescriptor)
    }
    
    static let depth: Float = 10.0
    
    init(pipeline: MTLRenderPipelineState, windowProps: WindowProperties) {
        let aspect = Float(windowProps.width) / Float(windowProps.height)
        let halfW: Float = 1.5 * aspect
        let halfH: Float = 1.5
        let depth: Float = BackgroundGrid.depth
        
        let heightSegments = 4
        let widthSegments = Int(roundf(Float(heightSegments) * aspect))
        let depthSegments = 10
        let lineHalfWidth: Float = 2.0
        
        var vertexData: [Float] = []
        var indexData: [Int16] = []
        var currentVertex: Int16 = 0
        
        func drawLine(from: float3, to: float3) {
            let direction = simd.normalize(to - from)
            vertexData += [
                from.x, from.y, from.z, direction.x, direction.y, direction.z,
                from.x, from.y, from.z, -direction.x, -direction.y, -direction.z,
                to.x, to.y, to.z, direction.x, direction.y, direction.z,
                to.x, to.y, to.z, -direction.x, -direction.y, -direction.z
            ]
            indexData += [
                currentVertex, currentVertex + 1, currentVertex + 2,
                currentVertex + 2, currentVertex + 1, currentVertex + 3
            ]
            currentVertex += 4
        }
        
        for i in 0...widthSegments {
            let x = Float(i) * (halfW * 2.0 / Float(widthSegments)) - halfW
            drawLine(from: float3(x, halfH, 0),
                     to: float3(x, halfH, depth))
            drawLine(from: float3(x, -halfH, 0),
                     to: float3(x, -halfH, depth))
        }
        
        for i in 1..<heightSegments {
            let y = Float(i) * (halfH * 2.0 / Float(heightSegments)) - halfH
            drawLine(from: float3(halfW, y, 0),
                     to: float3(halfW, y, depth))
            drawLine(from: float3(-halfW, y, 0),
                     to: float3(-halfW, y, depth))
        }
        
        for i in 1...depthSegments {
            let z = Float(i) * (depth / Float(depthSegments))
            drawLine(from: float3(-halfW, -halfH, z),
                     to: float3(-halfW, halfH, z))
            drawLine(from: float3(halfW, -halfH, z),
                     to: float3(halfW, halfH, z))
            drawLine(from: float3(-halfW, -halfH, z),
                     to: float3(halfW, -halfH, z))
            drawLine(from: float3(-halfW, halfH, z),
                     to: float3(halfW, halfH, z))
        }
        
        indexCount = indexData.count
        startTime = CACurrentMediaTime()
        
        let device = pipeline.device
        
        self.vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        self.indexBuffer = device.makeBuffer(bytes: indexData, length: indexData.count * MemoryLayout<Int16>.size, options: [])
        self.pipeline = pipeline
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = MTLCompareFunction.less
        depthDescriptor.isDepthWriteEnabled = true
        self.depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }
    
    func draw(context: RenderContext, projectionMatrix: float4x4, viewMatrix: float4x4, modelMatrix: float4x4) {
        let commandEncoder = context.commandEncoder
        
        struct GridUniforms {
            var mvpMatrix: float4x4
            var pixelWidth: Float
            var pixelHeight: Float
            var depth: Float
            var time: Float
        }
        
        let uniforms = GridUniforms(
            mvpMatrix: projectionMatrix * viewMatrix * modelMatrix,
            pixelWidth: 2.0 / Float(context.windowProps.width),
            pixelHeight: 2.0 / Float(context.windowProps.height),
            depth: BackgroundGrid.depth,
            time: Float(context.presentationTimestamp - startTime)
        )
        let uniformBuffer = context.constantBufferPool.createBuffer(data: uniforms)
        
        commandEncoder.setRenderPipelineState(pipeline)
        commandEncoder.setDepthStencilState(depthState)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
        commandEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: 0)
        commandEncoder.drawIndexedPrimitives(type: MTLPrimitiveType.triangle, indexCount: indexCount, indexType: MTLIndexType.uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }
}
