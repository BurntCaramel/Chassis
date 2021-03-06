//
//  Transforms.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Foundation


protocol ValueTransform {
	associatedtype Input
	associatedtype OutputValue
	
	subscript(input: Input) -> OutputValue { get }
}



