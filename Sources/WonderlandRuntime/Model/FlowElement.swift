//
//  FlowElement.swift
//  FBPLand
//
//  Created by Reality Builder Team on 19/2/2022.
//

import Foundation

protocol FlowTransformable {
    var center : Block.Point { get set }
    func containsPort(with uuid : String) -> Bool
    func port(with uuid : String) -> Block.Port?
}

protocol FlowElement : Identifiable, Equatable {
    var identifier : String { get }
    var timestamp : TimeInterval { get }
    mutating func update()
}
