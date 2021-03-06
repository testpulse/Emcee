import Runner
import Models
import RunnerModels

public final class FakeTestRunnerProvider: TestRunnerProvider {
    public var predefinedFakeTestRunner = FakeTestRunner()
    public var predefinedTestRunner: TestRunner

    public init() {
        predefinedTestRunner = predefinedFakeTestRunner
    }

    public func testRunner(testRunnerTool: TestRunnerTool) throws -> TestRunner {
        return predefinedTestRunner
    }
}

