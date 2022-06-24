//
//  UIImage+.swift
//  CardScanner
//
//  Created by DouDou on 2022/6/23.
//

import UIKit

extension UIImage {
    
    convenience init?(imageBuffer: CVImageBuffer) {
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: nil)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        guard let cgImage = context.createCGImage(ciImage, from: rect) else { return nil }
        self.init(cgImage: cgImage)
    }
    
    func subImage(with rect: CGRect) -> UIImage {
        guard let subCgImage = cgImage?.cropping(to: rect) else { return self }
        let smallBounds = CGRect(x: 0, y: 0, width: subCgImage.width, height: subCgImage.height)
        UIGraphicsBeginImageContext(smallBounds.size)
        let context = UIGraphicsGetCurrentContext()
        context?.draw(subCgImage, in: smallBounds)
        let smallImage = UIImage(cgImage: subCgImage)
        UIGraphicsEndImageContext()
        return smallImage
    }
    
}
