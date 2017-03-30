import Swift


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public enum OptimizationMode {
    case maximize
    case minimize

    public func should<T: Comparable>(use lhs: T, over rhs: T) -> Bool {
        switch self {
        case .maximize: return lhs > rhs
        case .minimize: return lhs < rhs
        }
    }
}
