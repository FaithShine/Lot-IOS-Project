//
//  IntrusionCell.swift
//  smartroom
//
//  Created by Bruno Luis Mendivez Vasquez on 14/11/2016.
//  Copyright © 2016 Bruno Luis Mendivez Vasquez. All rights reserved.
//

import UIKit

class IntrusionCell: UITableViewCell {

    @IBOutlet weak var lblIntrusionTitle: UILabel!
    @IBOutlet weak var lblIntrusionSubtitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
