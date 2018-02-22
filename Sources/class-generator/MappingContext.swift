//
//  MappingContext.swift
//  class-generator
//
//  Created by Ramirez, Jorge X.-ND on 1/25/18.
//

import Foundation
import ObjectMapper

internal struct MappingContext: MapContext {

    /// If true, all enum values will be alphabetized when parsed.
    internal let alphabetizeEnumValues: Bool

    /// If true, all class properties will be alphabetized when parsed.
    internal let alphabetizeProperties: Bool

}
