import UIKit
import Foundation
import Accelerate
import AVFoundation

public enum ScanType {
    case identity, bank
}

private var isInitIdScanEngine = false

private let scannerQueue = DispatchQueue(label: "com.scaner.scaner")

public protocol ScannerDelegate: NSObjectProtocol {
    func scanComplete(with result: IdentityCard, capture output: CaptureResult) -> Bool
    func scanComplete(with result: BankCard, capture output: CaptureResult, reco rect: CGRect) -> Bool
}

public class Scanner: NSObject {
    
    public let scanType: ScanType
    
    public let capturer = Capturer()
    
    public weak var delegate: ScannerDelegate?
    
    private var isInProcess = false
    
    private var isStop = false
    
    public init(type: ScanType) {
        scanType = type
        super.init()
        if type == .identity {
            startIdScanEngine()
        }
        capturer.delegate = self
    }
    
    @discardableResult
    public func startIdScanEngine() -> Bool {
        guard let workPath = Bundle.coreBundle.resourcePath else { return false }
        if !isInitIdScanEngine {
            let ret = EXCARDS_Init(workPath)
            isInitIdScanEngine = (ret == 0)
            if !isInitIdScanEngine {
                debugPrint("Star identity scan engine error return: \(ret)")
            }
        }
        return isInitIdScanEngine
    }
    
    public func destroyIdScanEngine() {
        isInitIdScanEngine = false
        EXCARDS_Done()
    }
    
    public func startScan() {
        isInProcess = false
        isStop = false
        capturer.startScan()
    }
    
    public func stopScan() {
        isStop = true
        capturer.stopScan()
    }
    
}

extension Scanner: CapturerDelegate {
    public func capturer(didOutput result: CaptureResult) -> Bool {
        if !isInProcess {
            isInProcess = true
            scannerQueue.sync {
                self.doRecognition(with: result)
            }
        }
        return isInProcess
    }
    
    private func doRecognition(with result: CaptureResult) {
        if isStop {
            return
        }
        switch scanType {
        case .identity:
            recognitionIdentityCard(from: result)
        case .bank:
            recognitionBankCard(from: result)
        }
        isInProcess = false
    }
    
    private func recognitionIdentityCard(from result: CaptureResult) {
        guard let ret = idCardRecognize(from: result) else {
            return
        }
        isStop = delegate?.scanComplete(with: ret, capture: result) ?? true
        if isStop {
            capturer.stopScan()
        }
        debugPrint("recognitionIdentityCard ret = \(ret)")
    }
    
    private func recognitionBankCard(from result: CaptureResult) {
        guard let ret = bankCardRecognize(from: result) else {
            return
        }
        isStop = delegate?.scanComplete(with: ret.0, capture: result, reco: ret.1) ?? true
        if isStop {
            capturer.stopScan()
        }
        debugPrint("recognitionBankCard ret1 = \(ret)")
    }
    
}

// MARK: - 身份证识别
private extension Scanner {
    func idCardRecognize(from result: CaptureResult) -> IdentityCard? {
        let outputSize: Int = 1024
        let buffer = result.imageBufAddr.bindMemory(to: UInt8.self, capacity: result.offset)
        let output: UnsafeMutablePointer<CChar> = .allocate(capacity: outputSize)
        defer {
            output.deinitialize(count: outputSize)
            output.deallocate()
        }
        let length = EXCARDS_RecoIDCardData(buffer,
                                            Int32(result.width),
                                            Int32(result.height),
                                            Int32(result.offset),
                                            8, output, Int32(outputSize))
        return decodeIDCardData(with: output, length: length)
    }
    
