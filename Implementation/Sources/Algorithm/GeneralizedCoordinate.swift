import CoreGraphics


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public enum GeneralizedCoordinate {
    case x(UndirectedVertex, CGFloat)
    case y(UndirectedVertex, CGFloat)
    case angle(UndirectedPath, CGAngle)
    case progress(UndirectedVertex, CGFloat)

    // realValue
    public var value: Double {
        get {
            switch self {
            case let .x(_, value):
                return Double(value)
            case let .y(_, value):
                return Double(value)
            case let .angle(_, angle):
                return Double(10 * tan(angle / 2))
            case let .progress(_, progress):
                return Double(10 * tan((progress - 0.5) * .pi))
            }
        }
        set {
            switch self {
            case let .x(vertex, _):
                self = .x(vertex, CGFloat(newValue))
            case let .y(vertex, _):
                self = .y(vertex, CGFloat(newValue))
            case let .angle(path, _):
                self = .angle(path, 2 * .atan(CGFloat(newValue / 10)))
            case let .progress(vertex, _):
                self = .progress(vertex, CGFloat(atan(newValue / 10) / .pi + 0.5))
            }
        }
    }

    public var rawValue: CGFloat {
        get {
            switch self {
            case let .x(_, value): return value
            case let .y(_, value): return value
            case let .angle(_, angle): return angle.radians
            case let .progress(_, progress): return progress
            }
        }
        set {
            switch self {
            case let .x(vertex, _): self = .x(vertex, newValue)
            case let .y(vertex, _): self = .y(vertex, newValue)
            case let .angle(path, _): self = .angle(path, .radians(newValue))
            case let .progress(vertex, _): self = .progress(vertex, newValue)
            }
        }
    }
}

extension GeneralizedCoordinate: Equatable, Hashable {
    public static func ==(lhs: GeneralizedCoordinate, rhs: GeneralizedCoordinate) -> Bool {
        switch lhs {
        case let .x(vertex, value):
            if case .x(vertex, value) = rhs {
                return true
            } else {
                return false
            }
        case let .y(vertex, value):
            if case .y(vertex, value) = rhs {
                return true
            } else {
                return false
            }
        case let .angle(path, value):
            if case .angle(path, value) = rhs {
                return true
            } else {
                return false
            }
        case let .progress(vertex, value):
            if case .progress(vertex, value) = rhs {
                return true
            } else {
                return false
            }
        }
    }

    public var hashValue: Int {
        switch self {
        case let .x(vertex, value):
            return HashHelper.combine(vertex, value)
        case let .y(vertex, value):
            return HashHelper.combine(vertex, value)
        case let .angle(path, value):
            return HashHelper.combine(path, value.turns)
        case let .progress(vertex, value):
            return HashHelper.combine(vertex, value)
        }
    }

}

extension GeneralizedCoordinate: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .x(vertex, x): return "x(\(vertex)) = \(x)"
        case let .y(vertex, y): return "y(\(vertex)) = \(y)"
        case let .angle(path, angle): return "angle(\(path)) = \(angle)"
        case let .progress(vertex, progress): return "progress(\(vertex)) = \(progress)"
        }
    }
}
