import CoreGraphics


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public protocol CGGeometryRoundable {
    typealias RoundingFunction = CGGeometryRoundingFunction
    associatedtype RoundingRule

    func rounded(_ function: RoundingFunction, _ rule: RoundingRule) -> Self
    func rounded(_ function: RoundingFunction) -> Self
    func rounded(_ rule: RoundingRule) -> Self
    func rounded() -> Self

    mutating func round(_ function: RoundingFunction, _ rule: RoundingRule)
    mutating func round(_ function: RoundingFunction)
    mutating func round(_ rule: RoundingRule)
    mutating func round()
}



// MARK: - Rounding Function

public protocol CGGeometryRoundingFunction {
    func round(_ value: CGFloat, using rule: FloatingPointRoundingRule) -> CGFloat
}

public struct CGGeometryRoundToPoints: CGGeometryRoundingFunction {
    public init() {
    }

    public func round(_ value: CGFloat, using rule: FloatingPointRoundingRule) -> CGFloat {
        return value.rounded(rule)
    }
}



// MARK: - Default Roundable

internal protocol CGGeometryDefaultRoundable: CGGeometryRoundable {
    static var defaultRoundingFunction: RoundingFunction { get }
    static var defaultRoundingRule: RoundingRule { get }
}

extension CGGeometryDefaultRoundable {
    public func rounded(_ function: RoundingFunction) -> Self {
        return self.rounded(function, Self.defaultRoundingRule)
    }

    public func rounded(_ rule: RoundingRule) -> Self {
        return self.rounded(Self.defaultRoundingFunction, rule)
    }

    public func rounded() -> Self {
        return self.rounded(Self.defaultRoundingFunction, Self.defaultRoundingRule)
    }

    public mutating func round(_ function: RoundingFunction, _ rule: RoundingRule) {
        self = self.rounded(function, rule)
    }

    public mutating func round(_ function: RoundingFunction) {
        self = self.rounded(function)
    }

    public mutating func round(_ rule: RoundingRule) {
        self = self.rounded(rule)
    }

    public mutating func round() {
        self = self.rounded()
    }
}


// MARK: - Protocol Conformances

extension CGFloat: CGGeometryRoundable {
    public typealias RoundingFunction = CGGeometryRoundable.RoundingFunction
    public typealias RoundingRule = FloatingPointRoundingRule

    public static let defaultRoundingFunction: RoundingFunction = CGGeometryRoundToPoints()
    public static let defaultRoundingRule: RoundingRule = .toNearestOrAwayFromZero

    public func rounded(_ function: RoundingFunction, _ rule: RoundingRule) -> CGFloat {
        return function.round(self, using: rule)
    }

    public func rounded(_ function: RoundingFunction) -> CGFloat {
        return self.rounded(function, CGFloat.defaultRoundingRule)
    }

    public mutating func round(_ function: RoundingFunction, _ rule: RoundingRule) {
        self = self.rounded(function, rule)
    }

    public mutating func round(_ function: RoundingFunction) {
        self = self.rounded(function)
    }
}

extension CGPoint: CGGeometryRoundable, CGGeometryDefaultRoundable {
    public typealias RoundingFunction = CGGeometryRoundingFunction

    public enum RoundingRule {
        case toNearestComponents
    }

    public static let defaultRoundingFunction: RoundingFunction = CGGeometryRoundToPoints()
    public static let defaultRoundingRule: RoundingRule = .toNearestComponents

    public func rounded(_ function: RoundingFunction, _ rule: RoundingRule) -> CGPoint {
        let x, y: CGFloat

        switch rule {
        case .toNearestComponents:
            x = self.x.rounded(function, .toNearestOrAwayFromZero)
            y = self.y.rounded(function, .toNearestOrAwayFromZero)
        }

        return CGPoint(x: x, y: y)
    }
}

