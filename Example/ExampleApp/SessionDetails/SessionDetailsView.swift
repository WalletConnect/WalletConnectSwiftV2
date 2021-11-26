import UIKit

final class SessionDetailsView: UIView {
    
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemFill
        imageView.layer.cornerRadius = 32
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .heavy)
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    let urlLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        label.textColor = .tertiaryLabel
        return label
    }()

    let headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        return stackView
    }()
    
    let chainsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .leading
        return stackView
    }()
    
    let methodsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .leading
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        
        addSubview(iconView)
        addSubview(headerStackView)
        addSubview(chainsStackView)
        addSubview(methodsStackView)
        headerStackView.addArrangedSubview(nameLabel)
        headerStackView.addArrangedSubview(urlLabel)
        headerStackView.addArrangedSubview(descriptionLabel)
        
        subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 64),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),
            
            headerStackView.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 32),
            headerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            headerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            chainsStackView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 24),
            chainsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            chainsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            methodsStackView.topAnchor.constraint(equalTo: chainsStackView.bottomAnchor, constant: 24),
            methodsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            methodsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
        ])
    }
    
    func loadImage(at url: String) {
        guard let iconURL = URL(string: url) else { return }
        DispatchQueue.global().async {
            if let imageData = try? Data(contentsOf: iconURL) {
                DispatchQueue.main.async { [weak self] in
                    self?.iconView.image = UIImage(data: imageData)
                }
            }
        }
    }
    
    func list(chains: [String]) {
        let label = UILabel()
        label.text = "Chains"
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .heavy)
        chainsStackView.addArrangedSubview(label)
        chains.forEach {
            chainsStackView.addArrangedSubview(ListItem(text: $0))
        }
    }
    
    func list(methods: [String]) {
        let label = UILabel()
        label.text = "Methods"
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .heavy)
        methodsStackView.addArrangedSubview(label)
        methods.forEach {
            methodsStackView.addArrangedSubview(ListItem(text: $0))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