    func decodeIDCardData(with result: UnsafeMutablePointer<CChar>, length: Int32) -> IdentityCard? {
        if length <= 0 {
            return nil
        }
        
        var idx = 0
        var ctype: Int8 = result[idx]
        var content = [Int8](repeating: 0, count: 256)
        var xlen: Int = 0
        
        let gbkEncoding = CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))
        
        let encoding = String.Encoding(rawValue: gbkEncoding)
        
        idx += 1
        
        var temp: [String: String?] = [:]

        while idx < length {
            ctype = result[idx]
            idx += 1
            xlen = 0
            while idx < length {
                if result[idx] == 32 {
                    idx += 1
                    break
                }
                content[xlen] = result[idx]
                xlen += 1
                idx += 1
            }
            content[xlen] = 0
            if xlen != 0 {
                switch ctype {
                case 0x21:
                    temp["number"] = String(cString: content, encoding: encoding)
                case 0x22:
                    temp["name"] = String(cString: content, encoding: encoding)
                case 0x23:
                    temp["gender"] = String(cString: content, encoding: encoding)
                case 0x24:
                    temp["nation"] = String(cString: content, encoding: encoding)
                case 0x25:
                    temp["address"] = String(cString: content, encoding: encoding)
                case 0x26:
                    temp["issue"] = String(cString: content, encoding: encoding)
                case 0x27:
                    temp["valid"] = String(cString: content, encoding: encoding)
                default:
                    continue
                }
            }
        }
        
        let info = temp.compactMapValues({$0})
        
        return info.isEmpty ? nil : .init(json: info)
    }
}

// MARK: - 银行卡识别
private extension Scanner {
    func bankCardRecognize(from result: CaptureResult) -> (BankCard, CGRect)? {
        let outputSize: Int = 512
        let size = MemoryLayout<UInt8>.size * result.width * result.height
        let output: UnsafeMutablePointer<UInt8> = .allocate(capacity: outputSize)
        defer {
            output.deinitialize(count: outputSize)
            output.deallocate()
        }
        let rect = getEffectImageRect(with: .init(width: result.width, height: result.height))
        let guideRect = getGuideFrame(with: rect)
        let pixelAddress = result.imageBufAddr.bindMemory(to: UInt8.self, capacity: result.offset)
        let cbCrBuffer = result.imageBufAddr.bindMemory(to: UInt8.self, capacity: result.offset + size)
        let length = BankCardNV12(output, Int32(outputSize),
                                  pixelAddress, cbCrBuffer,
                                  Int32(result.width), Int32(result.height),
                                  Int32(guideRect.origin.x), Int32(guideRect.origin.y),
                                  Int32(guideRect.maxX), Int32(guideRect.maxY))
        return decodeBankCardData(with: output, length: length,
                                  imageSize: .init(width: result.width, height: result.height),
                                  guideRect: guideRect)
    }
    
    func getEffectImageRect(with size: CGSize) -> CGRect {
        let size2 = UIScreen.main.bounds.size
        var size0: CGSize = size
        var point: CGPoint = .zero
        if size.width / size.height > size2.width / size2.height {
            let oldW = size.width
            size0.width = size2.width / size2.height * size.height
            point.x = (oldW - size0.width) * 0.5
        } else {
            let oldH = size.height
            size0.height = size2.height / size2.width * size.width
            point.y = (oldH - size0.height) * 0.5
        }
        return .init(origin: point, size: size0)
    }
    
    func getGuideFrame(with rect: CGRect) -> CGRect {
        var height = rect.size.height * 0.7
        if rect.size.height < height {
            height = rect.size.height
        }
        let width = CGFloat(height / 0.63)
        let left = 0.5 * (rect.size.width - width)
        let top = 0.5 * (rect.size.height - height)
        return .init(x: left + rect.origin.x,
                     y: top + rect.origin.y,
                     width: width, height: height)
    }

