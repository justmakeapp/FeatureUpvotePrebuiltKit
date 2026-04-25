//  Created by Claude on 24/04/2026.

import AnalyticsProtocol
import FeatureUpvoteAPIClient
import FeatureUpvoteKit
import FeatureUpvoteL10n
import Foundation
import FoundationX
import FUService
import Logging

@MainActor
@Observable
public final class FeatureUpvoteHomeBannerViewModel {
    private static var loggedImpressionForSession = false

    public var features: [FeatureUpvoteKit.Feature] = []
    public var votedFeatureIDs: Set<String> = []
    public private(set) var didFetch = false

    private let userID: String
    private let projectID: String
    private let analytics: AnalyticServiceInterface
    private let provider: FeatureUpvoteServiceInterface
    private let logger = Logger(label: String(describing: FeatureUpvoteHomeBannerViewModel.self))

    public init(
        userID: String,
        projectID: String,
        baseUrl: URL,
        xApiKey: String,
        analytics: AnalyticServiceInterface
    ) {
        self.userID = userID
        self.projectID = projectID
        self.provider = FeatureUpvoteAPIClient(baseUrl: baseUrl, xApiKey: xApiKey)
        self.analytics = analytics
    }

    init(
        userID: String,
        projectID: String,
        provider: FeatureUpvoteServiceInterface,
        analytics: AnalyticServiceInterface
    ) {
        self.userID = userID
        self.projectID = projectID
        self.provider = provider
        self.analytics = analytics
    }

    public func fetchTopFeaturesIfNeeded() async {
        guard !didFetch else { return }
        didFetch = true
        await fetchTopFeatures()
    }

    private func fetchTopFeatures() async {
        let userID = userID
        let projectID = projectID
        do {
            async let featuresRequest = provider.features(projectID: projectID)
            async let votedIDsRequest = provider.votedFeatureIDs(projectID: projectID, userID: userID)

            let fetchedFeatures = try await featuresRequest
            let fetchedVotedIDs = try await votedIDsRequest

            let filtered = fetchedFeatures
                .filter { feature in
                    let key = feature.tag.key?.lowercased()
                    return key != "tag.done" && key != "tag.closed"
                }
                .sorted { lhs, rhs in
                    lhs.voteCount != rhs.voteCount
                        ? lhs.voteCount > rhs.voteCount
                        : lhs.updatedAt > rhs.updatedAt
                }
                .prefix(3)

            features = filtered.map { object in
                FeatureUpvoteKit.Feature(
                    id: object.id,
                    name: object.name.asString { _ in FeatureUpvoteL10n.L10n.bundle },
                    description: object.description.asString { _ in FeatureUpvoteL10n.L10n.bundle },
                    tag: object.tag.asString { _ in FeatureUpvoteL10n.L10n.bundle },
                    voteCount: object.voteCount,
                    createdAt: object.createdAt,
                    updatedAt: object.updatedAt
                )
            }
            votedFeatureIDs = Set(fetchedVotedIDs)
            logImpressionIfNeeded()
        } catch {
            if let nsError = error as NSError?,
               nsError.domain == NSURLErrorDomain,
               nsError.code == NSURLErrorCancelled {
                return
            }
            logger.error("❌ Failed to load banner features: \(error)")
            features = []
            analytics.log(FeatureUpvoteEvent.featureUpvoteBannerLoadError(message: error.localizedDescription))
        }
    }

    private func logImpressionIfNeeded() {
        guard !features.isEmpty, !Self.loggedImpressionForSession else { return }
        Self.loggedImpressionForSession = true
        analytics.log(FeatureUpvoteEvent.featureUpvoteBannerShown)
    }

    public func handleVote(feature: FeatureUpvoteKit.Feature, isVoting: Bool) async throws {
        let userID = userID
        let projectID = projectID
        let previousVotedIDs = votedFeatureIDs

        if isVoting {
            votedFeatureIDs.insert(feature.id)
        } else {
            votedFeatureIDs.remove(feature.id)
        }

        do {
            if isVoting {
                _ = try await provider.vote(projectID: projectID, featureID: feature.id, userID: userID)
                analytics.log(FeatureUpvoteEvent.featureUpvoteBannerVote(featureID: feature.id))
            } else {
                _ = try await provider.unvote(projectID: projectID, featureID: feature.id, userID: userID)
                analytics.log(FeatureUpvoteEvent.featureUpvoteBannerUnvote(featureID: feature.id))
            }
        } catch {
            votedFeatureIDs = previousVotedIDs
            analytics.log(isVoting
                ? FeatureUpvoteEvent.voteFeatureError(featureID: feature.id, message: error.localizedDescription)
                : FeatureUpvoteEvent.unvoteFeatureError(featureID: feature.id, message: error.localizedDescription))
            throw error
        }
    }

    public func handleShowAll() {
        analytics.log(FeatureUpvoteEvent.featureUpvoteBannerShowAllTapped)
    }

    public func handleClose() {
        analytics.log(FeatureUpvoteEvent.featureUpvoteBannerDismissed)
    }
}
