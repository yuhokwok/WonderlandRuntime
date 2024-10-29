//
//  Connection.swift
//  FBPLand
//
//  Created by Reality Builder Team on 20/2/2022.
//

import Foundation

struct Connection : FlowElement, Codable  {
    
    var id : String {
        return identifier
    }
    
    var sourceId = ""
    var destinationId = ""
    
    var _identifier = UUID().uuidString
    var _timestamp = Date().timeIntervalSinceReferenceDate
    
    var identifier: String {
        return _identifier
    }
    
    var timestamp: TimeInterval {
        return _timestamp
    }
    
    static func ===(lhs : Connection, rhs : Connection) -> Bool {
        return (lhs.identifier == rhs.identifier && lhs.timestamp == rhs.timestamp)
    }
    
    static func ==(lhs : Connection, rhs : Connection) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    mutating func update() {
        self._timestamp = Date().timeIntervalSinceReferenceDate
    }
    
    static func build(sourceId : String, destinationId: String) -> Connection {
        var connection = Connection()
        connection.sourceId = sourceId
        connection.destinationId = destinationId
        return connection
    }
}
