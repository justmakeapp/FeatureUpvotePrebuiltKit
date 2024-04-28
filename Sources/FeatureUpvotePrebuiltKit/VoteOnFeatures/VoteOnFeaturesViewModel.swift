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

final class VoteOnFeaturesViewModel: ObservableObject {
    typealias L10n = FeatureUpvoteL10n.L10n
    let context: Context
    @Published private(set) var state = State.loading
    @Published var sortOrder: SortOrder = .reverse
    @Published var sortingType: SortType = .commingSoon

    @Published private var votedFeatureIDs: [String] = []
    @Published private var features: [FeatureObject] = []

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
                        name: Self.makeStringFromL10nValue(feature.name),
                        description: Self.makeStringFromL10nValue(feature.description),
                        tag: Self.makeStringFromL10nValue(feature.tag),
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

                let aName = Self.makeStringFromL10nValue(a.name)
                let bName = Self.makeStringFromL10nValue(b.name)

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

    private static func makeStringFromL10nValue(_ value: L10nValue) -> String {
        if let key = value.key {
            let format = L10n.localizedString(key, tableName: value.tableName)
            return String(format: format, locale: Locale.current, arguments: value.args)
        }
        return value.fallback
    }

    @MainActor
    func fetchListFeatures() async {
        do {
            let projectID = context.projectID
            async let features = context.featureUpvoteProvider.features(projectID: projectID)
            async let votedFeatureIDs = context.featureUpvoteProvider.votedFeatureIDs(
                projectID: projectID,
                userID: context.userID
            )

            let ids = try await votedFeatureIDs
            self.votedFeatureIDs = ids
            self.features = try await features
        } catch {
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

    enum SortType: Int, Hashable, CaseIterable, Identifiable {
        case alphabetical
        case createdDate
        case updatedDate
        case commingSoon

        static var allCases: [VoteOnFeaturesViewModel.SortType] = [
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
