import Swift


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public protocol ConfigurationProtocol {
    var count: Int { get }
    subscript(index: Int) -> Double { get set }

    func evaluate() -> Double
    func clone() -> Self
}
