//
//  TouchRecognizer.swift
//  Rifft
//
//  Created by Marius Petcu on 09/02/2017.
//  Copyright © 2017 Marius Petcu. All rights reserved.
//

import Foundation
import UIKit.UIGestureRecognizerSubclass
import simd

class TouchRecognizer : UIGestureRecognizer {
    var gameState: GameState
    var touches: [GameState.Shield: UITouch] = [:]
    
    init(gameState: GameState, target: Any?, action: Selector?) {
        self.gameState = gameState
        super.init(target: target, action: action)
    }
    
    func locationOfTouch(_ touch: UITouch) -> float2 {
        let bounds = self.view!.bounds
        let loc = touch.location(in: self.view!)
        return float2(
            (Float(loc.x / bounds.size.width) * 2.0 - 1.0) * 1.5,
            (Float(loc.y / bounds.size.height) * 2.0 - 1.0) * -1.5
        )
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        for touch in touches {
            let location = locationOfTouch(touch)
            var shield: GameState.Shield = location.x < 0 ? .left : .right
            if self.touches[shield] != nil {
                shield = GameState.Shield(rawValue: 1 - shield.rawValue)!
                if self.touches[shield] != nil {
                    return
                }
            }
            self.touches[shield] = touch
            gameState.updateShield(shield, active: true, position: location, timestamp: event.timestamp)
        }
        if (state == .changed || state == .began) {
            state = .changed
        } else {
            state = .began
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            var shield: GameState.Shield!
            if touch == self.touches[.left] { shield = .left }
            else if touch == self.touches[.right] { shield = .right }
            if shield == nil { continue }
            
            let location = locationOfTouch(touch)
            gameState.updateShield(shield, active: true, position: location, timestamp: event.timestamp)
        }
        state = .changed
    }
    
    func touchesFinished(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches {
            var shield: GameState.Shield!
            if touch == self.touches[.left] { shield = .left }
            else if touch == self.touches[.right] { shield = .right }
            if shield == nil { continue }
            
            let location = locationOfTouch(touch)
            gameState.updateShield(shield, active: false, position: location, timestamp: event.timestamp)
            self.touches.removeValue(forKey: shield)
        }
        state = self.touches.isEmpty ? .ended : .changed
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        touchesFinished(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        touchesFinished(touches, with: event)
    }
}
