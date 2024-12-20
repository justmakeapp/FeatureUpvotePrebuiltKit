//
//  FeatureUpvoteBottomCardViewController.swift
//  MakeFlashcard
//
//  Created by Long Vu on 18/06/2023.
//

// import AnalyticsProtocol
// import AppFoundation
// import AppFoundationUI
// import BottomCard
// import Combine
// import FeatureUpvoteKitUI
// import FeatureUpvoteServiceInterface
// import Foundation
// import SnapKit
// import UIKit
// import XCoordinator
//
// final class FeatureUpvoteBottomCardViewController: ReactiveBaseViewController {
//    var mainWindowRouter: WeakRouter<MainWindowRoute>?
//    private lazy var contentView: UIHostingView<ContentView> = {
//        let rootView = ContentView(viewModel: viewModel)
//
//        return .init(rootView: rootView)
//    }()
//
//    private let viewModel: FeatureUpvoteBottomCardViewModel
//
//    init(context: FeatureUpvoteBottomCardViewModel.Context) {
//        self.viewModel = .init(context: context)
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        view.layer.cornerRadius = 10
//        view.layer.masksToBounds = true
//        view.backgroundColor = .systemBackground
//
//        view.addSubview(contentView)
//
//        contentView.snp.makeConstraints {
//            $0.edges.equalToSuperview()
//        }
//
//        setupPermanentSubscriptions()
//    }
//
//    func setupPermanentSubscriptions() {
//        cancelPermanentSubscriptions()
//
//        viewModel.userActionSubject
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] action in
//                switch action {
//                case .dismiss:
//                    self?.mainWindowRouter?.trigger(.dismiss, with: .init(animated: true))
//                }
//            }
//            .store(in: &permanentCancellableSet)
//    }
// }
//
// final class FeatureUpvoteBottomCardViewModel: BaseViewModel, ObservableObject {
//    private let context: Context
//    let userActionSubject: PassthroughSubject<UserAction, Never> = .init()
//
//    private(set) lazy var voteOnFeaturesViewModel: VoteOnFeaturesViewModel = {
//        let ctx = VoteOnFeaturesViewModel.Context(
//            userID: context.userID,
//            featureUpvoteProvider: context.featureUpvoteProvider,
//            analytics: context.analytics
//        )
//        return .init(context: ctx)
//    }()
//
//    init(context: Context) {
//        self.context = context
//        super.init()
//    }
//
//    struct Context {
//        let userID: String
//        let featureUpvoteProvider: FeatureUpvoteServiceInterface
//        let analytics: AnalyticServiceInterface
//    }
//
//    enum UserAction {
//        case dismiss
//    }
// }
//
// extension FeatureUpvoteBottomCardViewController {
//    struct ContentView: View {
//        @ObservedObject var viewModel: FeatureUpvoteBottomCardViewModel
//        @State private var isShowVoteOnFeatures = false
//        var body: some View {
//            FeatureUpvoteBottomCard(primaryAction: {
//                isShowVoteOnFeatures = true
//            }, secondaryAction: {
//                dismiss()
//            })
//            .background(Color.systemBackground)
//            .cornerRadius(14.scaledToMac())
//            .sheet(isPresented: $isShowVoteOnFeatures) {
//                VoteOnFeaturesView(viewModel: viewModel.voteOnFeaturesViewModel)
//                    .onDisappear {
//                        dismiss()
//                    }
//            }
//        }
//
//        private func dismiss() {
//            viewModel.userActionSubject.send(.dismiss)
//        }
//    }
// }
//
// extension FeatureUpvoteBottomCardViewController: PresentationBehavior {
//    var bottomCardPresentationContentSizing: BottomCardPresentationContentSizing {
//        return .autoLayout
//    }
// }
