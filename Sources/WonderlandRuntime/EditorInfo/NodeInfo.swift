//
//  NodeInfo.swift
//  FBPLand
//
//  Created by Yu Ho Kwok on 10/20/24.
//

import Foundation

struct NodeInfo : Identifiable, Codable {
    var id : String
    var scale : CGFloat
    var offset : CGSize
    
    static func new(_ id : String) -> NodeInfo {
        let nodeInfo = NodeInfo(id: id, scale: 0.8, offset: .zero)
        return nodeInfo
    }
    
    static func new() -> NodeInfo {
        return NodeInfo.new(UUID().uuidString)
    }
    
}
