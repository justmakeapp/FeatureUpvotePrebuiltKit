//
//  VoteOnFeaturesViewModel.swift
//  MakeFlashcard
//
//  Created by Long Vu on 17/06/2023.
//

import AnalyticsProtocol
import Combine
import CombineExt
import FeatureUpvoteAPIClient
import FeatureUpvoteKit
import FeatureUpvoteL10n
import Foundation
import FoundationX
import FUService
import Logging

final class VoteOnFeaturesViewModel: ObservableObject {
    typealias L10n = FeatureUpvoteL10n.L10n
    let context: Context
    @Published private(set) var state = State.loading
    @Published var sortOrder: SortOrder = .reverse
    @Published var sortingType: SortType = .commingSoon

    @Published private var votedFeatureIDs: [String] = []
    @Published private var features: [FeatureObject] = []

    private let logger = Logger(label: String(describing: VoteOnFeaturesViewModel.self))
    private var cancellableSet: Set<AnyCancellable> = []

    init(context: Context) {
        self.context = context

        setupSubscriptions()
    }

    private func setupSubscriptions() {
        Publishers.CombineLatest4(
            $features.dropFirst(),
            $votedFeatureIDs.dropFirst().removeDuplicates(),
            $sortingType.removeDuplicates(),
            $sortOrder.removeDuplicates()
        )
        .map { features, votedFeatureIDs, sortType, sortOrder -> State in
            if features.isEmpty {
                return .empty
            } else {
                let sorted = features.sorted(
                    using: Self.makeSortDescriptors(sortType: sortType),
                    order: sortOrder
                )

                let transformed = sorted.map { feature -> FeatureUpvoteKit.Feature in
                    return .init(
                        id: feature.id,
                        name: feature.name.asString { _ in
                            L10n.bundle
                        },
                        description: feature.description.asString { _ in
                            L10n.bundle
                        },
                        tag: feature.tag.asString { _ in
                            L10n.bundle
                        },
                        voteCount: feature.voteCount,
                        createdAt: feature.createdAt,
                        updatedAt: feature.updatedAt
                    )
                }

                return .loaded(data: transformed, votedFeatureIDs: votedFeatureIDs)
            }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: \.state, on: self, ownership: .weak)
        .store(in: &cancellableSet)
    }

    private static func makeSortDescriptors(sortType: SortType) -> [CustomSortDescriptor<FeatureObject>] {
        let voteCount = CustomSortDescriptor.keyPath(\FeatureObject.voteCount)
        switch sortType {
        case .alphabetical:
            return [.init(comparator: { a, b in
                let aName = a.name.asString { _ in
                    L10n.bundle
                }
                let bName = b.name.asString { _ in
                    L10n.bundle
                }

                if aName < bName {
                    return .orderedAscending
                }
                if aName > bName {
                    return .orderedDescending
                }

                return .orderedSame
            }), voteCount]
        case .createdDate:
            return [.keyPath(\FeatureObject.createdAt), voteCount]
        case .updatedDate:
            return [.keyPath(\FeatureObject.updatedAt), voteCount]
        case .commingSoon:
            return [.init(comparator: { a, b in
                guard
                    let aKey = a.tag.key,
                    let bKey = b.tag.key,
                    let aTag = Tag(from: aKey),
                    let bTag = Tag(from: bKey)
                else {
                    return .orderedSame
                }

                if aTag < bTag {
                    return .orderedAscending
                }
                if aTag > bTag {
                    return .orderedDescending
                }

                return .orderedSame
            }), voteCount]
        }
    }

    @MainActor
    func fetchListFeatures() async {
        let userID = context.userID
        let projectID = context.projectID
        let featureUpvoteProvider = context.featureUpvoteProvider
        do {
            async let features = featureUpvoteProvider.features(projectID: projectID)
            async let votedFeatureIDs = featureUpvoteProvider.votedFeatureIDs(
                projectID: projectID,
                userID: userID
            )

            let ids = try await votedFeatureIDs
            self.votedFeatureIDs = ids
            self.features = try await features
        } catch {
            if let nsError = error as NSError? {
                if nsError.domain == NSURLErrorDomain &&
                    nsError.code == NSURLErrorCancelled {
                    // Ignore cancellation
                    try? await Task.sleep(for: .seconds(1))
                    await fetchListFeatures()

                    return
                }

                // Handle real error
                logger.debug("\(nsError)")
                return
            }
            logger.error("❌ Failed to load features: \(error)")
            state = .error(error)
            let event = FeatureUpvoteEvent.loadFeaturesError(message: error.localizedDescription)
            context.analytics.log(event)
        }
    }
}

extension VoteOnFeaturesViewModel {
    struct Context {
        let projectID: String
        let userID: String
        let featureUpvoteProvider: FeatureUpvoteServiceInterface
        let analytics: AnalyticServiceInterface
    }

    enum State {
        case empty
        case loading
        case loaded(data: [FeatureUpvoteKit.Feature], votedFeatureIDs: [String])
        case error(Error)
    }

    enum SortType: Int, Hashable, CaseIterable, Identifiable, Sendable {
        case alphabetical
        case createdDate
        case updatedDate
        case commingSoon

        static let allCases: [VoteOnFeaturesViewModel.SortType] = [
            .commingSoon,
            .alphabetical,
            .createdDate,
            .updatedDate
        ]

        var id: Int {
            rawValue
        }

        var title: String {
            switch self {
            case .alphabetical:
                return L10n.Sorting.alphabetical
            case .createdDate:
                return L10n.Sorting.createdDate
            case .updatedDate:
                return L10n.Sorting.updatedDate
            case .commingSoon:
                return L10n.Sorting.commingSoon
            }
        }

        var systemImageName: String {
            switch self {
            case .alphabetical:
                return "a.square"
            case .createdDate, .updatedDate:
                return "calendar"
            case .commingSoon:
                return "shippingbox"
            }
        }
    }

    enum Tag: Int, CustomStringConvertible, Hashable, Comparable {
        case closed
        case done
        case open
        case inProgress

        init?(from stringValue: String) {
            switch stringValue.lowercased() {
            case "tag.closed":
                self = .closed
            case "tag.done":
                self = .done
            case "tag.open":
                self = .open
            case "tag.inprogress":
                self = .inProgress
            default:
                return nil
            }
        }

        var description: String {
            switch self {
            case .open:
                return L10n.Tag.open
            case .inProgress:
                return L10n.Tag.inProgress
            case .done:
                return L10n.Tag.done
            case .closed:
                return L10n.Tag.closed
            }
        }

        static func < (lhs: VoteOnFeaturesViewModel.Tag, rhs: VoteOnFeaturesViewModel.Tag) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
