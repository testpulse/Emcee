import Foundation
import Models
import PathLib
import RunnerModels
import TemporaryStuff
import UniqueIdentifierGenerator

public final class SimulatorSetPathDeterminerImpl: SimulatorSetPathDeterminer {
    private let simulatorContainerFolderName: String
    private let temporaryFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        simulatorContainerFolderName: String = "fbsimctl_simulators",
        temporaryFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.simulatorContainerFolderName = simulatorContainerFolderName
        self.temporaryFolder = temporaryFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func simulatorSetPathSuitableForTestRunnerTool() throws -> AbsolutePath {
        return try temporaryFolder.pathByCreatingDirectories(
            components: [simulatorContainerFolderName, uniqueIdentifierGenerator.generate()]
        )
    }
}
