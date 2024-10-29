//
//  ArchiveManager.swift
//  WonderlandRuntime
//
//  Created by Yu Ho Kwok on 10/30/24.
//
import UIKit
import ZIPFoundation


struct ArchiveManager {
    static func unzipFile(at sourceURL: URL, to destinationURL: URL)  {
        try? FileManager.default.unzipItem(at: sourceURL, to: destinationURL)
    }
}
