import UIKit

struct AppearanceConfigurator: Configurator {

    func configure() {
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.w_foreground
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

    }
}
