//
//  ViewController.swift
//  SVGDemo
//
//  Created by xiaoshanlin on 2026/1/1.
//

import UIKit
import SVGBucket

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let image = LogUseTime.measure("load svg"){
            return ImageFile.icHighContrastCrdownload(CGSize(width: 72, height: 72))
        }
        imageView.image = image
        
        printWithTime("total file:",ImageiconSVGBReader.shared.fileCount())
    }


}

