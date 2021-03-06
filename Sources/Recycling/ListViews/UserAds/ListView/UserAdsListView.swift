//
//  Copyright © 2019 FINN AS. All rights reserved.
//

import UIKit

public protocol UserAdsListViewDelegate: AnyObject {
    func userAdsListViewDidStartRefreshing(_ userAdsListView: UserAdsListView)
    func userAdsListViewEmphasizedActionWasTapped(_ userAdsListView: UserAdsListView)
    func userAdsListViewEmphasizedActionWasCancelled(_ userAdsListView: UserAdsListView)
    func userAdsListViewEmphasized(_ userAdsListView: UserAdsListView, textFor rating: HappinessRating) -> String?
    func userAdsListViewEmphasized(_ userAdsListView: UserAdsListView, didSelectRating rating: HappinessRating)

    func userAdsListView(_ userAdsListView: UserAdsListView, userAdsListHeaderView: UserAdsListHeaderView, didTapSeeMoreButton button: Button)
    func userAdsListView(_ userAdsListView: UserAdsListView, didTapCreateNewAdButton button: Button)
    func userAdsListView(_ userAdsListView: UserAdsListView, didTapSeeAllAdsButton button: Button)
    func userAdsListView(_ userAdsListView: UserAdsListView, didSelectItemAtIndex indexPath: IndexPath)
    func userAdsListView(_ userAdsListView: UserAdsListView, willDisplayItemAtIndex indexPath: IndexPath)
    func userAdsListView(_ userAdsListView: UserAdsListView, didScrollInScrollView scrollView: UIScrollView)
    func userAdsListView(_ userAdsListView: UserAdsListView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
}

public protocol UserAdsListViewDataSource: AnyObject {
    var emphasizedActionHasBeenCollapsed: Bool { get }
    var emphasizedActionShowRatingView: Bool { get }

    func numberOfSections(in userAdsListView: UserAdsListView) -> Int
    func sectionNumberForEmphasizedAction(in userAdsListView: UserAdsListView) -> Int?
    func userAdsListView(_ userAdsListView: UserAdsListView, shouldDisplayInactiveSectionAt indexPath: IndexPath) -> Bool
    func userAdsListView(_ userAdsListView: UserAdsListView, numberOfRowsInSection section: Int) -> Int
    func userAdsListView(_ userAdsListView: UserAdsListView, modelAtIndex section: Int) -> UserAdsListHeaderViewModel
    func userAdsListView(_ userAdsListView: UserAdsListView, modelAtIndex indexPath: IndexPath) -> UserAdsListViewModel
    func userAdsListView(_ userAdsListView: UserAdsListView, loadImageForModel model: UserAdsListViewModel, imageWidth: CGFloat, completion: @escaping ((UIImage?) -> Void))
    func userAdsListView(_ userAdsListView: UserAdsListView, cancelLoadingImageForModel model: UserAdsListViewModel, imageWidth: CGFloat)
}

public class UserAdsListView: UIView {
    // MARK: - Internal properties

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = RefreshControl(frame: .zero)
        refreshControl.delegate = self
        return refreshControl
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(withAutoLayout: true)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserAdsListViewNewAdCell.self)
        tableView.register(UserAdsListViewCell.self)
        tableView.register(UserAdsListViewSeeAllAdsCell.self)
        tableView.register(UserAdsListEmphasizedActionCell.self)
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.backgroundColor = .bgPrimary
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.estimatedSectionHeaderHeight = 48
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        tableView.refreshControl = refreshControl
        return tableView
    }()

    private weak var delegate: UserAdsListViewDelegate?
    private weak var dataSource: UserAdsListViewDataSource?

    private let emptyTableViewSectionCount = 1
    private let numberOfRowsInFirstOrLastSection = 1

    private let firstSection = 0
    private var lastSection: Int {
        return (dataSource?.numberOfSections(in: self) ?? 1) - 1
    }

    // MARK: - Public properties

    public enum ToastType: Equatable {
        case success
        case error
    }

    public enum ToastPlacement: Equatable {
        case top
        case bottom
    }

    public var isEditing: Bool { return tableView.isEditing }
    public var isEmpty: Bool { return (dataSource?.userAdsListView(self, numberOfRowsInSection: 1) ?? 0 ) == 0}
    public private(set) var hasGivenRating = false

    // MARK: - Setup

    public init(delegate: UserAdsListViewDelegate, dataSource: UserAdsListViewDataSource) {
        super.init(frame: .zero)
        self.delegate = delegate
        self.dataSource = dataSource
        setup()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        addSubview(tableView)
        tableView.fillInSuperview()
    }

    public func showToastView(type: ToastType, placement: ToastPlacement, text: String, timeOut: Double, toastAction: ToastAction? = nil) {
        let successToastView = ToastView(style: .success, buttonStyle: .normal)
        successToastView.action = toastAction

        let errorToastView = ToastView(style: .error, buttonStyle: .normal)
        errorToastView.action = toastAction

        switch (type, placement) {
        case (.success, .top):
            successToastView.text = text
            successToastView.presentFromTop(view: self, animateOffset: 0, timeOut: timeOut)
        case (.success, .bottom):
            successToastView.text = text
            successToastView.presentFromBottom(view: self, animateOffset: 0, timeOut: timeOut)

        case (.error, .top):
            errorToastView.text = text
            errorToastView.presentFromTop(view: self, animateOffset: 0, timeOut: timeOut)
        case (.error, .bottom):
            errorToastView.text = text
            errorToastView.presentFromBottom(view: self, animateOffset: 0, timeOut: timeOut)
        }
    }

    // MARK: - Public

    public func reloadData() {
        endRefreshing()
        tableView.reloadData()
    }

    public func endRefreshing() {
        refreshControl.endRefreshing()
    }

    public func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        tableView.insertRows(at: indexPaths, with: animation)
    }

    public func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        tableView.deleteRows(at: indexPaths, with: animation)
    }

    public func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        tableView.reloadRows(at: indexPaths, with: animation)
    }

    public func deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        tableView.deleteSections(sections, with: animation)
    }

    public func reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        tableView.reloadSections(sections, with: animation)
    }

    public func scrollToTop() {
        tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: true)
    }
}

