import DistRun
import DistWork
import EventBus
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class QueueHTTPRESTServerTests: XCTestCase {
    let restServer = QueueHTTPRESTServer()
    let workerConfigurations = WorkerConfigurations()
    let workerId = "worker"
    let requestId = "requestId"
    let queueServerAddress = "localhost"
    
    override func setUp() {
        workerConfigurations.add(
            workerId: workerId,
            configuration: WorkerConfiguration(
                testExecutionBehavior: TestExecutionBehavior(numberOfRetries: 1, numberOfSimulators: 1, environment: [:], scheduleStrategy: .progressive),
                testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 10),
                reportAliveInterval: 5.0))
    }
    
    func test__RegisterWorkerHandler() throws {
        let workerRegistrar = WorkerRegistrar(
            workerConfigurations: workerConfigurations,
            workerAlivenessTracker: FakeWorkerAlivenessTracker.alivenessTrackerWithAlwaysAliveResults())
        
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: workerRegistrar),
            bucketFetchRequestHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()),
            bucketResultHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()),
            reportAliveHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()))
        let port = try restServer.start()
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)
        
        XCTAssertFalse(workerRegistrar.isWorkerRegistered(workerId: workerId))
        XCTAssertNoThrow(try client.registerWithServer())
        XCTAssertTrue(workerRegistrar.isWorkerRegistered(workerId: workerId))
    }
    
    func test__BucketFetchHandler() throws {
        let bucket = BucketFixtures.createBucket(testEntries: [
            TestEntry(className: "class1", methodName: "m1", caseId: nil),
            TestEntry(className: "class2", methodName: "m2", caseId: nil)])
        let dequeuedBucket = DequeuedBucket(bucket: bucket, workerId: workerId, requestId: requestId)
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: DequeueResult.dequeuedBucket(dequeuedBucket))
        let bucketProvider = BucketProviderEndpoint(bucketQueue: bucketQueue)
        
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()),
            bucketFetchRequestHandler: RESTEndpointOf(actualHandler: bucketProvider),
            bucketResultHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()),
            reportAliveHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()))
        let port = try restServer.start()
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)
        
        let fetchResult = try client.fetchBucket(requestId: requestId)
        XCTAssertEqual(fetchResult, SynchronousQueueClient.BucketFetchResult.bucket(bucket))
    }
    
    func test__ResultHandler() throws {
        let bucketQueue = FakeBucketQueue(throwsOnAccept: false)
        let testingResult = TestingResultFixtures.createTestingResult(unfilteredResults: [
            TestEntryResult.lost(testEntry: TestEntry(className: "class1", methodName: "m1", caseId: nil)),
            TestEntryResult.lost(testEntry: TestEntry(className: "class2", methodName: "m2", caseId: nil))])
        
        let resultsCollector = ResultsCollector()
        
        let resultHandler = BucketResultRegistrar(
            bucketQueue: bucketQueue,
            eventBus: EventBus(),
            resultsCollector: resultsCollector)
        
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()),
            bucketFetchRequestHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()),
            bucketResultHandler: RESTEndpointOf(actualHandler: resultHandler),
            reportAliveHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()))
        let port = try restServer.start()
        
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)
        try client.send(testingResult: testingResult, requestId: requestId)
        
        XCTAssertEqual(resultsCollector.collectedResults, [testingResult])
    }
    
    func test__ReportAliveHandler() throws {
        let alivenessTracker = FakeWorkerAlivenessTracker.alivenessTrackerWithAlwaysAliveResults()
        
        restServer.setHandler(
            registerWorkerHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()),
            bucketFetchRequestHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()),
            bucketResultHandler: RESTEndpointOf(actualHandler: FakeRESTEndpoint<Int>()),
            reportAliveHandler: RESTEndpointOf(actualHandler: WorkerAlivenessEndpoint(alivenessTracker: alivenessTracker)))
        let port = try restServer.start()
        
        let client = SynchronousQueueClient(serverAddress: queueServerAddress, serverPort: port, workerId: workerId)
        try client.reportAliveness()
        
        XCTAssertEqual(alivenessTracker.alivenessForWorker(workerId: workerId), .alive)
    }
}
