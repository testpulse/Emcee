import BuildArtifacts
import Foundation
import Models
import PluginSupport
import SimulatorPoolModels

public struct RunnerConfiguration {
    public let buildArtifacts: BuildArtifacts
    public let environment: [String: String]
    public let pluginLocations: Set<PluginLocation>
    public let simulatorSettings: SimulatorSettings
    public let testRunnerTool: TestRunnerTool
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testType: TestType
    
    public init(
        buildArtifacts: BuildArtifacts,
        environment: [String: String],
        pluginLocations: Set<PluginLocation>,
        simulatorSettings: SimulatorSettings,
        testRunnerTool: TestRunnerTool,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType
    ) {
        self.buildArtifacts = buildArtifacts
        self.environment = environment
        self.pluginLocations = pluginLocations
        self.simulatorSettings = simulatorSettings
        self.testRunnerTool = testRunnerTool
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
    }
}
