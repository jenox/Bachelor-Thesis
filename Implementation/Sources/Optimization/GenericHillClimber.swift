import Foundation


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public class GenericHillClimber<Configuration: ConfigurationProtocol> {

    // MARK: - Initialization

    public init(from configuration: Configuration, mode: OptimizationMode = .maximize) {
        self.mode = mode
        self.acceleration = 1.2

        self.configuration = configuration
        self.steps = Array(repeating: 1, count: configuration.count)
    }



    // MARK: - State

    private let mode: OptimizationMode
    private let acceleration: Double

    private(set) public var configuration: Configuration {
        didSet {
            self.undoManager.registerUndo(withTarget: self, handler: {
                $0.configuration = oldValue
            })
        }
    }

    private var steps: [Double] {
        didSet {
            self.undoManager.registerUndo(withTarget: self, handler: {
                $0.steps = oldValue
            })
        }
    }



    // MARK: - Hill Climbing

    public var numberOfDimensions: Int {
        return self.configuration.count
    }

    @discardableResult
    public func climb() -> Double {
        typealias Value = EvaluatedConfiguration<Configuration>

        let last = EvaluatedConfiguration(from: self.configuration)

        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        let count = self.steps.count

        let configurations = UnsafeMutablePointer<Value>.allocate(capacity: count)
        configurations.initialize(to: last, count: count)

        let accelerations = UnsafeMutablePointer<Double>.allocate(capacity: count)
        accelerations.initialize(to: pow(self.acceleration, -1), count: count)

        defer {
            configurations.deinitialize(count: count)
            configurations.deallocate(capacity: count)

            accelerations.deinitialize(count: count)
            accelerations.deallocate(capacity: count)
        }

        for index in 0..<count {
            queue.async(group: group, execute: {
                var best = last

                for exponent in -1...1 {
                    let factor = pow(self.acceleration, Double(exponent))
                    let delta = self.steps[index] * factor

                    let plus = last.adding(+delta, to: index)
                    let minus = last.adding(-delta, to: index)

                    for alternative in [plus, minus] {
                        if self.mode.should(use: alternative.value, over: best.value) {
                            best = alternative
                            accelerations[index] = factor
                        }
                    }
                }

                configurations[index] = best
            })
        }

        group.notify(queue: queue, execute: {
            semaphore.signal()
        })

        semaphore.wait()

        do {
            self.undoManager.beginUndoGrouping()

            var next = last

            for index in 0..<count {
                self.steps[index] *= accelerations[index]

                if self.mode.should(use: configurations[index].value, over: next.value) {
                    next = configurations[index]
                }
            }

            self.configuration = next.configuration

            self.undoManager.endUndoGrouping()

            return fabs(next.value - last.value)
        }
    }



    // MARK: - Undo & Redo

    private let undoManager: UndoManager = UndoManager()

    public func undo() {
        self.undoManager.undo()
    }

    public func redo() {
        self.undoManager.redo()
    }

    public func removeAllActions() {
        self.undoManager.removeAllActions()
    }
}
