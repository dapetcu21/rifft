//
//  ConstantBufferPool.swift
//  Rifft
//
//  Created by Marius Petcu on 06/02/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import Metal

class ConstantBufferPool {
    private var heaps = [MTLCommandBuffer]()
    private var commandBuffer: MTLCommandBuffer
    
    init(_ commandBuffer: MTLCommandBuffer) {
        self.commandBuffer = commandBuffer
    }
    
    static private var bufferPools = [ObjectIdentifier: ConstantBufferPool]()
    
    static func getBufferPool(commandBuffer: MTLCommandBuffer) -> ConstantBufferPool {
        let commandBufferId = ObjectIdentifier(commandBuffer)
        let optionalBufferPool: ConstantBufferPool? = bufferPools[commandBufferId]
        if let bufferPool = optionalBufferPool {
            return bufferPool;
        }
        let bufferPool = ConstantBufferPool(commandBuffer)
        bufferPools[commandBufferId] = bufferPool
        return bufferPool
    }
}
