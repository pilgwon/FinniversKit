//
//  Copyright © 2019 FINN AS. All rights reserved.
//

import FinniversKit

private struct ProfileItem: MinFinnProfileCellModel {
    var profileImage: UIImage?
    var profileImageUrl: URL?
    var displayName: String
    var subtitle: String
    var isVerified: Bool
}

private struct VerifyItem: MinFinnVerifyCellModel {
    let title: String
    let buttonTitle: String
}

private struct IconItem: MinFinnIconCellModel {
    let icon: UIImage?
    let title: String
}

private struct Item: MinFinnCellModel {
    let title: String
    let hasChevron: Bool
}

private struct Section {
    let items: [MinFinnCellModel]
}

class MinFinnDemoView: UIView {

    private lazy var sections = [
        Section(items: [
            ProfileItem(profileImage: nil, profileImageUrl: nil, displayName: "Ola Nordmann", subtitle: "ola.nordmann@finn.no", isVerified: true),
            VerifyItem(title: "Bekreft at du er deg", buttonTitle: "Kom i gang")
        ]),
        Section(items: [
            IconItem(icon: UIImage(named: "favorites"), title: "Favoritter"),
            IconItem(icon: UIImage(named: "savedSearches"), title: "Lagrede Søk"),
            IconItem(icon: UIImage(named: "ratings"), title: "Vurderinger")
        ]),
        Section(items: [
            Item(title: "Personvernerklæring", hasChevron: true),
            Item(title: "Instillinger", hasChevron: true),
            Item(title: "Kundeservice", hasChevron: false),
            Item(title: "Logg ut", hasChevron: false),
        ])
    ]

    private lazy var minFinnView: MinFinnView = {
        let view = MinFinnView(withAutoLayout: true)
        view.dataSource = self
        view.delegate = self
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(minFinnView)
        minFinnView.fillInSuperview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MinFinnDemoView: MinFinnViewDataSource {
    func numberOfSections(in view: MinFinnView) -> Int {
        sections.count
    }

    func minFinnView(_ view: MinFinnView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func minFinnView(_ view: MinFinnView, modelForRowAt indexPath: IndexPath) -> MinFinnCellModel {
        sections[indexPath.section].items[indexPath.item]
    }
}

extension MinFinnDemoView: MinFinnViewDelegate {
    func minFinnView(_ view: MinFinnView, didSelectProfileImageAt indexPath: IndexPath) {
    }

    func minFinnView(_ view: MinFinnView, didSelectModelAt indexPath: IndexPath) {
        let model = sections[indexPath.section].items[indexPath.item]
        print("Did select model: \n\t- \(model)")
    }

    func minFinnView(_ view: MinFinnView, loadImageWith url: URL, completion: (UIImage?) -> Void) {
    }
}