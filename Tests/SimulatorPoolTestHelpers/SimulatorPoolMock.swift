@testable import SimulatorPool
import DeveloperDirLocator
import DeveloperDirLocatorTestHelpers
import Models
import ModelsTestHelpers
import PathLib
import SimulatorPoolModels
import TemporaryStuff
import RunnerModels

public final class SimulatorPoolMock: SimulatorPool {
    public var freedSimulatorContoller: SimulatorController?
    
    public init() {}
    
    public func allocateSimulatorController() throws -> SimulatorController {
        let controller = FakeSimulatorController(
            simulator: SimulatorFixture.simulator(),
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            developerDir: .current
        )
        controller.simulatorBecameBusy()
        return controller
    }
    
    public func free(simulatorController: SimulatorController) {
        simulatorController.simulatorBecameIdle()
        freedSimulatorContoller = simulatorController
    }
    
    public func deleteSimulators() {}
    
    public func shutdownSimulators() {}
}
