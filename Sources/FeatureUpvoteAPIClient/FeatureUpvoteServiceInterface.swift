//
//  FeatureUpvoteServiceInterface.swift
//
//
//  Created by Long Vu on 17/06/2023.
//

import Foundation

package struct L10nValue: Decodable {
    public let key: String?
    public let tableName: String?
    public let args: [CVarArg]
    public let fallback: String

    public func asString(_ bundle: Bundle) -> String {
        if let key {
            let format = NSLocalizedString(
                key,
                tableName: tableName,
                bundle: bundle,
                value: "",
                comment: ""
            )
            return String(format: format, locale: Locale.current, arguments: args)
        }
        return fallback
    }

    enum CodingKeys: String, CodingKey {
        case key
        case tableName
        case args
        case fallback
    }

    public init(
        key: String?,
        tableName: String?,
        args: [CVarArg],
        fallback: String
    ) {
        self.key = key
        self.tableName = tableName
        self.args = args
        self.fallback = fallback
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.key = try container.decodeIfPresent(String.self, forKey: .key)
        self.tableName = try container.decodeIfPresent(String.self, forKey: .tableName)
        if let fallback = try container.decodeIfPresent(String.self, forKey: .fallback) {
            self.fallback = fallback
        } else {
            throw NSError(
                domain: "",
                code: 1_000,
                userInfo: [NSLocalizedDescriptionKey: "Can not decode fallback property"]
            )
        }

        var argsContainer = try container.nestedUnkeyedContainer(forKey: .args)

        var args: [CVarArg] = []

        while !argsContainer.isAtEnd {
            if let intValue = try? argsContainer.decode(Int.self) {
                args.append(intValue)
            }

            if let doubleValue = try? argsContainer.decode(Double.self) {
                args.append(doubleValue)
            }

            if let stringValue = try? argsContainer.decode(String.self) {
                args.append(stringValue)
            }
        }

        self.args = args
    }
}

package struct FeatureObject: Decodable {
    public let id: String
    public let name: L10nValue
    public let description: L10nValue
    public let tag: L10nValue
    public let voteCount: UInt
    public let createdAt: Date
    public let updatedAt: Date
}

package protocol FeatureUpvoteServiceInterface {
    func features(projectID: String) async throws -> [FeatureObject]
    func votedFeatureIDs(projectID: String, userID: String) async throws -> [String]
    func vote(projectID: String, featureID: String, userID: String) async throws -> FeatureObject
    func unvote(projectID: String, featureID: String, userID: String) async throws -> FeatureObject
    func createFeature(
        name: String,
        description: String,
        projectID: String,
        userID: String
    ) async throws -> FeatureObject
}
