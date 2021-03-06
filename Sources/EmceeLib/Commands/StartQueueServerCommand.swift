import ArgLib
import AutomaticTermination
import DateProvider
import Deployer
import DistWorkerModels
import Extensions
import Foundation
import LocalHostDeterminer
import LocalQueueServerRunner
import Logging
import LoggingSetup
import Models
import PluginManager
import PortDeterminer
import QueueServer
import RemotePortDeterminer
import RequestSender
import ResourceLocationResolver
import ScheduleStrategy
import TemporaryStuff
import UniqueIdentifierGenerator

public final class StartQueueServerCommand: Command {
    public let name = "startLocalQueueServer"
    public let description = "Starts queue server on local machine. This mode waits for jobs to be scheduled via REST API."
    public let arguments: Arguments = [
        ArgumentDescriptions.emceeVersion.asRequired,
        ArgumentDescriptions.queueServerRunConfigurationLocation.asRequired
    ]

    private let requestSenderProvider: RequestSenderProvider
    private let payloadSignature: PayloadSignature
    private let resourceLocationResolver: ResourceLocationResolver
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        requestSenderProvider: RequestSenderProvider,
        payloadSignature: PayloadSignature,
        resourceLocationResolver: ResourceLocationResolver,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.requestSenderProvider = requestSenderProvider
        self.payloadSignature = payloadSignature
        self.resourceLocationResolver = resourceLocationResolver
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func run(payload: CommandPayload) throws {
        let emceeVersion: Version = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name)
        let queueServerRunConfiguration = try ArgumentsReader.queueServerRunConfiguration(
            location: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerRunConfigurationLocation.name),
            resourceLocationResolver: resourceLocationResolver
        )
        
        try LoggingSetup.setupAnalytics(analyticsConfiguration: queueServerRunConfiguration.analyticsConfiguration, emceeVersion: emceeVersion)
        
        try startQueueServer(
            emceeVersion: emceeVersion,
            queueServerRunConfiguration: queueServerRunConfiguration,
            workerDestinations: queueServerRunConfiguration.workerDeploymentDestinations
        )
    }
    
    private func startQueueServer(
        emceeVersion: Version,
        queueServerRunConfiguration: QueueServerRunConfiguration,
        workerDestinations: [DeploymentDestination]
    ) throws {
        Logger.info("Generated payload signature: \(payloadSignature)")
        
        let automaticTerminationController = AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy
        ).createAutomaticTerminationController()
        let queueServer = QueueServerImpl(
            automaticTerminationController: automaticTerminationController,
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(queueServerRunConfiguration.deploymentDestinationConfigurations.count)
            ),
            checkAgainTimeInterval: queueServerRunConfiguration.checkAgainTimeInterval,
            dateProvider: SystemDateProvider(),
            emceeVersion: emceeVersion,
            localPortDeterminer: LocalPortDeterminer(portRange: Ports.defaultQueuePortRange),
            payloadSignature: payloadSignature,
            queueServerLock: AutomaticTerminationControllerAwareQueueServerLock(
                automaticTerminationController: automaticTerminationController
            ),
            requestSenderProvider: requestSenderProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessPolicy: .workersStayAliveWhenQueueIsDepleted,
            workerConfigurations: createWorkerConfigurations(
                queueServerRunConfiguration: queueServerRunConfiguration
            )
        )
        let pollPeriod: TimeInterval = 5.0
        let queueServerTerminationWaiter = QueueServerTerminationWaiterImpl(
            pollInterval: pollPeriod,
            queueServerTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy
        )
        
        let localQueueServerRunner = LocalQueueServerRunner(
            queueServer: queueServer,
            automaticTerminationController: automaticTerminationController,
            queueServerTerminationWaiter: queueServerTerminationWaiter,
            queueServerTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy,
            pollPeriod: pollPeriod,
            newWorkerRegistrationTimeAllowance: 360.0,
            remotePortDeterminer: RemoteQueuePortScanner(
                host: LocalHostDeterminer.currentHostAddress,
                portRange: Ports.defaultQueuePortRange,
                requestSenderProvider: requestSenderProvider
            ),
            temporaryFolder: try TemporaryFolder(),
            workerDestinations: workerDestinations
        )
        try localQueueServerRunner.start(emceeVersion: emceeVersion)
    }
    
    private func createWorkerConfigurations(
        queueServerRunConfiguration: QueueServerRunConfiguration
    ) -> WorkerConfigurations {
        let configurations = WorkerConfigurations()
        for deploymentDestinationConfiguration in queueServerRunConfiguration.deploymentDestinationConfigurations {
            configurations.add(
                workerId: deploymentDestinationConfiguration.destinationIdentifier,
                configuration: queueServerRunConfiguration.workerConfiguration(
                    deploymentDestinationConfiguration: deploymentDestinationConfiguration,
                    payloadSignature: payloadSignature
                )
            )
        }
        return configurations
    }
}
