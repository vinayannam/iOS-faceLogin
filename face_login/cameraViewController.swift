//
//  cameraViewController.swift
//  face_login
//
//  Created by A.S.D.Vinay on 18/01/17.
//  Copyright © 2017 A.S.D.Vinay. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import ProjectOxfordFace


enum PhotoType{
    case login
    case signup
}

class cameraViewController: UIViewController,AVCapturePhotoCaptureDelegate {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var button: UIButton!
    
    var captureSession = AVCaptureSession()
    var sessionOutput =  AVCapturePhotoOutput()
    var previewLayer = AVCaptureVideoPreviewLayer()
    var userStorageref = FIRStorageReference()
    var personImage = UIImage()
    var faceFromPhoto: MPOFace!
    var faceFromFirebase: MPOFace!
    var actIdc:UIActivityIndicatorView!
    var phototype:PhotoType!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let storage = FIRStorage.storage()
        
        let storageRef = storage.reference(forURL: "gs://facelogin-95d40.appspot.com")
        
        userStorageref = storageRef.child("users")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let deviceSession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInDuoCamera,.builtInTelephotoCamera,.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .unspecified)
        
        for device in (deviceSession?.devices)! {
            
            if device.position == AVCaptureDevicePosition.front {
                
                do {
                    
                    let input = try AVCaptureDeviceInput(device: device)
                    
                    if captureSession.canAddInput(input){
                        captureSession.addInput(input)
                        
                        if captureSession.canAddOutput(sessionOutput){
                            captureSession.addOutput(sessionOutput)
                            
                            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                            previewLayer.connection.videoOrientation = .portrait
                            
                            cameraView.layer.addSublayer(previewLayer)
                            cameraView.addSubview(button)
                            
                            previewLayer.position = CGPoint (x: self.cameraView.frame.width / 2, y: self.cameraView.frame.height / 2)
                            previewLayer.bounds = cameraView.frame
                            
                            captureSession.startRunning()
                            
                        }
                    }
                    
                    
                } catch let avError {
                    print(avError)
                }
                
                
            }
            
        }
        
    }
    
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = photoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            let userID = FIRAuth.auth()?.currentUser?.uid
            let imageRef = userStorageref.child("\(userID!).jpg")
            
            showActivityindicator(onView: self.cameraView)
            
            if phototype == PhotoType.signup{
                self.personImage = UIImage(data: dataImage)!
                
                let client = MPOFaceServiceClient(subscriptionKey: "8f16684192cc4dca9b6264f7128c00a7")!
                
                let data = UIImageJPEGRepresentation(self.personImage, 0.8)
                
                client.detect(with: data!, returnFaceId: true, returnFaceLandmarks: true, returnFaceAttributes: [], completionBlock: { (faces, error) in
                    
                    if error != nil {
                        print(error ?? "")
                        return
                    }
                    
                    if (faces!.count) > 1 || faces!.count == 0 {
                        print("too many or not at all faces")
                        self.failLogin()
                        return
                    }
                    
                    
                    
                    let uploadTask = imageRef.put(dataImage, metadata: nil, completion: { (metadata, error) in
                        if error != nil {
                            print(error!)
                            return
                        }
                    })
                    
                    uploadTask.resume()
                    
                })
                
                captureSession.stopRunning()
                previewLayer.removeFromSuperlayer()
                
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "logged")
                self.present(vc, animated: true, completion:  nil)
                
                actIdc.stopAnimating()
                
            }else if phototype == PhotoType.login {
                
                self.personImage = UIImage(data: dataImage)!
                captureSession.stopRunning()
                
                imageRef.downloadURL(completion: {(url,error) in
                    if error != nil{
                        print(error!)
                        return
                    }
                    
                    self.verify(withURl: url!.absoluteString)
                })
                
            }
            
        }
        
    }
    
        func verify(withURl url: String){
            let client = MPOFaceServiceClient(subscriptionKey: "8f16684192cc4dca9b6264f7128c00a7")!
            
            let data = UIImageJPEGRepresentation(self.personImage, 0.8)
            
            client.detect(with: data!, returnFaceId: true, returnFaceLandmarks: true, returnFaceAttributes: [], completionBlock: { (faces, error) in
                if error != nil{
                    print(error!)
                    return
                }
                
                if (faces!.count) > 1 || faces!.count == 0 {
                    print("too many or not at all faces")
                    self.failLogin()
                    self.actIdc.stopAnimating()
                    return
                }
                
                self.faceFromPhoto = faces![0]
                
                client.detect(withUrl: url, returnFaceId: true, returnFaceLandmarks: true, returnFaceAttributes: [], completionBlock: {(faces,error) in
                    if error != nil{
                        print(error!)
                        return
                    }
                    
                    self.faceFromFirebase = faces![0]
                    
                    client.verify(withFirstFaceId: self.faceFromPhoto.faceId, faceId2: self.faceFromFirebase.faceId, completionBlock: {(result,error) in
                    
                        if error != nil{
                            print(error!)
                            return
                        }
                        
                        self.actIdc.stopAnimating()
                        
                        if result!.isIdentical{
                            
                            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "logged")
                            self.present(vc, animated: true, completion:  nil)
                            
                        }
                        else{
                            self.failLogin()
                        
                            
                        }
                    
                    
                    
                    })
                    
                })
                
            })
            

        }
    
    
    
    func showActivityindicator(onView:UIView){
    
        let container:UIView = UIView()
        container.frame = onView.frame
        container.center = onView.center
        container.backgroundColor = UIColor(white: 0, alpha: 0.8)
        
        let loadingView:UIView = UIView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = onView.center
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        actIdc = UIActivityIndicatorView()
        
        actIdc.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        actIdc.hidesWhenStopped = true
        actIdc.activityIndicatorViewStyle = .whiteLarge
        actIdc.center = CGPoint(x: loadingView.frame.size.width/2, y: loadingView.frame.size.height/2)
        
        loadingView.addSubview(actIdc)
        container.addSubview(loadingView)
        onView.addSubview(container)
        
        actIdc.startAnimating()
    }

    func failLogin(){
        let alert = UIAlertController(title: "Failed Login", message: "Not same person", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style: .default, handler: {(action) in
        
        let logVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "login")
        
        self.present(logVC, animated: true, completion:  nil)
        })
        alert.addAction(cancel)
        
        do{
            try FIRAuth.auth()?.signOut()
            
        }
        catch{
        
        }
    
    
    
        self.present(alert, animated: true, completion: nil)
    }


    
    @IBAction func takePhoto(_ sender: Any) {
        
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String : previewPixelType, kCVPixelBufferWidthKey as String : 160, kCVPixelBufferHeightKey as String : 160]
        
        settings.previewPhotoFormat = previewFormat
        sessionOutput.capturePhoto(with: settings, delegate: self)
        
    }



}
