//
//  ListCellView.swift
//  BondDemo
//
//  Created by Srđan Rašić on 26/01/15.
//  Copyright (c) 2015 Srdan Rasic. All rights reserved.
//

import UIKit
import Bond

class ListCellView: UITableViewCell {
  
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var ownerLabel: UILabel!
  @IBOutlet weak var avatarImageView: UIImageView!
  
  override func prepareForReuse() {
    super.prepareForReuse()
    avatarImageView.image = nil
    avatarImageView.designatedBond.unbindAll()
  }
}