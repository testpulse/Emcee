import AppleTools
import BuildArtifactsTestHelpers
import DeveloperDirLocatorTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import QueueModelsTestHelpers
import ResourceLocationResolverTestHelpers
import TemporaryStuff
import TestHelpers
import XCTest

final class XcTestRunFileArgumentTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    
    func test___apptest_requires_app_bundle() throws {
        let arg = XcTestRunFileArgument(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(
                appBundle: nil,
                runner: "",
                xcTestBundle: "",
                additionalApplicationBundles: []
            ),
            developerDirLocator: FakeDeveloperDirLocator(),
            entriesToRun: [],
            resourceLocationResolver: FakeResourceLocationResolver.resolvingTo(path: tempFolder.absolutePath),
            temporaryFolder: tempFolder,
            testContext: TestContextFixtures().testContext,
            testType: .appTest
        )
        
        assertThrows { _ = try arg.stringValue() }
    }
    
    func test___uitest_requires_app_bundle() throws {
        let arg = XcTestRunFileArgument(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(
                appBundle: nil,
                runner: "",
                xcTestBundle: "",
                additionalApplicationBundles: []
            ),
            developerDirLocator: FakeDeveloperDirLocator(),
            entriesToRun: [],
            resourceLocationResolver: FakeResourceLocationResolver.resolvingTo(path: tempFolder.absolutePath),
            temporaryFolder: tempFolder,
            testContext: TestContextFixtures().testContext,
            testType: .uiTest
        )
        
        assertThrows { _ = try arg.stringValue() }
    }
    
    func test___uitest_requires_runner_app_bundle() throws {
        let arg = XcTestRunFileArgument(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(
                appBundle: "",
                runner: nil,
                xcTestBundle: "",
                additionalApplicationBundles: []
            ),
            developerDirLocator: FakeDeveloperDirLocator(),
            entriesToRun: [],
            resourceLocationResolver: FakeResourceLocationResolver.resolvingTo(path: tempFolder.absolutePath),
            temporaryFolder: tempFolder,
            testContext: TestContextFixtures().testContext,
            testType: .uiTest
        )
        
        assertThrows { _ = try arg.stringValue() }
    }
}