    func decodeBankCardData(with result: UnsafeMutablePointer<UInt8>, length: Int32, imageSize: CGSize, guideRect: CGRect) -> (BankCard, CGRect)? {
        if length <= 0 {
            return nil
        }
        
        var sets = [Int](repeating: 0, count: Int(length))
        for idx in 0..<sets.count {
            sets[idx] = Int(result[idx])
        }
        
        var idx = 4
        var szBankName = [Int](repeating: 0, count: 64)
        
        // bank name, GBK CharSet;
        for idxx in 0..<64 {
            let code = sets[idx]
            szBankName[idxx] = code
            idx += 1
        }
        
        // 字符解析，包含空格
        var hic = sets[idx]
        idx += 1
        
        var lwc = sets[idx]
        idx += 1
        
        var charIdx = 0
        let charNum = (hic << 8) + lwc
        var numbers = [CChar](repeating: 0, count: charNum+1)
        var rects = [CGRect](repeating: .zero, count: charNum)
        
        // char code and its rect
        while idx < length - 9 {
            
            // 字符的编码unsigned short
            hic = sets[idx]
            idx += 1
            lwc = sets[idx]
            idx += 1
            numbers[charIdx] = CChar((hic << 8) + lwc)
    
            // 字符的矩形框lft, top, w, h
            hic = sets[idx]
            idx += 1
            lwc = sets[idx]
            idx += 1
            let left = (hic << 8) + lwc
            
            hic = sets[idx]
            idx += 1
            lwc = sets[idx]
            idx += 1
            let top = (hic << 8) + lwc
            
            hic = sets[idx]
            idx += 1
            lwc = sets[idx]
            idx += 1
            let width = (hic << 8) + lwc
            
            hic = sets[idx]
            idx += 1
            lwc = sets[idx]
            idx += 1
            let height = (hic << 8) + lwc
            
            rects[charIdx] = .init(x: left, y: top, width: width, height: height)
            
            charIdx += 1
        }
        
        if charIdx < 10 || charIdx > 24 || charNum != charIdx {
            charIdx = 0
        }
        
        numbers[charIdx] = 0
        
        if charIdx > 0 {
            if let cardNumber = String(cString: numbers, encoding: .ascii) {
                let subRect = getRecognizeRect(with: imageSize, guideRect: guideRect, charCount: charIdx, numbers: numbers, rects: rects)
                return (BankCard(number: cardNumber), subRect)
            }
        }
        
        return nil
    }
    
    func getRecognizeRect(with size: CGSize, guideRect: CGRect, charCount: Int, numbers: [CChar], rects: [CGRect]) -> CGRect {
        var nCount = 1
        var subRect = rects[0]
        var nAvgW = subRect.size.width
        var nAvgH = subRect.size.height
        
        for idx in 1..<charCount {
            subRect = combinRect(subRect, rects[idx])
            if numbers[idx] != 32 {
                nAvgW += rects[idx].size.width
                nAvgH += rects[idx].size.height
                nCount += 1
            }
        }
        
        // 统计得到的平均宽度和高度
        nAvgW /= CGFloat(nCount)
        nAvgH /= CGFloat(nCount)

        // releative to the big image（相对于大图）
        subRect.origin.x += guideRect.origin.x
        subRect.origin.y += guideRect.origin.y
        //    rect.offset(guideRect.left, guideRect.top);
        // 做一个扩展
        subRect.origin.y -= nAvgH
        if subRect.origin.y < 0 {
            subRect.origin.y = 0
        }
        subRect.size.height += nAvgH * 2
        
        let width = size.width
        let height = size.height
        
        if subRect.size.height + subRect.origin.y >= height {
            subRect.size.height = height - subRect.origin.y - 1
        }
        subRect.origin.x -= nAvgW
        if subRect.origin.x < 0 {
            subRect.origin.x = 0
        }
        subRect.size.width += nAvgW * 2
        if subRect.size.width + subRect.origin.x >= width {
            subRect.size.width = width - subRect.origin.x - 1
        }
        return subRect
        
    }
    
    func combinRect(_ rect1: CGRect, _ rect2: CGRect) -> CGRect {
        let left = min(rect1.origin.x, rect2.origin.x)
        let top = min(rect1.origin.y, rect2.origin.y)
        let right = max(rect1.size.width + rect1.origin.x, rect2.size.width + rect2.origin.x)
        let bottom = max(rect1.size.height + rect1.origin.y, rect2.size.height + rect2.origin.y)
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }
    
}
