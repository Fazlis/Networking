//
//  Utils.swift
//  Networking
//
//  Created by Fazliddinov Iskandar on 30/05/25.
//

import Foundation


func safePrint(isDebug: Bool, _ message: @autoclosure () -> String) {
    if isDebug {
        print(message())
    }
}
