//
//  NATOperationCell.swift
//  HiBeacons
//
//  Created by Nick Toumpelis on 2015-07-26.
//  Copyright (c) 2015 Nick Toumpelis.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import UIKit

/// The custom cell that is used for presenting the user with the three possible app operations.
class NATOperationCell : UITableViewCell
{
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func updateConstraints() {
        // We wouldn't normally need this, since constraints can be set in Interface Builder. However, there seems
        // to be a bug that removes all constraints from our cells upon dequeueing, so we need to re-add them here.

        contentView.translatesAutoresizingMaskIntoConstraints = false

        let rightAccessoryViewMarginConstraint = NSLayoutConstraint(item: accessoryView!, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: -14.0)
        let topAccessoryViewMarginConstraint = NSLayoutConstraint(item: accessoryView!, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 7.0)
        let activityViewWidthConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 20.0)
        let activityViewHeightConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 7.0)
        let rightActivityViewMarginConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .Right, relatedBy: .Equal, toItem: accessoryView, attribute: .Left, multiplier: 1.0, constant: -8.0)
        let topActivityViewMarginConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 20.0)

        addConstraints([rightAccessoryViewMarginConstraint,
                        topAccessoryViewMarginConstraint,
                        activityViewWidthConstraint,
                        activityViewHeightConstraint,
                        rightActivityViewMarginConstraint,
                        topActivityViewMarginConstraint])

        super.updateConstraints()
    }
}
