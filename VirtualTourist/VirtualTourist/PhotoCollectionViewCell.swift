//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by TOM BELUNIS on 9/17/15.
//  Copyright © 2015 TOM BELUNIS. All rights reserved.
//

import UIKit

// Custom view for photo collection view
class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
