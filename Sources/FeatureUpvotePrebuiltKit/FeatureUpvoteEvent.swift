//
//  FeatureUpvoteEvent.swift
//  MakeFlashcard
//
//  Created by Long Vu on 18/06/2023.
//

import Foundation
import Umbrella

public enum FeatureUpvoteEvent: EventType {
    case openFeatureUpvote
    case loadFeaturesError(message: String)
    case voteFeature(featureID: String)
    case voteFeatureError(featureID: String, message: String)
    case unvoteFeature(featureID: String)
    case unvoteFeatureError(featureID: String, message: String)
    case createFeature(name: String, desc: String)
    case createFeatureError(name: String, desc: String, message: String)
    case cancelFeatureUpvote

    public func name(for _: ProviderType) -> String? {
        switch self {
        case .openFeatureUpvote:
            return "OpenFeatureUpvote"
        case .loadFeaturesError:
            return "LoadFeaturesError"
        case .voteFeature:
            return "VoteFeature"
        case .voteFeatureError:
            return "VoteFeatureError"
        case .unvoteFeature:
            return "UnvoteFeature"
        case .unvoteFeatureError:
            return "UnvoteFeatureError"
        case .createFeature:
            return "CreateFeature"
        case .createFeatureError:
            return "CreateFeatureError"
        case .cancelFeatureUpvote:
            return "CancelFeatureUpvote"
        }
    }

    public func parameters(for _: ProviderType) -> [String: Any]? {
        switch self {
        case .openFeatureUpvote, .cancelFeatureUpvote:
            return nil
        case let .loadFeaturesError(message):
            return ["message": message]
        case let .voteFeature(featureID), let .unvoteFeature(featureID):
            return ["featureID": featureID]
        case
            let .voteFeatureError(featureID, message),
            let .unvoteFeatureError(featureID, message):
            return ["featureID": featureID, "message": message]
        case let .createFeature(name, desc):
            return ["featureName": name, "featureDesc": desc]
        case let .createFeatureError(name, desc, message):
            return ["featureName": name, "featureDesc": desc, "message": message]
        }
    }
}
