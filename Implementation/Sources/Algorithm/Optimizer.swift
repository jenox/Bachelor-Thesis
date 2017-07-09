//
//  Optimizer.swift
//  Drawing-Graphs-with-Circular-Arcs
//
//  Created by Christian Schnorr on 18.05.17.
//  Copyright © 2017 Christian Schnorr. All rights reserved.
//

import Foundation



public protocol Optimizer: class {
    var configuration: MappedAccessConfiguration { get }
    var drawing: Drawing { get }

    @discardableResult
    func step() -> Double

    func undo()
    func redo()
    func removeAllActions()
}
