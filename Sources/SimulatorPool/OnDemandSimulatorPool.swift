import DeveloperDirLocator
import Dispatch
import Foundation
import Logging
import Models
import ResourceLocationResolver
import TemporaryStuff

public class OnDemandSimulatorPool {
    
    public struct Key: Hashable, CustomStringConvertible {
        public let numberOfSimulators: UInt
        public let developerDir: DeveloperDir
        public let testDestination: TestDestination
        public let simulatorControlTool: SimulatorControlTool
        
        public init(
            numberOfSimulators: UInt,
            developerDir: DeveloperDir,
            testDestination: TestDestination,
            simulatorControlTool: SimulatorControlTool
        ) {
            self.numberOfSimulators = numberOfSimulators
            self.developerDir = developerDir
            self.testDestination = testDestination
            self.simulatorControlTool = simulatorControlTool
        }
        
        public var description: String {
            return "<\(type(of: self)): \(numberOfSimulators) simulators, destination: \(testDestination)>"
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(testDestination)
            hasher.combine(simulatorControlTool)
            hasher.combine(numberOfSimulators)
        }
        
        public static func == (left: OnDemandSimulatorPool.Key, right: OnDemandSimulatorPool.Key) -> Bool {
            return left.testDestination == right.testDestination
                && left.simulatorControlTool == right.simulatorControlTool
                && left.numberOfSimulators == right.numberOfSimulators
        }
    }
    
    private let developerDirLocator: DeveloperDirLocator
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorControllerProvider: SimulatorControllerProvider
    private let syncQueue = DispatchQueue(label: "ru.avito.OnDemandSimulatorPool")
    private let tempFolder: TemporaryFolder
    private var pools = [Key: SimulatorPool]()
    
    public init(
        developerDirLocator: DeveloperDirLocator,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorControllerProvider: SimulatorControllerProvider,
        tempFolder: TemporaryFolder
    ) {
        self.developerDirLocator = developerDirLocator
        self.resourceLocationResolver = resourceLocationResolver
        self.simulatorControllerProvider = simulatorControllerProvider
        self.tempFolder = tempFolder
    }
    
    deinit {
        deleteSimulators()
    }
    
    public func pool(key: Key) throws -> SimulatorPool {
        return try syncQueue.sync {
            if let existingPool = pools[key] {
                Logger.verboseDebug("Got SimulatorPool for key \(key)")
                return existingPool
            } else {
                let pool = try SimulatorPool(
                    developerDir: key.developerDir,
                    developerDirLocator: developerDirLocator,
                    numberOfSimulators: key.numberOfSimulators,
                    simulatorControlTool: key.simulatorControlTool,
                    simulatorControllerProvider: simulatorControllerProvider,
                    tempFolder: tempFolder,
                    testDestination: key.testDestination
                )
                pools[key] = pool
                Logger.verboseDebug("Created SimulatorPool for key \(key)")
                return pool
            }
        }
    }
    
    public func deleteSimulators() {
        syncQueue.sync {
            for pool in pools.values {
                pool.deleteSimulators()
            }
            pools.removeAll()
        }
    }
}
