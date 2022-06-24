//
//  ResultViewController.swift
//  CardScanner
//
//  Created by DouDou on 2022/6/23.
//

import UIKit
import SnapKit
import DDCardScanner

class ResultViewController: UIViewController {

    var results: [String] = []
    
    var sourceImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = R.color.dark()
        navigationItem.title = "识别结果"
        
        let closeButton: UIButton = {
            let button = UIButton(type: .custom)
            button.frame = .init(x: 0, y: 0, width: 32, height: 32)
            button.addTarget(self, action: #selector(closeButtonClick), for: .touchUpInside)
            button.setBackgroundImage(R.image.icon_univerial_close_white_normal(), for: .normal)
            return button
        }()
        
        navigationItem.leftBarButtonItem = .init(customView: closeButton)
        
        let safeArea = navigationController?.view.safeAreaInsets ?? .zero
        
        let sourceImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.image = sourceImage
            imageView.contentMode = .scaleAspectFit
            imageView.contentScaleFactor = UIScreen.main.scale
            return imageView
        }()
        view.addSubview(sourceImageView)
        sourceImageView.snp.makeConstraints { (make) in
            make.height.equalTo(200)
            make.leading.width.equalTo(self.view)
            make.top.equalTo(self.view).offset(safeArea.top + 16)
        }
        
        let resultLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.textColor = .white
            return label
        }()
        view.addSubview(resultLabel)
        resultLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(sourceImageView.snp.bottom).offset(32)
        }
        
        resultLabel.text = results.joined(separator: "\r")
        
    }
    
    @objc open func closeButtonClick() {
        navigationController?.popToRootViewController(animated: true)
    }
    
}
