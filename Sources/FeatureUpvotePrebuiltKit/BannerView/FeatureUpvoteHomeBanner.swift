//  Created by Claude on 24/04/2026.

import FeatureUpvoteKit
import FeatureUpvoteKitUI
import FeatureUpvoteL10n
import SwiftUI

public struct FeatureUpvoteHomeBanner: View {
    private var viewModel: FeatureUpvoteHomeBannerViewModel

    private var config = Config()
    private let onShowAll: () -> Void
    private let onClose: () -> Void

    public init(
        viewModel: FeatureUpvoteHomeBannerViewModel,
        onShowAll: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onShowAll = onShowAll
        self.onClose = onClose
    }

    public var body: some View {
        if !viewModel.features.isEmpty {
            cardContent
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            VStack(spacing: 8) {
                ForEach(viewModel.features) { feature in
                    featureRow(feature)
                    if viewModel.features.last != feature {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 4)

            HStack {
                seeAllButton
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .modifier {
            if #available(iOS 26.0, macOS 26.0, *) {
                $0.glassEffect(.regular, in: .rect(cornerRadius: 16))
                    .clipShape(.rect(cornerRadius: 16))
            } else {
                $0.background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.accentColor.opacity(0.08))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.15), lineWidth: 1)
                        }
                }
            }
        }
        .frame(maxWidth: 450)
        .frame(maxWidth: .infinity)
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.FeatureVoting.HomeBanner.title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(L10n.FeatureVoting.HomeBanner.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                viewModel.handleClose()
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .modifier {
                        if #available(iOS 26, macOS 26, *) {
                            $0.glassEffect(.regular.interactive(), in: Circle())
                        } else {
                            $0.contentShape(.rect)
                                .background(.ultraThinMaterial)
                                .clipShape(.circle)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.FeatureVoting.HomeBanner.closeAccessibilityLabel))
        }
    }

    private func featureRow(_ feature: FeatureUpvoteKit.Feature) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TagView(title: feature.tag)
                    .disabled()
                    .tint(config.tagColorMap[feature.tag])
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VoteButton(
                voteCount: feature.voteCount,
                hasVoted: viewModel.votedFeatureIDs.contains(feature.id)
            )
            .onVote { isVoting in
                try await viewModel.handleVote(feature: feature, isVoting: isVoting)
            }
            .size(44.scaledToMac())
        }
    }

    private var seeAllButton: some View {
        Button(action: {
            viewModel.handleShowAll()
            onShowAll()
        }) {
            Text(L10n.FeatureVoting.HomeBanner.showAll)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .modifier {
                    if #available(iOS 26, macOS 26, *) {
                        $0.glassEffect(.regular.interactive(), in: Capsule())
                    } else {
                        $0.background(Color.accentColor.opacity(0.12), in: Capsule())
                    }
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }
}

public extension FeatureUpvoteHomeBanner {
    struct Config {
        var tagColorMap: [String: Color] = [:]
    }

    func tagColorMap(_ value: [String: Color]) -> Self {
        var copy = self
        copy.config.tagColorMap = value
        return copy
    }
}
