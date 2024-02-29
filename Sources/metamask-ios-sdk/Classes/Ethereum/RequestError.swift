//
//  RequestError.swift
//

import Foundation
import Combine

// MARK: - RequestError

public struct RequestError: Codable, Error {
    public let code: Int
    public let message: String
    public let data: RequestErrorData?

    public init(from info: [String: Any]) {
        code = info["code"] as? Int ?? -1
        if let dataInfo = (info["data"] as? [String: Any]) {
            data = RequestErrorData(from: dataInfo)
        } else {
            data = nil
        }
        message = info["message"] as? String ?? ErrorType(rawValue: code)?.message ?? ""
    }

    public var localizedDescription: String {
        message
    }
    
    public static var connectError: RequestError {
        RequestError(from: [
            "code": -101,
            "message": "Not connected. Please call connect(:Dapp) first"
        ])
    }
    
    public static var invalidUrlError: RequestError {
        RequestError(from: [
            "code": -101,
            "message": "Please use a valid url in AppMetaData"
        ])
    }
    
    public static var invalidTitleError: RequestError {
        RequestError(from: [
            "code": -101,
            "message": "Please use a valid name in AppMetaData"
        ])
    }
    
    public static var invalidBatchRequestError: RequestError {
        RequestError(from: [
            "code": -101,
            "message": "Something went wrong, check that your requests are valid"
        ])
    }
    
    static func failWithError(_ error: RequestError) -> EthereumPublisher {
        let passthroughSubject = PassthroughSubject<Any, RequestError>()
        let publisher: EthereumPublisher = passthroughSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        passthroughSubject.send(completion: .failure(error))
        return publisher
    }
}

public extension RequestError {
    var codeType: ErrorType {
        ErrorType(rawValue: code) ?? .unknownError
    }
}

public struct RequestErrorData: Codable  {
    public var message: String?
    public var data: ErrorData?
    
    public init(from info: [String: Any]) {
        message = info["message"] as? String
        if let dataInfo = (info["data"] as? [String: Any]) {
            data = ErrorData(from: dataInfo)
        } else {
            data = nil
        }
    }
}

public struct ErrorData: Codable  {
    public var message: String?
    public var data: String?
    
    public init(from info: [String: Any]) {
        message = info["message"] as? String
        data = info["data"] as? String
    }
}
