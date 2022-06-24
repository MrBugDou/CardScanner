//
//  ViewController.swift
//  CardScanner
//
//  Created by DouDou on 2022/6/20.
//

import UIKit
import SnapKit
import DDCardScanner

class DemoNavigationController: UINavigationController {
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = R.color.dark()
        navigationItem.title = "OCR识别"
        
        let idCardScanButton: UIButton = {
            let button = UIButton(type: .custom)
            button.setTitle("身份证识别", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = R.color.orange()
            button.addTarget(self, action: #selector(idCardScanButtonClick(_:)), for: .touchUpInside)
            return button
        }()
        view.addSubview(idCardScanButton)
        idCardScanButton.snp.makeConstraints { (make) in
            make.height.equalTo(44)
            make.top.equalToSuperview().offset(180)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        let bankCardScanButton: UIButton = {
            let button = UIButton(type: .custom)
            button.setTitle("银行卡识别", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = R.color.orange()
            button.addTarget(self, action: #selector(bankCardScanButtonClick(_:)), for: .touchUpInside)
            return button
        }()
        view.addSubview(bankCardScanButton)
        bankCardScanButton.snp.makeConstraints { (make) in
            make.leading.trailing.height.equalTo(idCardScanButton)
            make.top.equalTo(idCardScanButton.snp.bottom).offset(50)
        }
        
    }
    
    @objc func idCardScanButtonClick(_ sender: UIButton) {
        let ocrVc = OCRViewController(type: .identity)
        navigationController?.pushViewController(ocrVc, animated: true)
    }
    
    @objc func bankCardScanButtonClick(_ sender: UIButton) {
        let ocrVc = OCRViewController(type: .bank)
        navigationController?.pushViewController(ocrVc, animated: true)
    }
    
}
