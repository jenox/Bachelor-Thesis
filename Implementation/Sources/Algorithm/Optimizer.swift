//
//  Optimizer.swift
//  Drawing-Graphs-with-Circular-Arcs
//
//  Created by Christian Schnorr on 18.05.17.
//  Copyright © 2017 Christian Schnorr. All rights reserved.
//

import Foundation



public protocol Optimizer: class {
    init(from configuration: MappedAccessConfiguration)

    var configuration: MappedAccessConfiguration { get }

    func step()

    func undo()
    func redo()
    func removeAllActions()
}

extension Optimizer {
    public init(for paths: GreedilyRealizableSequenceOfPaths) {
        let builder = RandomizedConfigurationBuilder(for: paths)
        let configuration = builder.configuration

        self.init(from: configuration)
    }
}
