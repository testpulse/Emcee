import Foundation
import RequestSender

public final class QueueVersionRequest: NetworkRequest {
    public typealias Response = QueueVersionResponse
    
    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.queueVersion.withLeadingSlash
    public let payload: QueueVersionPayload? = QueueVersionPayload()

    public init() {}
}

public final class QueueVersionPayload: Codable {
    public init() {}
}
