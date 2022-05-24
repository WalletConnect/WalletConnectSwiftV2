import UIKit
import SwiftUI

class SceneViewController<ViewModel: ObservableObject, Content: View>: UIHostingController<Content> {
    
    private let viewModel: ViewModel

    init(viewModel: ViewModel, content: Content) {
        self.viewModel = viewModel
        super.init(rootView: content)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
