//
//  Triangle.swift
//  Chassis
//
//  Created by Patrick Smith on 18/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


func TriangleGetOppositeSideLengthForAngle(angle: Radians, betweenSideOfLength side1Length: Dimension, andSideOfLength side2Length: Dimension) -> Dimension {
	return sqrt((side1Length * side1Length) + (side2Length * side2Length) - (2.0 * side1Length * side2Length * cos(angle)))
}

func TriangleGetAngleBetweenSides(side1Length: Dimension, side2Length: Dimension, oppositeSideLength: Dimension) -> Radians {
	return acos(((side1Length * side1Length) + (side2Length * side2Length) - (oppositeSideLength * oppositeSideLength)) / (2.0 * side1Length * side2Length))
}

func TriangleGetOtherSideLengthsForAngle(angle1: Radians, secondAngle angle2: Radians, side1To3Length: Dimension) -> (side2To3Length: Dimension, side1To2Length: Dimension) {
	let angle3 = M_PI - (angle1 + angle2)
	let part = side1To3Length / sin(angle2)
	return (
		sin(angle1) * part,
		sin(angle3) * part
	)
}

func TriangleGetOtherSideLengthsForAngle(angle1: Radians, angle2: Radians, angle3: Radians, sideOppositeCorner1Length: Dimension) -> (sideOppositeCorner2Length: Dimension, sideOppositeCorner3Length: Dimension) {
	let part = sideOppositeCorner1Length / sin(angle1)
	return (
		sin(angle2) * part,
		sin(angle3) * part
	)
}


struct TriangularPoints {
	var a: Point2D
	var b: Point2D
	var c: Point2D
}

extension TriangularPoints {
	// FIXME: wrong
	/*func containsPoint(pt: Point2D) -> Bool {
		// From http://www.blackpawn.com/texts/pointinpoly/default.html
		let u = ((b.y * c.x) - (b.x * c.y)) / ((a.x * b.y) - (a.y * b.x))
		let v = ((a.x * c.y) - (a.y * c.x)) / ((a.x * b.y) - (a.y * b.x))
		
		return u >= 0.0 && v >= 0.0 && (u + v <= 1.0)
	}*/
}


enum TriangleDetailCorner {
	case AAngle(Radians)
	case BAngle(Radians)
	case CAngle(Radians)
}

enum TriangleDetailSide {
	case ABLength(Dimension)
	case BCLength(Dimension)
	case CALength(Dimension)
}


enum TriangleSideClassification {
	// All sides are equal in length
	case Equilateral
	// Two sides are equal in length
	case Isosceles
	// All sides are unequal
	case Scalene
}

enum TriangleInternalAngleClassification {
	// One interior angle is 90 degrees
	case RightAngled
	// All interior angles less than 90
	case AcuteAngled
	// One interior angle more than 90
	case ObtuseAngled
}


enum TriangularFoundation {
	case SideLengths(ab: Dimension, bc: Dimension, ca: Dimension)
	case CornerA(a: Radians, ca: Dimension, ab: Dimension)
	case CornerB(b: Radians, bc: Dimension, ab: Dimension)
	case CornerC(c: Radians, bc: Dimension, ca: Dimension)
	case SideAB(ab: Dimension, a: Radians, b: Radians)
	case SideBC(bc: Dimension, b: Radians, c: Radians)
	case SideCA(ca: Dimension, a: Radians, c: Radians)
}
