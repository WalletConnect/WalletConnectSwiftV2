
import Foundation
import UIKit

final class ConnectView: UIView {
    var segmentedControl: UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: ["Pairings", "New Pairing"])
//        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }

    let tableView = UITableView()
    
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
    
    let connectWalletButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Connect Wallet", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 8
        return button
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        addSubview(segmentedControl)
        addSubview(qrCodeView)
        addSubview(copyButton)
        addSubview(connectWalletButton)
//        addSubview(tableView)
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "pairing_cell")
        subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            
            segmentedControl.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 64),
            segmentedControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            segmentedControl.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            
//            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 26),
//            tableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),

            qrCodeView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 26),
            qrCodeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            qrCodeView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
            qrCodeView.widthAnchor.constraint(equalTo: qrCodeView.heightAnchor),
            
            copyButton.topAnchor.constraint(equalTo: qrCodeView.bottomAnchor, constant: 16),
            copyButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            copyButton.widthAnchor.constraint(equalTo: qrCodeView.widthAnchor),
            copyButton.heightAnchor.constraint(equalToConstant: 44),
            
            connectWalletButton.topAnchor.constraint(equalTo: copyButton.bottomAnchor, constant: 16),
            connectWalletButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            connectWalletButton.widthAnchor.constraint(equalTo: copyButton.widthAnchor),
            connectWalletButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
