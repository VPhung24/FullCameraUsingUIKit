//
//  FullScreenCameraViewController.swift
//  WhatChaUp2UsingUIKit
//
//  Created by Vivian Phung on 3/21/23.
//

import UIKit
import AVFoundation
import Photos

class FullScreenCameraViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let sessionQueue = DispatchQueue(label: "SessionQueue")
    private let captureButton = UIButton()
    private var captureOutput: AVCapturePhotoOutput!
    private var imageView: UIImageView!
    private var saveButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupCaptureButton()
        setupImageView()
        setupSaveButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.captureSession != nil {
            sessionQueue.async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession != nil {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high

        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Unable to access the back camera.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("Error adding back camera input: \(error.localizedDescription)")
            return
        }

        let videoOutput = AVCaptureVideoDataOutput()
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(captureOutput) {
            captureSession.addOutput(captureOutput)
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)
    }

    private func setupCaptureButton() {
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 30
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            captureButton.widthAnchor.constraint(equalToConstant: 60),
            captureButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func setupImageView() {
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupSaveButton() {
        saveButton = UIButton(type: .system)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveImage), for: .touchUpInside)
        saveButton.isHidden = true // Initially hide the save button
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            saveButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    @objc private func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = .auto
        if captureOutput.isHighResolutionCaptureEnabled { // Check if high-resolution capture is supported
            photoSettings.isHighResolutionPhotoEnabled = true
        }

        captureOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    @objc private func saveImage() {
        guard let image = imageView.image else {
            print("No image to save.")
            return
        }

        guard let croppedImage = cropImageToAspectFill(image, imageView: imageView) else {
            print("Unable to crop image.")
            return
        }

        saveImageToCameraRoll(croppedImage)

        // Hide the save button after saving the image
        saveButton.isHidden = true
    }

    private func saveImageToCameraRoll(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }, completionHandler: { success, error in
                    if success {
                        print("Image saved to camera roll.")
                    } else if let error = error {
                        print("Error saving image to camera roll: \(error.localizedDescription)")
                    }
                })
            case .denied, .restricted, .notDetermined:
                print("Photo library access is not granted.")
            default:
                break
            }
        }
    }

    private func cropImageToAspectFill(_ image: UIImage, imageView: UIImageView) -> UIImage? {
        let imageViewAspectRatio = imageView.bounds.width / imageView.bounds.height
        let imageAspectRatio = image.size.width / image.size.height

        var newSize = CGSize()
        if imageAspectRatio > imageViewAspectRatio {
            newSize.height = image.size.height
            newSize.width = image.size.height * imageViewAspectRatio
        } else {
            newSize.width = image.size.width
            newSize.height = image.size.width / imageViewAspectRatio
        }

        let xWidth = (image.size.width - newSize.width) / 2
        let yHeight = (image.size.height - newSize.height) / 2

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(x: -xWidth, y: -yHeight, width: image.size.width, height: image.size.height))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return croppedImage
    }
}

extension FullScreenCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
            print("Unable to create image from captured photo data.")
            return
        }

        imageView.image = image
        saveButton.isHidden = false
    }
}
