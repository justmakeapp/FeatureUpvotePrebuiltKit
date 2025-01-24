//
//  FeatureUpvoteAPIClient.swift
//
//
//  Created by Long Vu on 17/06/2023.
//

import Foundation
import FoundationX
import FUService
import SwiftyJSON

public final class FeatureUpvoteAPIClient: AbstractAPIClient {
    private let baseUrl: URL
    private let xApiKey: String

    private static let decoder: JSONDecoder = {
        let v = JSONDecoder()
        v.dateDecodingStrategy = .formatted(.iso8601Formatter())
        return v
    }()

    public init(
        baseUrl: URL,
        xApiKey: String
    ) {
        self.baseUrl = baseUrl
        self.xApiKey = xApiKey
    }
}

// MARK: - FeatureUpvoteServiceInterface

extension FeatureUpvoteAPIClient: FeatureUpvoteServiceInterface {
    public func features(projectID: String) async throws -> [FeatureObject] {
        guard let url: URL = {
            guard var urlComponents = URLComponents(
                url: baseUrl.appending(path: "/features/\(projectID)"),
                resolvingAgainstBaseURL: false
            ) else {
                return nil
            }

            urlComponents.queryItems = [
                URLQueryItem(name: "limit", value: "1000"),
                URLQueryItem(name: "offset", value: "0"),
            ]

            return urlComponents.url
        }() else {
            throw URLError(.unsupportedURL)
        }

        var request = URLRequest(url: url)
            .xApiKey(xApiKey)

        request.httpMethod = "GET"

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let data = try processResponseData(data: responseData, statusCode: httpResponse.statusCode)

        let json = JSON(data)
        let featuresData = try json["features"].rawData()

        let features: [FeatureObject] = try Self.decoder.decode([FeatureObject].self, from: featuresData)
        return features
    }

    public func feature(projectID: String, featureId: String) async throws -> FeatureObject? {
        try await features(projectID: projectID).first { $0.id == featureId }
    }

    public func votedFeatureIDs(projectID: String, userID: String) async throws -> [String] {
        guard let url: URL = {
            guard var urlComponents = URLComponents(
                url: baseUrl.appending(path: "/votedFeatures/\(projectID)"),
                resolvingAgainstBaseURL: false
            ) else {
                return nil
            }

            urlComponents.queryItems = [
                URLQueryItem(name: "userID", value: userID),
            ]

            return urlComponents.url
        }() else {
            throw URLError(.unsupportedURL)
        }

        var request = URLRequest(url: url)
            .xApiKey(xApiKey)

        request.httpMethod = "GET"

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let data = try processResponseData(data: responseData, statusCode: httpResponse.statusCode)

        let json = JSON(data)
        guard let array = json["featureIDs"].array else {
            throw NSError(
                domain: Bundle.main.bundleIdentifier!,
                code: 1_000,
                userInfo: [NSLocalizedDescriptionKey: "feature ids is empty"]
            )
        }
        let featureIDs = array.compactMap(\.string)
        return featureIDs
    }

    public func vote(projectID: String, featureID: String, userID: String) async throws -> FeatureObject {
        let url: URL = baseUrl.appending(path: "/vote/\(projectID)/\(featureID)")

        var request = URLRequest(url: url)
            .xApiKey(xApiKey)

        request.httpBody = {
            let parameters: [String: Any] = [
                "userID": userID
            ]
            return try? JSONSerialization.data(withJSONObject: parameters)
        }()
        request.httpMethod = "PUT"

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let data = try processResponseData(data: responseData, statusCode: httpResponse.statusCode)

        let json = JSON(data)
        let featureData = try json["feature"].rawData()

        let feature = try Self.decoder.decode(FeatureObject.self, from: featureData)
        return feature
    }

    public func unvote(projectID: String, featureID: String, userID: String) async throws -> FeatureObject {
        let url: URL = baseUrl.appending(path: "/unvote/\(projectID)/\(featureID)")

        var request = URLRequest(url: url)
            .xApiKey(xApiKey)

        request.httpBody = {
            let parameters: [String: Any] = [
                "userID": userID
            ]
            return try? JSONSerialization.data(withJSONObject: parameters)
        }()
        request.httpMethod = "PUT"

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let data = try processResponseData(data: responseData, statusCode: httpResponse.statusCode)
        let json = JSON(data)
        let featureData = try json["feature"].rawData()
        let feature = try Self.decoder.decode(FeatureObject.self, from: featureData)
        return feature
    }

    public func createFeature(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        projectID: String,
        userID: String
    ) async throws -> FeatureObject {
        let url: URL = baseUrl.appending(path: "/features/\(projectID)")

        var request = URLRequest(url: url)
            .xApiKey(xApiKey)

        request.httpBody = {
            let name: [String: Any] = [
                "args": [CVarArg](),
                "fallback": name
            ]
            let description: [String: Any] = [
                "args": [CVarArg](),
                "fallback": description
            ]
            let tag: [String: Any] = [
                "key": "tag.open",
                "tableName": "Localizable",
                "args": [CVarArg](),
                "fallback": "Open"
            ]

            let parameters = [
                "userID": userID,
                "features": [[
                    "id": id,
                    "name": name,
                    "description": description,
                    "tag": tag
                ] as [String: Any]]
            ]

            return try? JSONSerialization.data(withJSONObject: parameters)
        }()
        request.httpMethod = "POST"

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let data = try processResponseData(data: responseData, statusCode: httpResponse.statusCode)
        let json = JSON(data)
        let featuresData = try json["features"].rawData()
        let features: [FeatureObject] = try Self.decoder.decode([FeatureObject].self, from: featuresData)
        guard let feature = features.first else {
            throw NSError(
                domain: Bundle.main.bundleIdentifier!,
                code: 1_000,
                userInfo: [NSLocalizedDescriptionKey: "Not found feature!"]
            )
        }
        return feature
    }
}