// MARK: - UITableViewDelegate

extension UserAdsListView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == firstSection || indexPath.section == lastSection { return }
        delegate?.userAdsListView(self, didSelectItemAtIndex: indexPath)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.userAdsListView(self, didScrollInScrollView: scrollView)
    }

    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return delegate?.userAdsListView(self, editActionsForRowAt: indexPath)
    }
}

// MARK: - UITableViewDataSource

extension UserAdsListView: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        if isEmpty { return emptyTableViewSectionCount }
        return (dataSource?.numberOfSections(in: self) ?? 0)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case firstSection, lastSection: return nil
        default:
            let headerView = UserAdsListHeaderView(atSection: section)
            headerView.delegate = self

            if let model = dataSource?.userAdsListView(self, modelAtIndex: section) {
                headerView.model = model
            }

            return headerView
        }
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let emphasizedSection = dataSource?.sectionNumberForEmphasizedAction(in: self) ?? firstSection
        switch section {
        // We don't want to show the sectionHeader for the new-ad-button, all-ads-button, and emphasizedAd-action-ad
        case firstSection, lastSection, emphasizedSection: return CGFloat.leastNonzeroMagnitude
        default: return UITableView.automaticDimension
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isEmpty { return numberOfRowsInFirstOrLastSection }
        if section == firstSection || section == lastSection { return numberOfRowsInFirstOrLastSection }

        return dataSource?.userAdsListView(self, numberOfRowsInSection: section) ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let colors: [UIColor] = [.toothPaste, .mint, .banana, .salmon]
        let color = colors[indexPath.row % 4]

        switch indexPath.section {
        case firstSection:
            let newAdCell = tableView.dequeue(UserAdsListViewNewAdCell.self, for: indexPath)
            newAdCell.delegate = self
            if let model = dataSource?.userAdsListView(self, modelAtIndex: indexPath) {
                newAdCell.model = model
            }
            return newAdCell
        case lastSection:
            let seeAllAdsCell = tableView.dequeue(UserAdsListViewSeeAllAdsCell.self, for: indexPath)
            seeAllAdsCell.delegate = self
            if let model = dataSource?.userAdsListView(self, modelAtIndex: indexPath) {
                seeAllAdsCell.model = model
            }
            return seeAllAdsCell
        default:
            if let emphasizedSection = dataSource?.sectionNumberForEmphasizedAction(in: self), indexPath.section == emphasizedSection {
                let cell = tableView.dequeue(UserAdsListEmphasizedActionCell.self, for: indexPath)
                cell.loadingColor = color
                cell.dataSource = self
                cell.delegate = self

                let actionHasBeenCollapsed = dataSource?.emphasizedActionHasBeenCollapsed ?? false
                cell.shouldShowAction = !actionHasBeenCollapsed
                if let model = dataSource?.userAdsListView(self, modelAtIndex: indexPath) {
                    cell.model = model
                }

                return cell
            }

            let cell = tableView.dequeue(UserAdsListViewCell.self, for: indexPath)
            cell.loadingColor = color
            cell.dataSource = self
            if let model = dataSource?.userAdsListView(self, modelAtIndex: indexPath) {
                cell.model = model
            }
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let imageLoadingCell = cell as? ImageLoading { imageLoadingCell.loadImage() }
        delegate?.userAdsListView(self, willDisplayItemAtIndex: indexPath)
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case firstSection, lastSection: return false
        default: return true
        }
    }
}

// MARK: - UserAdsListViewNewAdCellDelegate

extension UserAdsListView: UserAdsListViewNewAdCellDelegate {
    public func userAdsListViewNewAdCell(_ userAdsListViewNewAdCell: UserAdsListViewNewAdCell, didTapCreateNewAdButton button: Button) {
        delegate?.userAdsListView(self, didTapCreateNewAdButton: button)
    }
}

