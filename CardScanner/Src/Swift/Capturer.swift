import Foundation
import AVFoundation

public struct CaptureResult {
    
    public let width: Int
    
    public let height: Int
    
    public let offset: Int
    
    public let pixelBuffer: CVImageBuffer
    
    public let imageBufAddr: UnsafeMutableRawPointer
    
}

public protocol CapturerDelegate: NSObjectProtocol {
    func capturer(didOutput result: CaptureResult) -> Bool
}

private let capturerQueue = DispatchQueue(label: "com.scaner.capturer")

public class Capturer: NSObject {
    
    private var stoped: Bool = false
    
    /// 输入输出中间桥梁(会话)
    public let session = AVCaptureSession()
    
    public weak var delegate: CapturerDelegate?
    
    public let metadataOutput = AVCaptureVideoDataOutput()
    
    public private(set) var videoInput: AVCaptureDeviceInput?
    
    public override init() {
        
        super.init()
        
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        videoInput = deviceInput
        
        if session.canAddInput(deviceInput) {
            session.addInput(deviceInput)
        }
        
        metadataOutput.alwaysDiscardsLateVideoFrames = true
        let key = kCVPixelBufferPixelFormatTypeKey as String
        // metadataOutput.videoSettings = [key: kCVPixelFormatType_32BGRA]
        metadataOutput.videoSettings = [key: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        metadataOutput.setSampleBufferDelegate(self, queue: capturerQueue)
        
        var videoConnection: AVCaptureConnection?
        for connection in metadataOutput.connections {
            for port in connection.inputPorts {
                if port.mediaType == .video {
                    videoConnection = connection
                    break
                }
            }
            if videoConnection != nil {
                break
            }
        }
        
        if videoConnection?.isVideoStabilizationSupported == true {
            videoConnection?.preferredVideoStabilizationMode = .auto
        }
        // videoConnection?.videoOrientation = .portrait
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
        }
        
        do {
            try device.lockForConfiguration()
            if device.isSmoothAutoFocusSupported {
                device.isSmoothAutoFocusEnabled = true
            }
            var currentMode = device.focusMode
            if currentMode == .locked {
                currentMode = .autoFocus
            }
            if device.isFocusModeSupported(currentMode) {
                device.focusMode = currentMode
            }
            device.unlockForConfiguration()
            
            session.commitConfiguration()
        } catch {
            debugPrint("device.lockForConfiguration() error: \(error)")
        }
        
    }
    
    public func startScan() {
        stoped = false
        if !session.isRunning {
            capturerQueue.async {
                self.session.startRunning()
            }
        }
    }
    
    public func stopScan() {
        stoped = true
        if session.isRunning {
            capturerQueue.async {
                self.session.stopRunning()
            }
        }
    }
    
    public func switchCameras() -> Bool {
        if AVCaptureDevice.devices(for: .video).count < 2 {
            return false
        }
        guard let oldInput = videoInput, let newInput = try? AVCaptureDeviceInput(device: oldInput.device) else { return false }
        if session.canAddInput(newInput) {
            session.beginConfiguration()
            session.removeInput(oldInput)
            session.addInput(newInput)
            videoInput = newInput
            session.commitConfiguration()
            return true
        }
        return false
    }
    
    public func setFlash(mode: AVCaptureDevice.FlashMode) {
        guard let device = videoInput?.device else { return }
        if device.flashMode != mode, device.isFlashModeSupported(mode) {
            do {
                try device.lockForConfiguration()
                device.flashMode = mode
                device.unlockForConfiguration()
            } catch {
                debugPrint("device.lockForConfiguration() error: \(error)")
            }
        }
    }
    
    public func setTorch(mode: AVCaptureDevice.TorchMode) {
        guard let device = videoInput?.device else { return }
        if device.torchMode != mode, device.isTorchModeSupported(mode) {
            do {
                try device.lockForConfiguration()
                device.torchMode = mode
                device.unlockForConfiguration()
            } catch {
                debugPrint("device.lockForConfiguration() error: \(error)")
            }
        }
    }
    
    public func focusAt(point: CGPoint) {
        guard let device = videoInput?.device else { return }
        if device.isFocusPointOfInterestSupported,
           device.isFocusModeSupported(.autoFocus) {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
                device.unlockForConfiguration()
            } catch {
                debugPrint("device.lockForConfiguration() error: \(error)")
            }
        }
    }
    
    public func exposeAt(point: CGPoint) {
        guard let device = videoInput?.device else { return }
        if device.isExposurePointOfInterestSupported,
           device.isExposureModeSupported(.autoExpose) {
            do {
                try device.lockForConfiguration()
                device.exposurePointOfInterest = point
                device.exposureMode = .autoExpose
                if device.isExposureModeSupported(.locked) {
                    setupDeviceAdjustingExposureKVO(with: device)
                }
                device.unlockForConfiguration()
            } catch {
                debugPrint("device.lockForConfiguration() error: \(error)")
            }
        }
    }
    
    /// 重置曝光
    public func resetFocusAndExposureModes() {
        guard let device = videoInput?.device else { return }
        
        let canResetFocus = device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus)
        
        let canResetExposure = device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose)
        
        let centerPoint = CGPoint(x: 0.5, y: 0.5)
        
        do {
            try device.lockForConfiguration()
            if canResetFocus {
                device.focusMode = .autoFocus
                device.focusPointOfInterest = centerPoint
            }
            if canResetExposure {
                device.exposureMode = .autoExpose
                device.exposurePointOfInterest = centerPoint
            }
            device.unlockForConfiguration()
        } catch {
            debugPrint("device.lockForConfiguration() error: \(error)")
        }
    }
    
    // MARK: 设置KVO监听
    /// 进度条监听
    private var adjustingExposureKVO: NSKeyValueObservation?
    private func setupDeviceAdjustingExposureKVO(with device: AVCaptureDevice) {
        adjustingExposureKVO = device.observe(\.isAdjustingExposure, options: [.new]) { [weak self] (device, _) in
            if !device.isAdjustingExposure, device.isExposureModeSupported(.locked) {
                self?.adjustingExposureKVO?.invalidate()
                DispatchQueue.main.async {
                    do {
                        try device.lockForConfiguration()
                        device.exposureMode = .locked
                        device.unlockForConfiguration()
                    } catch {
                        debugPrint("device.lockForConfiguration() error: \(error)")
                    }
                }
            }
        }
    }
    
}

extension Capturer: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if output != metadataOutput {
            return
        }
        
        if stoped {
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        
        guard let imageBufAddr = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let offset = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        
        if stoped {
            return
        }
        
        let result = CaptureResult(width: width, height: height, offset: offset, pixelBuffer: pixelBuffer, imageBufAddr: imageBufAddr)
        
        DispatchQueue.main.async {
            self.stoped = self.delegate?.capturer(didOutput: result) ?? false
        }
    }
    
//    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//            return
//        }
//        if output == metadataOutput {
//            delegate?.capturer(didDrop: pixelBuffer)
//        }
//    }
    
}
