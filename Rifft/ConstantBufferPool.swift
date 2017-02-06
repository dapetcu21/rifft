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
    private var heaps = [MTLHeap]()
    private var buffers = [MTLBuffer]()
    private var device: MTLDevice
    public var heapSize = 1 * 1024 * 1024 // 1MB should be enough for constants
    
    init(_ device: MTLDevice) {
        self.device = device
    }
    
    func aliasBuffers() {
        for buffer in buffers {
            buffer.makeAliasable()
        }
        buffers.removeAll(keepingCapacity: true)
    }
    
    func dequeueBuffer(length: Int) -> MTLBuffer {
        let bufferOptions = MTLResourceOptions.cpuCacheModeWriteCombined.union(MTLResourceOptions.storageModeShared)
        let sizeAndAlign = device.heapBufferSizeAndAlign(length: length, options: bufferOptions)
        
        for heap in heaps {
            if heap.maxAvailableSize(alignment: sizeAndAlign.align) >= sizeAndAlign.size {
                let buffer = heap.makeBuffer(length: length, options: bufferOptions)
                buffers.append(buffer)
                return buffer
            }
        }
        
        let heapDescriptor = MTLHeapDescriptor()
        heapDescriptor.cpuCacheMode = MTLCPUCacheMode.writeCombined
        heapDescriptor.storageMode = MTLStorageMode.shared
        heapDescriptor.size = max(sizeAndAlign.size, heapSize)
        
        let heap = device.makeHeap(descriptor: heapDescriptor)
        heaps.append(heap)
        
        let buffer = heap.makeBuffer(length: length, options: bufferOptions)
        buffers.append(buffer)
        return buffer
    }
    
    func createBuffer<T>(data: T) -> MTLBuffer {
        let size = MemoryLayout<T>.size
        let buffer = dequeueBuffer(length: size)
        buffer.contents().storeBytes(of: data, as: T.self)
        return buffer
    }
}
