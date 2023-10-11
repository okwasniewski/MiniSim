//
//  SubMenuItem.swift
//  MiniSim
//
//  Created by Anton Kolchunov on 11.10.23.
//

import Cocoa
import Foundation

protocol SubMenuItem {
    var needBootedDevice: Bool { get }
    var bootsDevice: Bool  { get }
    var title: String { get }
    var image: NSImage? { get }
    var tag: Int { get }
    var isSeparator: Bool { get }
}
