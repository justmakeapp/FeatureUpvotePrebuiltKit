//
//  VoteOnFeaturesView.swift
//  MakeFlashcard
//
//  Created by Long Vu on 17/06/2023.
//

import Algorithms
import AnalyticsProtocol
import FeatureUpvoteAPIClient
import FeatureUpvoteKit
import FeatureUpvoteKitUI
import FeatureUpvoteL10n
import SwiftUI
import ViewComponent

public struct VoteOnFeaturesView: View {
    typealias L10n = FeatureUpvoteL10n.L10n

    @StateObject var viewModel: VoteOnFeaturesViewModel
    @State private var selectedTags: Set<String> = []
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    @State private var error: Error?

    @State private var navigationPath: [String] = []

    private let analytics: AnalyticServiceInterface

    private let tagColorMap = [
        VoteOnFeaturesViewModel.Tag.open.description: Color.accentColor,
        VoteOnFeaturesViewModel.Tag.inProgress.description: Color.orange,
        VoteOnFeaturesViewModel.Tag.done.description: Color.purple,
        VoteOnFeaturesViewModel.Tag.closed.description: Color.gray,
    ]

    public init(
        projectID: String,
        userID: String,
        baseUrl: URL,
        xApiKey: String,
        analytics: AnalyticServiceInterface
    ) {
        let featureUpvoteProvider = FeatureUpvoteAPIClient(baseUrl: baseUrl, xApiKey: xApiKey)
        let ctx = VoteOnFeaturesViewModel.Context(
            projectID: projectID,
            userID: userID,
            featureUpvoteProvider: featureUpvoteProvider,
            analytics: analytics
        )
        _viewModel = .init(wrappedValue: VoteOnFeaturesViewModel(context: ctx))
        self.analytics = analytics
    }

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .alert(using: $error, content: { error in
                    Alert(title: Text(L10n.Error.title), message: Text(error.localizedDescription))
                })
                .onAppear {
                    analytics.log(FeatureUpvoteEvent.openFeatureUpvote)
                }
                .onDisappear {
                    analytics.log(FeatureUpvoteEvent.cancelFeatureUpvote)
                }
                .navigationTitle(Text(L10n.voteOnFeatures))
                .navigationDestination(for: String.self, destination: { _ in
                    CreateNewFeatureView(
                        projectID: viewModel.context.projectID,
                        userID: viewModel.context.userID,
                        featureUpvoteProvider: viewModel.context.featureUpvoteProvider,
                        analytics: analytics
                    )
                    .onDisappear {
                        Task {
                            await viewModel.fetchListFeatures()
                        }
                    }
                })
                .searchable(text: $searchText)
                .toolbar {
                    if navigationPath.isEmpty {
                        #if os(macOS)

                            ToolbarItemGroup {
                                sortMenuView
                                closeButton
                            }

                        #endif

                        #if os(iOS)
                            ToolbarItem(placement: .navigationBarLeading) {
                                closeButton
                            }
                            ToolbarItemGroup {
                                sortMenuView
                            }
                        #endif

                        ToolbarItem(placement: {
                            #if os(iOS)
                                return .navigationBarTrailing
                            #endif

                            #if os(macOS)
                                return .confirmationAction
                            #endif
                        }()) {
                            NavigationLink(L10n.Action.create, value: "creation-view")
                            #if os(macOS)
                                .buttonStyle(.borderedProminent)
                            #endif
                        }
                    }
                }
        }
        #if os(macOS)
        .frame(width: 500, height: 400)
        #endif
        .task {
            await viewModel.fetchListFeatures()
        }
    }

    @ViewBuilder
    private var closeButton: some View {
        #if os(macOS)
            Button(L10n.Action.cancel) {
                dismiss()
            }
        #endif

        #if os(iOS)
            CloseButton {
                dismiss()
            }
        #endif
    }

    private var sortMenuView: some View {
        Menu(L10n.Sorting.sortBy, systemImage: "line.3.horizontal.decrease.circle") {
            Picker("", selection: $viewModel.sortingType) {
                ForEach(VoteOnFeaturesViewModel.SortType.allCases) { sortType in
                    Label(sortType.title, systemImage: sortType.systemImageName)
                        .tag(sortType)
                }
            }
            .pickerStyle(.inline)

            Divider()

            Picker("", selection: $viewModel.sortOrder) {
                Text(L10n.SortOrder.ascending)
                    .tag(SortOrder.forward)

                Text(L10n.SortOrder.descending)
                    .tag(SortOrder.reverse)
            }
            .pickerStyle(.inline)
        }
        #if os(macOS)
        .menuStyle(.borderedButton)
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .empty:
            CustomEmptyView(title: L10n.empty)

        case let .error(error):
            VStack {
                Image(systemName: "xmark.octagon.fill")
                    .font(.title)
                    .foregroundColor(.red)

                Text(error.localizedDescription)
                    .foregroundColor(.secondary)
            }

        case .loading:
            ProgressView()

        case let .loaded(data, votedFeatureIds):
            let allTags: [String] = Array(data.map(\.tag).uniqued())
            let filterdData: [FeatureUpvoteKit.Feature] = {
                var result: [FeatureUpvoteKit.Feature] = data
                if !selectedTags.isEmpty {
                    result = data.filter { selectedTags.contains($0.tag) }
                }
                if !searchText.isEmpty {
                    result = result.filter { feature in
                        let sample = [feature.name, feature.description].joined(separator: " ")
                        return sample.lowercased().contains(searchText.lowercased())
                    }
                }

                return result
            }()

            FeatureUpvoteView(data: filterdData) { feature in
                FeatureCellView(
                    title: feature.name,
                    description: feature.description,
                    tag: feature.tag
                ) {
                    VoteButton(voteCount: feature.voteCount, hasVoted: votedFeatureIds.contains(feature.id))
                        .onVote { [context = viewModel.context] isVote in
                            let featureID = feature.id
                            do {
                                if isVote {
                                    analytics.log(FeatureUpvoteEvent.voteFeature(featureID: featureID))

                                    _ = try await context.featureUpvoteProvider.vote(
                                        projectID: context.projectID,
                                        featureID: featureID,
                                        userID: context.userID
                                    )
                                } else {
                                    analytics.log(FeatureUpvoteEvent.unvoteFeature(featureID: featureID))
                                    _ = try await context.featureUpvoteProvider.unvote(
                                        projectID: context.projectID,
                                        featureID: featureID,
                                        userID: context.userID
                                    )
                                }
                            } catch {
                                await MainActor.run {
                                    self.error = error
                                    if isVote {
                                        let event = FeatureUpvoteEvent.voteFeatureError(
                                            featureID: featureID,
                                            message: error.localizedDescription
                                        )
                                        analytics.log(event)
                                    } else {
                                        let event = FeatureUpvoteEvent.unvoteFeatureError(
                                            featureID: featureID,
                                            message: error.localizedDescription
                                        )
                                        analytics.log(event)
                                    }
                                }
                            }
                        }
                }
                .tagColorMap(tagColorMap)
            } headerBuilder: {
                TagFilterView(tags: allTags, selectedTags: $selectedTags)
                    .tagColorMap(tagColorMap)
            }
        }
    }
}

