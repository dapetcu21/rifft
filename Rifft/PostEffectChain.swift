//
//  PostEffectChain.swift
//  Rifft
//
//  Created by Marius Petcu on 20/01/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import MetalKit

class PostEffect {
}

class PostEffectChain {
    var effects: Array<PostEffect> = []
    var textures: Array<MTLTexture> = []
    var renderPassDescriptors: Array<MTLRenderPassDescriptor> = []
    var device: MTLDevice
    var windowProps: WindowProperties
    
    init(device: MTLDevice, windowProps: WindowProperties) {
        self.device = device
        self.windowProps = windowProps
    }
    
    func addEffect(_ effect: PostEffect) {
        if effects.count < 2 {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: windowProps.colorPixelFormat,
                width: windowProps.width,
                height: windowProps.height,
                mipmapped: false
            )
            let texture = device.makeTexture(descriptor: textureDescriptor)
            textures.append(texture)
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptors.append(renderPassDescriptor)
        }
    }
    
    func draw(_ commandEncoder: MTLRenderCommandEncoder) {
        // device.makeCommandQueue().makeCommandBuffer().make
    }
}
