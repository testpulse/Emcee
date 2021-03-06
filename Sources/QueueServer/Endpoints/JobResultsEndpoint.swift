import BalancingBucketQueue
import Extensions
import Foundation
import Models
import RESTMethods
import RESTServer

public final class JobResultsEndpoint: RESTEndpoint {
    private let jobResultsProvider: JobResultsProvider

    public init(jobResultsProvider: JobResultsProvider) {
        self.jobResultsProvider = jobResultsProvider
    }
    
    public func handle(decodedPayload: JobResultsRequest) throws -> JobResultsResponse {
        let jobResults = try jobResultsProvider.results(jobId: decodedPayload.jobId)
        return JobResultsResponse(jobResults: jobResults)
    }
}
