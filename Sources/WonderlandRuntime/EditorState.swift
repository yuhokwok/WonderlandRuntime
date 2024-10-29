//
//  EditorState.swift
//  FBPLand
//
//  Created by Reality Builder Team on 5/3/2022.
//

import UIKit


/// Store the Status for Editor 
class EditorState : Codable {
    var center : Block.Point
    var coordSystem : CoordSystem
    var scale : CGFloat
    
    init(center : Block.Point, scale: CGFloat = 1, coordSystem : CoordSystem = .xy) {
        self.center = center
        self.scale = scale
        self.coordSystem = coordSystem
    }
    
    enum CoordSystem : String, Codable {
        case xy = "x-y"
        case xz = "x-z"
    }
}
