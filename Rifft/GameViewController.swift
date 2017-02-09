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
    var depthPixelFormat: MTLPixelFormat
    var sampleCount: Int
}

struct RenderContext {
    var commandEncoder: MTLRenderCommandEncoder
    var commandBuffer: MTLCommandBuffer
    var constantBufferPool: ConstantBufferPool
    var windowProps: WindowProperties
    var presentationTimestamp: Double
}

struct InitContext {
    var device: MTLDevice
    var windowProps: WindowProperties
    var library: MTLLibrary
    var functions: [String: MTLFunction]
    
    mutating func getFunction(name: String) -> MTLFunction {
        var f = functions[name]
        if f != nil { return f! }
        f = library.makeFunction(name: name)
        functions[name] = f
        return f!
    }
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
            depthPixelFormat: view.depthStencilPixelFormat,
            sampleCount: view.sampleCount
        )
        
        commandQueue = device.makeCommandQueue()
        commandQueue.label = "main command queue"
        
        constantBufferPool = ConstantBufferPool(device)
        
        var initContext = InitContext(
            device: device,
            windowProps: windowProps,
            library: device.newDefaultLibrary()!,
            functions: [:]
        )
        scene = LevelScene(context: &initContext)
    }
    
    func draw(in view: MTKView) {
        // TODO: Use CADisplayLink's timestamp for more precise timing
        let timestamp = CACurrentMediaTime() + 1.0 / 60.0;
        
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
            
            let aspect = Float(windowProps.width) / Float(windowProps.height)
            let nearZ = 1.5 / tanf(30.0 * Float(M_PI) / 180.0)
            
            // Metal uses [0, 1] for its Z coordinate and makeFrustum assumes [-1, 1]
            // We have to adjust for that
            let projectionMatrix = float4x4.makeTranslation(0, 0, 0.5) *
                float4x4.makeScale(1, 1, 0.5) *
                float4x4.makeFrustum(
                    left: aspect * -1.5, right: aspect * 1.5,
                    bottom: -1.5, top: 1.5,
                    nearZ: nearZ, farZ: nearZ + 100
                ) *
                float4x4.makeScale(1, 1, -1) // We prefer +Z into the screen
            
            
            let viewMatrix = float4x4.makeTranslation(0, 0, nearZ)
            
            let renderContext = RenderContext(
                commandEncoder: renderEncoder,
                commandBuffer: commandBuffer,
                constantBufferPool: constantBufferPool,
                windowProps: windowProps,
                presentationTimestamp: timestamp
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
