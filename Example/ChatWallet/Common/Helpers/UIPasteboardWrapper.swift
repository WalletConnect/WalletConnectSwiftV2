//
//  UIPasteboardWrapper.swift
//  ChatWallet
//
//  Created by Alexander Lisovyk on 06.12.22.
//

import Foundation
import UIKit

struct UIPasteboardWrapper {
    static var string: String? {
        UIPasteboard.general.string
    }
}
