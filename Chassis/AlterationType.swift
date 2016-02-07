//
//  AlterationType.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol AlterationType: JSONRepresentable, CustomStringConvertible {
	typealias Kind: KindType
	
	var kind: Kind { get }
}

extension AlterationType {
	public var description: String {
		return self.toJSON().description
	}
}
