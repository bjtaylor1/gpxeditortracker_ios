import AVFoundation
import UIKit

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var notificationName: Notification.Name?
    
    @IBAction func cancelClick(_ sender: Any) {
        dismiss(animated: true)
    }
    
    var started: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tryStartCapture()
    }
    
    func tryStartCapture() {
        if(started) {return}
        started = true
        
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            cameraAccessGranted()
        case .denied:
            cameraAccessDenied()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.cameraAccessGranted()
                } else {
                    // no need to show dialog, as they've just pressed the reject button
                    DispatchQueue.main.async {
                        self.dismiss(animated: true)
                    }

                }
            }
        case .restricted:
            self.cameraAccessDenied()
        @unknown default:
            self.cameraAccessDenied()
        }
    }
    
    func cameraAccessDenied() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Camera", message: "No access to camera. Go to Settings, Privacy, Camera to configure.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in self.dismiss(animated: true)}))
            self.present(alert, animated:true)
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        captureSession = nil
        super.dismiss(animated: flag, completion: completion)
    }
    
    func cameraAccessGranted() {
        NotificationCenter.default.post(name: .onCameraAccess, object: nil)
        
        DispatchQueue.main.async {
            self.cameraAccessGrantedUi()
        }
        
    }
    
    func cameraAccessGrantedUi() {
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)

        }
        
        dismiss(animated: true)
    }
    
    func found(code: String) {
        guard let n = notificationName else {
            return
        }
        NotificationCenter.default.post(name: n, object: code)
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
