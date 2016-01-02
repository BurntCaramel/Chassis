//
//  Quad.swift
//  Chassis
//
//  Created by Patrick Smith on 11/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


enum QuadInset {
	case TopBottomLeadingTrailing(top: Dimension, bottom: Dimension, leading: Dimension, trailing: Dimension)
}

enum QuadDivision {
	case FractionFromSide(fraction: Dimension, side: Rectangle.DetailSide)
	case DistanceFromSide(distance: Dimension, side: Rectangle.DetailSide)
	case EvenDivisionsFromSide(divisionCount: UInt, side: Rectangle.DetailSide)
}
