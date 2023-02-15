import UIKit

final class MainViewController: UITabBarController {

    private let presenter: MainPresenter

    init(presenter: MainPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabs()
    }

    private func setupTabs() {
        let viewControllers = presenter.viewControllers

        for (index, viewController) in viewControllers.enumerated() {
            let model = presenter.tabs[index]
            let item = UITabBarItem()
            item.title = model.title
            item.image = model.icon
            item.isEnabled = TabPage.enabledTabs.contains(model)
            viewController.tabBarItem = item
            viewController.view.backgroundColor = .w_background
        }

        self.viewControllers = viewControllers
        self.selectedIndex = TabPage.selectedIndex
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
