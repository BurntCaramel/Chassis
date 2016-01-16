//
//  ShapeComponent.swift
//  Chassis
//
//  Created by Patrick Smith on 5/12/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum Shape {
	case SingleMark(Mark)
	case SingleLine(Line)
	case SingleRectangle(Rectangle)
	case SingleRoundedRectangle(Rectangle, cornerRadius: Dimension) // TODO: more fine grained corner radius
	case SingleEllipse(Rectangle)
	case Group(ShapeGroup)
}

extension Shape {
	public var kind: ShapeKind {
		switch self {
		case .SingleMark: return .Mark
		case .SingleLine: return .Line
		case .SingleRectangle: return .Rectangle
		case .SingleRoundedRectangle: return .RoundedRectangle
		case .SingleEllipse: return .Ellipse
		case .Group: return .Group
		}
	}
}

extension Shape: ElementType {
	static var baseComponentKind: ComponentBaseKind {
		return .Shape
	}
	
	public var componentKind: ComponentKind {
		return .Shape(kind)
	}
}

extension Shape {
	public mutating func makeElementAlteration(alteration: ElementAlteration) -> Bool {
		if case let .Replace(.Shape(replacement)) = alteration {
			self = replacement
			return true
		}
		
		switch self {
		case let .SingleMark(mark):
			self = .SingleMark(mark.alteredBy(alteration))
		case var .SingleRectangle(underlying):
			//underlying.makeElementAlteration(alteration)
			self = .SingleRectangle(underlying)
		case var .Group(underlying):
			//underlying.makeElementAlteration(alteration)
			self = .Group(underlying)
		default:
			// FIXME
			return false
		}
		
		return true
	}
	
	mutating func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		switch self {
		case var .Group(group):
			group.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
			self = .Group(group)
		default:
			// FIXME:
			return
		}
	}
}

extension Shape {
	func createQuartzPath() -> CGPath {
		switch self {
		case let .SingleMark(mark):
			let path = CGPathCreateMutable()
			let origin = mark.origin
			CGPathMoveToPoint(path, nil, CGFloat(origin.x), CGFloat(origin.y))
			return path
		case let .SingleLine(line):
			let path = CGPathCreateMutable()
			let origin = line.origin
			CGPathMoveToPoint(path, nil, CGFloat(origin.x), CGFloat(origin.y))
			if let endPoint = line.endPoint {
				CGPathAddLineToPoint(path, nil, CGFloat(endPoint.x), CGFloat(endPoint.y))
			}
			else {
				// TODO: decide what to do with infinite lines
			}
			return path
		case let .SingleRectangle(rectangle):
			return CGPathCreateWithRect(rectangle.toQuartzRect(), nil)
		case let .SingleRoundedRectangle(rectangle, cornerRadius):
			return CGPathCreateWithRoundedRect(rectangle.toQuartzRect(), CGFloat(cornerRadius), CGFloat(cornerRadius), nil)
		case let .SingleEllipse(rectangle):
			return CGPathCreateWithEllipseInRect(rectangle.toQuartzRect(), nil)
		case .Group:
			let path = CGPathCreateMutable()
			// TODO: combine paths
			return path
		}
	}
}

extension Shape {
	func offsetBy(x x: Dimension, y: Dimension) -> Shape {
		switch self {
		case let .SingleMark(origin):
			return .SingleMark(origin.offsetBy(x: x, y: y))
		case let .SingleLine(line):
			return .SingleLine(line.offsetBy(x: x, y: y))
		case let .SingleRectangle(rectangle):
			return .SingleRectangle(rectangle.offsetBy(x: x, y: y))
		case let .SingleRoundedRectangle(rectangle, cornerRadius):
			return .SingleRoundedRectangle(rectangle.offsetBy(x: x, y: y), cornerRadius: cornerRadius)
		case let .SingleEllipse(rectangle):
			return .SingleEllipse(rectangle.offsetBy(x: x, y: y))
		case let .Group(group):
			return .Group(group.offsetBy(x: x, y: y))
		}
	}
}

extension Shape {
	init(propertiesSource: PropertiesSourceType, kind: ShapeKind) throws {
		switch kind {
		case .Line:
			self = .SingleLine(try Line(propertiesSource: propertiesSource))
		default:
			throw PropertiesSourceError.NoPropertiesFound(availablePropertyChoices: Line.availablePropertyChoices)
		}
	}
}

extension Shape: AnyElementProducible, GroupElementChildType {
	func toAnyElement() -> AnyElement {
		return .Shape(self)
	}
}


protocol ShapeProducible {
	func produceShape() -> Shape
}

extension Shape: ShapeProducible {
	func produceShape() -> Shape {
		return self
	}
}
