import UIKit

final class ProposerView: UIView {
    
    let qrCodeView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy", for: .normal)
        button.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 8
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        
        addSubview(qrCodeView)
        addSubview(copyButton)
        
        subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            qrCodeView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 64),
            qrCodeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            qrCodeView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            qrCodeView.widthAnchor.constraint(equalTo: qrCodeView.heightAnchor),
            
            copyButton.topAnchor.constraint(equalTo: qrCodeView.bottomAnchor, constant: 16),
            copyButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            copyButton.widthAnchor.constraint(equalTo: qrCodeView.widthAnchor),
            copyButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
