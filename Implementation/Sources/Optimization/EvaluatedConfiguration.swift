import Swift


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
public struct EvaluatedConfiguration<Configuration: ConfigurationProtocol> {
    public let configuration: Configuration
    public let value: Double

    public init(from configuration: Configuration) {
        self.configuration = configuration
        self.value = configuration.evaluate()
    }

    internal func adding(_ delta: Double, to index: Int) -> EvaluatedConfiguration {
        var configuration = self.configuration
        configuration[index] += delta

        return EvaluatedConfiguration(from: configuration)
    }
}
