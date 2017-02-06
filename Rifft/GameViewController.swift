//
//  GameViewController.swift
//  Rifft
//
//  Created by Marius Petcu on 19/01/2017.
//  Copyright (c) 2017 Marius Petcu. All rights reserved.
//

import UIKit
import Metal
import MetalKit

let MaxBuffers = 1

struct WindowProperties {
    var width: Int
    var height: Int
    var colorPixelFormat: MTLPixelFormat
    var sampleCount: Int
}

struct RenderContext {
    var commandEncoder: MTLRenderCommandEncoder
    var commandBuffer: MTLCommandBuffer
    var constantBufferPool: ConstantBufferPool
    var windowProps: WindowProperties
}

class GameViewController: UIViewController, MTKViewDelegate {
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    var constantBufferPool: ConstantBufferPool! = nil
    let inflightSemaphore = DispatchSemaphore(value: MaxBuffers)
    var bufferIndex = 0
    
    var windowProps: WindowProperties! = nil
    
    var scene: LevelScene! = nil
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { // Fallback to a blank NSView, an application could also fallback to OpenGL here.
            print("Metal is not supported on this device")
            self.view = UIView(frame: self.view.frame)
            return
        }
        
        // setup view properties
        let view = self.view as! MTKView
        view.delegate = self
        view.device = device
        view.sampleCount = 4
        
        windowProps = WindowProperties(
            width: Int(view.bounds.width),
            height: Int(view.bounds.height),
            colorPixelFormat: view.colorPixelFormat,
            sampleCount: view.sampleCount
        )
        
        commandQueue = device.makeCommandQueue()
        commandQueue.label = "main command queue"
        
        constantBufferPool = ConstantBufferPool(device)
        
        scene = LevelScene(device: device, windowProps: windowProps)
    }
    
    func draw(in view: MTKView) {
        
        // use semaphore to encode one frame ahead
        let _ = inflightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer.label = "Frame command buffer"
        
        constantBufferPool.aliasBuffers()
        
        // use completion handler to signal the semaphore when this frame is completed allowing the encoding of the next frame to proceed
        // use capture list to avoid any retain cycles if the command buffer gets retained anywhere besides this stack frame
        commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
            if let strongSelf = self {
                strongSelf.inflightSemaphore.signal()
            }
            return
        }
        
        if let renderPassDescriptor = view.currentRenderPassDescriptor, let currentDrawable = view.currentDrawable {
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder.label = "render encoder"
            
            let projectionMatrix = float4x4.makeOrtho(
                left: 0, right: Float(windowProps.width),
                bottom: 0, top: Float(windowProps.height),
                nearZ: -1, farZ: 1
            )
            let viewMatrix = float4x4(diagonal: float4(1.0))
            
            let renderContext = RenderContext(
                commandEncoder: renderEncoder,
                commandBuffer: commandBuffer,
                constantBufferPool: constantBufferPool,
                windowProps: windowProps
            )
            scene.draw(context: renderContext, projectionMatrix: projectionMatrix, viewMatrix: viewMatrix)
            
            renderEncoder.endEncoding()
            commandBuffer.present(currentDrawable)
        }
        
        // bufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        bufferIndex = (bufferIndex + 1) % MaxBuffers
        
        commandBuffer.commit()
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
