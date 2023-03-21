//
//  ViewController.swift
//  WhatChaUp2UsingUIKit
//
//  Created by Vivian Phung on 3/20/23.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton()
        button.setTitle("Open Video", for: .normal)

        // Add capture button
        button.backgroundColor = .white
        button.layer.cornerRadius = 30
        button.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(button)
         NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 60)
         ])
        button.addTarget(self, action: #selector(openVideoView), for: .touchUpInside)

        view.addSubview(button)
    }

    @objc func openVideoView() {
        let videoVC = FullScreenCameraViewController()
        present(videoVC, animated: true, completion: nil)
    }

}
