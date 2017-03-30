import CoreGraphics


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public enum GeneralizedCoordinate: CustomStringConvertible {
    case x(UndirectedVertex, CGFloat)
    case y(UndirectedVertex, CGFloat)
    case angle(UndirectedPath, CGAngle)
    case progress(UndirectedVertex, CGFloat)

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

    public var description: String {
        switch self {
        case let .x(vertex, x): return "x(\(vertex)) = \(x)"
        case let .y(vertex, y): return "y(\(vertex)) = \(y)"
        case let .angle(path, angle): return "angle(\(path)) = \(angle)"
        case let .progress(vertex, progress): return "progress(\(vertex)) = \(progress)"
        }
    }
}
