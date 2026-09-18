//
//  CameraController.swift
//  BacaUang2
//
//  Created by Imelda Damayanti on 14/09/26.
//
import AVFoundation
import CoreImage
import UIKit
import Combine


final class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "camera.frame.queue")
    private let ciContext = CIContext()
    private var lastProcessed = Date.distantPast
    
    private var device: AVCaptureDevice?
    private var torchIsOn = false
    private var lastTorchToggle = Date.distantPast

    private let torchOnISOThreshold: Float = 800
    private let torchOffISOThreshold: Float = 500
    private let torchToggleCooldown: TimeInterval = 2.0
    
    
    var onFrame: ((CGImage) -> Void)?

    @Published var setupError: String?

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else {
                DispatchQueue.main.async { self?.setupError = "Akses kamera ditolak. Aktifkan di Settings." }
                return
            }
            self?.configureAndStart()
        }
    }

    private func configureAndStart() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            DispatchQueue.main.async { self.setupError = "Kamera belakang gak ketemu (normal di Simulator)." }
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        self.device = device

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        guard session.canAddOutput(output) else {
            DispatchQueue.main.async { self.setupError = "Gak bisa nambahin video output." }
            session.commitConfiguration()
            return
        }
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        session.addOutput(output)
        if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90 // portrait
        }
        
        session.commitConfiguration()
        session.startRunning()
    }

    func stop() {
        session.stopRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessed) > 0.5 else { return }
        lastProcessed = now
        updateTorch()

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        onFrame?(cgImage)
    }
    private func updateTorch() {
        guard let device, device.hasTorch, device.isTorchAvailable else { return }
        guard Date().timeIntervalSince(lastTorchToggle) > torchToggleCooldown else { return }

        let iso = device.iso
        guard let _ = try? device.lockForConfiguration() else { return }
        defer { device.unlockForConfiguration() }

        if !torchIsOn && iso >= torchOnISOThreshold, device.isTorchModeSupported(.on) {
            device.torchMode = .on
            torchIsOn = true
            lastTorchToggle = Date()
        } else if torchIsOn && iso <= torchOffISOThreshold {
            device.torchMode = .off
            torchIsOn = false
            lastTorchToggle = Date()
        }
    }
}
