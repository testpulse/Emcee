import BuildArtifacts
import Foundation
import Models
import TestArgFile
import TestDiscovery

public enum TestDicoveryModeInputValidationError: Error, CustomStringConvertible {
    case missingAppBundleToPerformApplicationTestRuntimeDump(XcTestBundle)
    public var description: String {
        switch self {
        case .missingAppBundleToPerformApplicationTestRuntimeDump(let xcTestBundle):
            return "Cannot perform runtime dump in application test mode: test bundle \(xcTestBundle) requires application bundle to be provided, but build artifacts do not contain location of app bundle"
        }
    }
}

public final class TestDiscoveryModeDeterminer {
    public static func testDiscoveryMode(testArgFileEntry: TestArgFile.Entry) throws -> TestDiscoveryMode {
        switch testArgFileEntry.buildArtifacts.xcTestBundle.testDiscoveryMode {
        case .parseFunctionSymbols:
            return .parseFunctionSymbols
        case .runtimeLogicTest:
            return .runtimeLogicTest(testArgFileEntry.simulatorControlTool)
        case .runtimeAppTest:
            guard let appLocation = testArgFileEntry.buildArtifacts.appBundle else {
                throw TestDicoveryModeInputValidationError.missingAppBundleToPerformApplicationTestRuntimeDump(testArgFileEntry.buildArtifacts.xcTestBundle)
            }
            return .runtimeAppTest(
                RuntimeDumpApplicationTestSupport(
                    appBundle: appLocation,
                    simulatorControlTool: testArgFileEntry.simulatorControlTool
                )
            )
        }
    }
}
