//
//  AudioManager.swift
//  Rifft
//
//  Created by Marius Petcu on 09/02/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import AVFoundation


class AudioManager : NSObject {
    var preloadHandler: (TimeInterval) -> Void
    var delay: TimeInterval
    var player: AVPlayer
    
    init(url: URL, delay: TimeInterval, preloadHandler: @escaping (TimeInterval) -> Void) {
        self.preloadHandler = preloadHandler
        self.delay = delay
        
        let player = AVPlayer(url: url)
        self.player = player
        
        super.init()
        
        player.automaticallyWaitsToMinimizeStalling = false
        player.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayer.status),
            options: [],
            context: Unmanaged.passUnretained(self).toOpaque()
        )
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == Unmanaged.passUnretained(self).toOpaque() else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        let player = object as! AVPlayer
        if player.status == .readyToPlay {
            player.removeObserver(self, forKeyPath: keyPath!)
            let delay = self.delay
            let preloadHandler = self.preloadHandler
            player.preroll(atRate: 1, completionHandler: { (hasFinished: Bool) in
                if hasFinished {
                    let now = CMClockMakeHostTimeFromSystemUnits(mach_absolute_time())
                    let hostTime = CMTimeAdd(now, CMTime(seconds: delay, preferredTimescale: 1000))
                    preloadHandler(CMTimeGetSeconds(hostTime))
                    player.setRate(1, time: CMTime(seconds: 0, preferredTimescale: 1), atHostTime: hostTime)
                }
             }
            )
        }
    }
    
}
