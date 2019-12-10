//
//  Copyright © 2019 FINN AS. All rights reserved.
//

import UIKit

// MARK: - MinFinnCellModel
public protocol MinFinnCellModel: BasicTableViewCellViewModel {}

public extension MinFinnCellModel {
    var subtitle: String? { nil }
    var detailText: String? { nil }
    var hasChevron: Bool { false }
}

// MARK: - MinFinnProfileCellModel
public protocol MinFinnProfileCellModel: MinFinnCellModel, IdentityViewModel {}

public extension MinFinnProfileCellModel {
    var title: String { "" }
    var description: String? { nil }
    var displayMode: IdentityView.DisplayMode { .nonInteractible }
}

// MARK: - MinFinnVerifyCellModel
public protocol MinFinnVerifyCellModel: MinFinnCellModel {
    var buttonTitle: String { get }
}

// MARK: - MinFinnIconCellModel
public protocol MinFinnIconCellModel: MinFinnCellModel, IconTitleTableViewCellViewModel {}

public extension MinFinnIconCellModel {
    var iconTintColor: UIColor? { .licorice }
    var hasChevron: Bool { true }
}