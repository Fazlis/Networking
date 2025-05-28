////
//  CachePolicy.swift
//  Core
//
//  Created by Fazliddinov Iskandar on 28/05/25.
//  
//  Email: exclusive.fazliddinov@gmail.com
//  GitHub: https://github.com/Fazlis
//  LinkedIn: https://www.linkedin.com/in/iskandar-fazliddinov-2b8438279
//  Phone: (+992) 92-100-44-55
//

import Foundation


public enum CacheProtocol {
    case none
    case memory(ttl: TimeInterval?) // например, 3600 — 1 час
    case disk(ttl: TimeInterval?)   // nil — бесконечно
    case session                    // пока не перезапущено
}
