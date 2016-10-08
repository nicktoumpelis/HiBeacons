//
//  NATOperationType.swift
//  HiBeacons
//
//  Created by Nick Toumpelis on 2016-10-03.
//  Copyright © 2016 Nick Toumpelis. All rights reserved.
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

/// Encapsulates the three kinds of operations possible to perform in the app.
enum NATOperationType: String
{
    /// The monitoring operation.
    case monitoring

    /// The advertising operation.
    case advertising

    /// The ranging operation.
    case ranging

    /** 
     Initializes an operation type with an index. It is failable.
     :param: index The index of the type.
     */
    init?(index: Int) {
        switch index {
        case 0:
            self = .monitoring
        case 1:
            self = .advertising
        case 2:
            self = .ranging
        default:
            return nil
        }
    }

    /// Returns the index value for an operation type.
    func index() -> Int {
        switch self {
        case .monitoring:
            return 0
        case .advertising:
            return 1
        case .ranging:
            return 2
        }
    }

    /// Returns the capitalized raw value for an operation type.
    func capitalizedRawValue() -> String {
        return self.rawValue.capitalized
    }
}