// MARK: - UserAdsListHeaderViewDelegate

extension UserAdsListView: UserAdsListHeaderViewDelegate {
    public func userAdsListHeaderView(_ userAdsListHeaderView: UserAdsListHeaderView, didTapSeeMoreButton button: Button) {
        delegate?.userAdsListView(self, userAdsListHeaderView: userAdsListHeaderView, didTapSeeMoreButton: button)
    }
}

// MARK: - UserAdsListViewCellDataSource

extension UserAdsListView: UserAdsListViewCellDataSource {
    public func userAdsListViewCellShouldDisplayAsInactive(_ userAdsListViewCell: UserAdsListViewCell) -> Bool {
        guard let indexPath = tableView.indexPathForRow(at: userAdsListViewCell.center) else { return  false}
        return dataSource?.userAdsListView(self, shouldDisplayInactiveSectionAt: indexPath) ?? false
    }

    public func userAdsListViewCell(_ userAdsListViewCell: UserAdsListViewCell, loadImageForModel model: UserAdsListViewModel, imageWidth: CGFloat, completion: @escaping ((UIImage?) -> Void)) {
        dataSource?.userAdsListView(self, loadImageForModel: model, imageWidth: imageWidth, completion: completion)
    }

    public func userAdsListViewCell(_ userAdsListViewCell: UserAdsListViewCell, cancelLoadingImageForModel model: UserAdsListViewModel, imageWidth: CGFloat) {
        dataSource?.userAdsListView(self, cancelLoadingImageForModel: model, imageWidth: imageWidth)
    }
}

// MARK: - UserAdsListViewSeeAllAdsCellDelegate

extension UserAdsListView: UserAdsListViewSeeAllAdsCellDelegate {
    public func userAdsListViewSeeAllAdsCell(_ userAdsListViewSeeAllAdsCell: UserAdsListViewSeeAllAdsCell, didTapSeeAllAdsButton button: Button) {
        delegate?.userAdsListView(self, didTapSeeAllAdsButton: button)
    }
}

extension UserAdsListView: RefreshControlDelegate {
    public func refreshControlDidBeginRefreshing(_ refreshControl: RefreshControl) {
        delegate?.userAdsListViewDidStartRefreshing(self)
    }
}

extension UserAdsListView: UserAdsListEmphasizedActionCellDelegate {
    public func userAdsListEmphasizedActionCell(_ cell: UserAdsListEmphasizedActionCell, buttonWasTapped: Button) {
        guard let emphasizedSection = dataSource?.sectionNumberForEmphasizedAction(in: self) else { return }
        delegate?.userAdsListViewEmphasizedActionWasTapped(self)
        tableView.reloadSections(IndexSet(integer: emphasizedSection), with: .automatic)
    }

    public func userAdsListEmphasizedActionCell(_ cell: UserAdsListEmphasizedActionCell, cancelButtonWasTapped: Button) {
        let showRatingView = dataSource?.emphasizedActionShowRatingView ?? false
        guard showRatingView != false && hasGivenRating != false else {
            cell.showRatingView()
            return
        }

        guard let emphasizedSection = dataSource?.sectionNumberForEmphasizedAction(in: self) else { return }
        delegate?.userAdsListViewEmphasizedActionWasCancelled(self)
        tableView.reloadSections(IndexSet(integer: emphasizedSection), with: .automatic)
    }

    public func userAdsListEmphasizedActionCell(_ cell: UserAdsListEmphasizedActionCell, closeButtonWasTapped: UIButton) {
        delegate?.userAdsListViewEmphasizedActionWasCancelled(self)

        cell.hideRatingView(completion: {
            guard let emphasizedSection = self.dataSource?.sectionNumberForEmphasizedAction(in: self) else { return }
            self.tableView.reloadSections(IndexSet(integer: emphasizedSection), with: .automatic)
        })
    }

    public func userAdsListEmphasizedActionCell(_ cell: UserAdsListEmphasizedActionCell, textFor rating: HappinessRating) -> String? {
        return delegate?.userAdsListViewEmphasized(self, textFor: rating)
    }

    public func userAdsListEmphasizedActionCell(_ cell: UserAdsListEmphasizedActionCell, didSelectRating rating: HappinessRating) {
        hasGivenRating = true
        delegate?.userAdsListViewEmphasized(self, didSelectRating: rating)

        cell.hideRatingView(completion: {
            guard let emphasizedSection = self.dataSource?.sectionNumberForEmphasizedAction(in: self) else { return }
            self.tableView.reloadSections(IndexSet(integer: emphasizedSection), with: .automatic)

            if let feedbackText = cell.model?.ratingViewModel?.feedbackText {
                self.showToastView(type: .success, placement: .bottom, text: feedbackText, timeOut: 2)
            }
        })
    }
}
