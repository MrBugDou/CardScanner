//
//  OCRViewController.swift
//  CardScanner
//
//  Created by DouDou on 2022/6/23.
//

import UIKit
import SnapKit
import AVFoundation
import DDCardScanner

typealias DDScanner = DDCardScanner.Scanner
typealias DDScanType = DDCardScanner.ScanType

class OCRViewController: UIViewController {

    var scanner: DDScanner!
    
    var type: DDScanType!
    
    convenience init(type: DDScanType) {
        self.init()
        self.type = type
        self.scanner = .init(type: type)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        scanner.delegate = nil
        scanner.stopScan()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = R.color.dark()
        
        // Do any additional setup after loading the view.
        let preLayer = AVCaptureVideoPreviewLayer(session: scanner.capturer.session)
        preLayer.frame = view.bounds
        preLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(preLayer, at: 0)
        
        scanner.startScan()
        scanner.delegate = self
        
        let safeArea = navigationController?.view.safeAreaInsets ?? .zero
        
        let closeButton: UIButton = {
            let button = UIButton(type: .custom)
            button.addTarget(self, action: #selector(closeButtonClick), for: .touchUpInside)
            button.setBackgroundImage(R.image.icon_univerial_close_white_normal(), for: .normal)
            return button
        }()
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(safeArea.top + 6)
        }
        
    }
    
    @objc open func closeButtonClick() {
        navigationController?.popViewController(animated: true)
    }
    
}

extension OCRViewController: ScannerDelegate {
    
    func scanComplete(with result: IdentityCard, capture output: CaptureResult) -> Bool {
        var results: [String] = []

        if let front = result.front {
            results.append(front.name)
            results.append(front.gender)
            results.append(front.nation)
            results.append(front.address)
            results.append(front.number)
        }
        
        if let back = result.back {
            results.append(back.issue)
            results.append(back.valid)
        }
        
        let resultVc = ResultViewController()
        resultVc.results = results
        resultVc.sourceImage = .init(imageBuffer: output.pixelBuffer)
        navigationController?.pushViewController(resultVc, animated: true)
        
        return true
    }
    
    func scanComplete(with result: BankCard, capture output: CaptureResult, reco rect: CGRect) -> Bool {
        
        var results: [String] = [result.number]

        if let bankName = result.bankName {
            results.append(bankName)
        }
        
        let resultVc = ResultViewController()
        resultVc.results = results
        resultVc.sourceImage = .init(imageBuffer: output.pixelBuffer)?.subImage(with: rect)
        navigationController?.pushViewController(resultVc, animated: true)
        
        return true
    }
}
