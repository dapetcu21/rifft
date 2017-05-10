//
//  OnsetDetection.swift
//  Rifft
//
//  Created by Marius Petcu on 09/05/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

struct Onset {
    var timestamp: Double
}

func getOnsetListFromMusic(_ musicUrl: URL) throws -> [Onset] {
    let asset = AVAsset(url: musicUrl)
    let reader = try AVAssetReader(asset: asset)
    let track = asset.tracks(withMediaType: AVMediaTypeAudio)[0]
    
    let fftSize = 1024
    let fftLength = 10 // 1024 == 2 ^ 10
    let sampleRate = 44100
    let meanWindowSize = 31
    let meanWindowScale = 1.8 / Float(meanWindowSize)
    
    let settings: [String: Int] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVLinearPCMIsFloatKey: 1,
        AVLinearPCMIsNonInterleaved: 1,
        AVLinearPCMBitDepthKey: 32,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: 1,
        ]
    
    let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
    
    reader.add(readerOutput)
    reader.startReading()
    
    let fftSampleDuration: Double = Double(fftSize) / Double(sampleRate)
    let fftRadix = FFTRadix(kFFTRadix2)
    let fftSetup = vDSP_create_fftsetup(vDSP_Length(fftLength), fftRadix)!
    
    var inputBuffer = [Float](repeating: 0.0, count: fftSize)
    var tmpBuffer = [Float](repeating: 0.0, count: fftSize)
    var tmp2Buffer = [Float](repeating: 0.0, count: fftSize)
    var lastFFT = [Float](repeating: 0.0, count: fftSize)
    var splitBuffer = DSPSplitComplex(realp: &tmpBuffer, imagp: &inputBuffer)
    
    
    var bufferHead = 0
    var tick = 0
    var lastPeak: Float = 0.0
    var lastLastPeak: Float = 0.0
    var meanWindowBuffer = [Float](repeating: 0.0, count: meanWindowSize)
    var meanWindowIndex = 0
    var meanWindowSum: Float = 0.0
    
    var window = [Float](repeating: 0.0, count: fftSize) // Hamming window
    vDSP_hamm_window(&window, UInt(fftSize), 0)
    
    var onsets = [Onset]()
    
    while reader.status == AVAssetReaderStatus.reading {
        if let sampleBufferRef = readerOutput.copyNextSampleBuffer() {
            if let blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef) {
                let bufferLength = CMBlockBufferGetDataLength(blockBufferRef)
                
                let data = NSMutableData(length: bufferLength)
                CMBlockBufferCopyDataBytes(blockBufferRef, 0, bufferLength, data!.mutableBytes)
                
                let sampleCount = bufferLength / 4
                let ptr = data!.bytes.bindMemory(to: Float32.self, capacity: sampleCount)
                var pos = 0
                
                while sampleCount - pos > 0 {
                    let len = min(fftSize - bufferHead, sampleCount - pos)
                    
                    let buffer = UnsafeBufferPointer(start: ptr + pos, count: len)
                    inputBuffer.replaceSubrange(bufferHead..<(len + bufferHead), with: buffer)
                    
                    bufferHead += len
                    pos += len
                    if (bufferHead == fftSize) {
                        bufferHead = 0
                        
                        vDSP_vmul(&inputBuffer, 1, &window, 1, &tmpBuffer, 1, vDSP_Length(fftSize))
                        
                        inputBuffer.withUnsafeMutableBufferPointer({
                            memset($0.baseAddress, 0, fftSize * 4)
                        })
                        
                        vDSP_fft_zip(fftSetup, &splitBuffer, 1, vDSP_Length(fftLength), FFTDirection(kFFTDirection_Forward))
                        
                        vDSP_zvmags(&splitBuffer, 1, &tmp2Buffer, 1, vDSP_Length(fftSize))
                        
                        vvsqrtf(&inputBuffer, &tmp2Buffer, [Int32(fftSize)])
                        
                        var magnitude: Float = 0.0
                        vDSP_meanv(&inputBuffer, 1, &magnitude, vDSP_Length(fftSize))
                        magnitude
                        
                        if tick > 0 {
                            vDSP_vsub(&lastFFT, 1, &inputBuffer, 1, &tmpBuffer, 1, vDSP_Length(fftSize))
                            vDSP_vthr(&tmpBuffer, 1, [Float(0.0)], &tmp2Buffer, 1, vDSP_Length(fftSize))
                            
                            var flux: Float = 0.0
                            vDSP_meanv(&tmp2Buffer, 1, &flux, vDSP_Length(fftSize))
                            flux
                            
                            meanWindowSum += flux - meanWindowBuffer[meanWindowIndex]
                            meanWindowBuffer[meanWindowIndex] = flux
                            meanWindowIndex += 1
                            if (meanWindowIndex == meanWindowSize) {
                                meanWindowIndex = 0
                            }
                            
                            if (tick > meanWindowSize) {
                                let mean = meanWindowScale * meanWindowSum
                                var windowCenter = meanWindowIndex - (meanWindowSize / 2)
                                if (windowCenter < 0) {
                                    windowCenter += meanWindowSize
                                }
                                let fluxAtCenterOfWindow = meanWindowBuffer[windowCenter]
                                
                                let peak = max(0.0, fluxAtCenterOfWindow - mean)
                                if (lastLastPeak < lastPeak && lastPeak >= peak) {
                                    let timestamp: Double = Double(tick - (meanWindowSize / 2) - 1) * fftSampleDuration
                                    onsets.append(Onset(timestamp: timestamp))
                                }
                                lastLastPeak = lastPeak
                                lastPeak = peak
                            }
                        }
                        
                        lastFFT.replaceSubrange(0..<fftSize, with: inputBuffer)
                        tick += 1
                    }
                }
                
                CMSampleBufferInvalidate(sampleBufferRef)
            }
        }
    }
    
    vDSP_destroy_fftsetup(fftSetup)
    
    return onsets
}

let musicUrl = Bundle.main.url(forResource: "oban", withExtension: "mp3")!
print(try getOnsetListFromMusic(musicUrl))