extension CGSize: CGGeometryRoundable, CGGeometryDefaultRoundable {
    public typealias RoundingFunction = CGGeometryRoundingFunction

    public enum RoundingRule {
        case toNearestComponents
        case toNearestContainer
        case toNearestContained
    }

    public static let defaultRoundingFunction: RoundingFunction = CGGeometryRoundToPoints()
    public static let defaultRoundingRule: RoundingRule = .toNearestComponents

    public func rounded(_ function: RoundingFunction, _ rule: RoundingRule) -> CGSize {
        let w, h: CGFloat

        switch rule {
        case .toNearestComponents:
            w = self.width.rounded(function, .toNearestOrAwayFromZero)
            h = self.height.rounded(function, .toNearestOrAwayFromZero)
        case .toNearestContainer:
            w = self.width.rounded(function, self.width >= 0 ? .up : .down)
            h = self.height.rounded(function, self.height >= 0 ? .up : .down)
        case .toNearestContained:
            w = self.width.rounded(function, self.width >= 0 ? .down : .up)
            h = self.height.rounded(function, self.height >= 0 ? .down : .up)
        }

        return CGSize(width: w, height: h)
    }
}

extension CGRect: CGGeometryRoundable, CGGeometryDefaultRoundable {
    public typealias RoundingFunction = CGGeometryRoundingFunction

    public enum RoundingRule {
        case toNearestComponents // component-wise
        case toNearestContainer // smallest container, "integral"
        case toNearestEdges // edge-wise
    }

    public static let defaultRoundingFunction: RoundingFunction = CGGeometryRoundToPoints()
    public static let defaultRoundingRule: RoundingRule = .toNearestComponents

    public func rounded(_ function: RoundingFunction, _ rule: RoundingRule) -> CGRect {
        guard self != .null else {
            return .null
        }

        guard self != .infinite else {
            return .infinite
        }

        let x, y, w, h: CGFloat

        switch rule {
        case .toNearestComponents:
            x = self.origin.x.rounded(function, .toNearestOrAwayFromZero)
            y = self.origin.y.rounded(function, .toNearestOrAwayFromZero)
            w = self.size.width.rounded(function, .toNearestOrAwayFromZero)
            h = self.size.height.rounded(function, .toNearestOrAwayFromZero)
        case .toNearestContainer:
            x = self.origin.x.rounded(function, self.size.width >= 0 ? .down : .up)
            y = self.origin.y.rounded(function, self.size.height >= 0 ? .down : .up)
            w = self.size.width.rounded(function, self.size.width >= 0 ? .up : .down)
            h = self.size.height.rounded(function, self.size.height >= 0 ? .up : .down)
        case .toNearestEdges:
            x = self.origin.x.rounded(function, .toNearestOrAwayFromZero)
            y = self.origin.y.rounded(function, .toNearestOrAwayFromZero)
            w = (self.size.width + self.origin.x - x).rounded(function, .toNearestOrAwayFromZero)
            h = (self.size.height + self.origin.y - y).rounded(function, .toNearestOrAwayFromZero)
        }

        return CGRect(x: x, y: y, width: w, height: h)
    }
}

extension CGVector: CGGeometryRoundable, CGGeometryDefaultRoundable {
    public typealias RoundingFunction = CGGeometryRoundingFunction

    public enum RoundingRule {
        case toNearestComponents
    }

    public static let defaultRoundingFunction: RoundingFunction = CGGeometryRoundToPoints()
    public static let defaultRoundingRule: RoundingRule = .toNearestComponents

    public func rounded(_ function: RoundingFunction, _ rule: RoundingRule) -> CGVector {
        let dx, dy: CGFloat

        switch rule {
        case .toNearestComponents:
            dx = self.dx.rounded(function, .toNearestOrAwayFromZero)
            dy = self.dy.rounded(function, .toNearestOrAwayFromZero)
        }

        return CGVector(dx: dx, dy: dy)
    }
}
