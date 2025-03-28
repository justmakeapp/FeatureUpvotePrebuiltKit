//
//  FeatureUpvoteServiceInterface.swift
//
//
//  Created by Long Vu on 17/06/2023.
//

import Foundation
import FoundationX

public struct FeatureObject: Decodable, Sendable {
    public let id: String
    public let name: L10nValue
    public let description: L10nValue
    public let tag: L10nValue
    public let voteCount: UInt
    public let createdAt: Date
    public let updatedAt: Date
}

public protocol FeatureUpvoteServiceInterface: Sendable {
    func features(projectID: String) async throws -> [FeatureObject]
    func feature(projectID: String, featureId: String) async throws -> FeatureObject?
    func votedFeatureIDs(projectID: String, userID: String) async throws -> [String]
    func vote(projectID: String, featureID: String, userID: String) async throws -> FeatureObject
    func unvote(projectID: String, featureID: String, userID: String) async throws -> FeatureObject
    func createFeature(
        id: String,
        name: String,
        description: String,
        projectID: String,
        userID: String
    ) async throws -> FeatureObject
}
