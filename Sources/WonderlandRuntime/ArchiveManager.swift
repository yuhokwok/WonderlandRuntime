//
//  ArchiveManager.swift
//  WonderlandRuntime
//
//  Created by Yu Ho Kwok on 10/30/24.
//
import UIKit
import Zip

struct ArchiveManager {
    static func unzipFile(at sourceURL: URL, to destinationURL: URL)  {
        try? Zip.unzipFile(sourceURL, destination: destinationURL, overwrite: false, password: nil)
    }
}