extension VoteOnFeaturesView {
    // MARK: - CreateNewFeatureView

    struct CreateNewFeatureView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var name = ""
        @State private var desc = ""
        @State private var error: Error?
        @State private var canPress = true
        let projectID: String
        let userID: String
        let featureUpvoteProvider: FeatureUpvoteServiceInterface
        let analytics: AnalyticServiceInterface

        var body: some View {
            contentView
                .alert(using: $error, content: { error in
                    Alert(title: Text(L10n.Error.title), message: Text(error.localizedDescription))
                })
                .navigationTitle(Text(L10n.Feature.new))
                .toolbar {
                    ToolbarItem(placement: {
                        #if os(iOS)
                            return .navigationBarTrailing
                        #endif

                        #if os(macOS)
                            return .confirmationAction
                        #endif
                    }()) {
                        Button {
                            Task {
                                await handleCreate()
                            }
                        } label: {
                            Text(L10n.Action.create)
                        }
                    }
                }
        }

        private var contentView: some View {
            Form {
                TextField(L10n.Feature.name, text: $name)
                TextField(L10n.Feature.desc, text: $desc)
            }
            #if os(macOS)
            .padding()
            #endif
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }

        @MainActor
        private func handleCreate() async {
            guard canPress else {
                return
            }

            canPress = false

            do {
                guard name.count > 10 else {
                    throw FeatureUpvoteL10n.L10n.Error.featureNameShoudMoreThanXCharacters(10)
                }
                guard desc.count > 10 else {
                    throw FeatureUpvoteL10n.L10n.Error.featureDescShoudMoreThanXCharacters(10)
                }
                let event = FeatureUpvoteEvent.createFeature(
                    name: name,
                    desc: desc
                )
                analytics.log(event)
                _ = try await featureUpvoteProvider.createFeature(
                    name: name,
                    description: desc,
                    projectID: projectID,
                    userID: userID
                )
                dismiss.callAsFunction()
            } catch {
                self.error = error
                self.canPress = true

                let event = FeatureUpvoteEvent.createFeatureError(
                    name: name,
                    desc: desc,
                    message: error.localizedDescription
                )
                analytics.log(event)
            }
        }
    }
}
