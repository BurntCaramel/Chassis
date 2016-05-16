//
//  Rectangle.swift
//  Chassis
//
//  Created by Patrick Smith on 27/09/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation

/*
<Guides>
	<Rectangle ref='UUID-45253453455' origin={<Point2D x={24} y={90} />} width={40} height={60} />
</Guides>

<Graphics>
	<EllipseGraphic origin={refs['UUID-45253453455'].corner.A.origin} width={refs['UUID-45253453455'].width} height={refs['UUID-45253453455'].height} />
</Graphics>

*/



public enum Rectangle {
	case originWidthHeight(origin: Point2D, width: Dimension, height: Dimension)
	case minMax(minPoint: Point2D, maxPoint: Point2D)
	case centerOrigin(origin: Point2D, xRadius: Dimension, yRadius: Dimension)
	
	public enum Kind : String, KindType {
		case originWidthHeight = "originWidthHeight"
		case minMax = "minMax"
		case centerOrigin = "centerOrigin"
	}
	
	public enum Property: String, PropertyKeyType {
		case origin = "origin"
		case width = "width"
		case height = "height"
		case minPoint = "minPoint"
		case maxPoint = "maxPoint"
		
		public var kind: PropertyKind {
			switch self {
			case .origin: return .Point2D
			case .width: return .Dimension
			case .height: return .Dimension
			case .minPoint: return .Point2D
			case .maxPoint: return .Point2D
			}
		}
	}
	
	public enum DetailCorner: Int { // counter-clockwise
		case a // origin / min / top left
		case b // top right
		case c // max / bottom right
		case d // bottom left
	}
	
	public enum DetailSide: String {
		case ab = "ab" // top
		case bc = "bc" // right
		case cd = "cd" // bottom
		case da = "da" // left
	}
	
	public struct Points {
		var a: Point2D
		var b: Point2D
		var c: Point2D
		var d: Point2D
	}
	
	public struct CornerView {
		typealias Index = Rectangle.DetailCorner
	}
	
	public struct SideView {
		typealias Index = Rectangle.DetailSide
	}
	
	public enum Alteration {
		case MoveCornerTo(corner: DetailCorner, toPoint: Point2D)
		case MoveSideBy(side: DetailSide, by: Dimension)
	}
}

/*extension Rectangle.Kind {
	var propertyKind: PropertyKeyShape {
		switch self {
		case .originWidthHeight:
			return PropertyKeyShape([
				Rectangle.Property.origin: true,
				Rectangle.Property.width: true,
				Rectangle.Property.height: true,
			])
		case .minMax:
			return PropertyKeyShape([
				Rectangle.Property.minPoint: true,
				Rectangle.Property.maxPoint: true,
			])
		}
	}
}*/

extension Rectangle.DetailSide {
	var corners: (start: Rectangle.DetailCorner, end: Rectangle.DetailCorner) {
		switch self {
		case .ab: return (.a, .b)
		case .bc: return (.b, .c)
		case .cd: return (.c, .d)
		case .da: return (.d, .a)
		}
	}
}

extension Rectangle {
	var width: Dimension {
		switch self {
		case let .originWidthHeight(_, width, _):
			return width
		case let .minMax(minPoint, maxPoint):
			return maxPoint.x - minPoint.x
		case let .centerOrigin(_, xRadius, _):
			return xRadius * 2.0
		}
	}
		
	var height: Dimension {
		switch self {
		case let .originWidthHeight(_, _, height):
			return height
		case let .minMax(minPoint, maxPoint):
			return maxPoint.y - minPoint.y
		case let .centerOrigin(_, _, yRadius):
			return yRadius * 2.0
		}
	}
	
	func pointForCorner(corner: DetailCorner) -> Point2D {
		switch self {
		case let .originWidthHeight(origin, width, height):
			switch corner {
			case .a: return origin
			case .b: return Point2D(x: origin.x + width, y: origin.y)
			case .c: return Point2D(x: origin.x + width, y: origin.y + height)
			case .d: return Point2D(x: origin.x, y: origin.y + height)
			}
		case let .minMax(minPoint, maxPoint):
			switch corner {
			case .a: return minPoint
			case .b: return Point2D(x: maxPoint.x, y: minPoint.y)
			case .c: return maxPoint
			case .d: return Point2D(x: minPoint.x, y: maxPoint.y)
			}
		case let .centerOrigin(origin, xRadius, yRadius):
			switch corner {
			case .a: return origin.offsetBy(x: -xRadius, y: -yRadius)
			case .b: return origin.offsetBy(x: xRadius, y: -yRadius)
			case .c: return origin.offsetBy(x: xRadius, y: yRadius)
			case .d: return origin.offsetBy(x: -xRadius, y: yRadius)
			}
		}
	}
	
	var centerPoint: Point2D {
		switch self {
		case let .centerOrigin(origin, _, _):
			return origin
		default:
			let pointA = pointForCorner(.a)
			let pointC = pointForCorner(.c)
			let difference = (pointC - pointA) / 2
			return pointA.offsetBy(difference)
		}
	}
	
	func lineForSide(side: DetailSide) -> Line {
		let (startCorner, endCorner) = side.corners
		return Line.Segment(origin: pointForCorner(startCorner), end: pointForCorner(endCorner))
	}
}

extension Rectangle {
	func toOriginWidthHeight() -> Rectangle {
		switch self {
		case .originWidthHeight:
			return self
		default:
			return .originWidthHeight(origin: pointForCorner(.a), width: width, height: height)
		}
	}
	
	// TODO: toMinMax(), toCenterOrigin
}

extension Rectangle: Offsettable {
	public func offsetBy(x x: Dimension, y: Dimension) -> Rectangle {
		switch self {
		case let .originWidthHeight(origin, width, height):
			return .originWidthHeight(
				origin: origin.offsetBy(x: x, y: y),
				width: width,
				height: height
			)
		case let .minMax(minPoint, maxPoint):
			return .minMax(
				minPoint: minPoint.offsetBy(x: x, y: y),
				maxPoint: maxPoint.offsetBy(x: x, y: y)
			)
		case let .centerOrigin(origin, xRadius, yRadius):
			return .centerOrigin(
				origin: origin.offsetBy(x: x, y: y),
				xRadius: xRadius,
				yRadius: yRadius
			)
		}
	}
}

extension Rectangle {
	mutating func makeRectangleAlteration(alteration: Alteration) {
		var minPoint = pointForCorner(.a)
		var maxPoint = pointForCorner(.c)
		
		switch alteration {
		case let .MoveCornerTo(corner, toPoint):
			switch corner {
			case .a:
				minPoint = toPoint
			case .b:
				minPoint.y = toPoint.y
				maxPoint.x = toPoint.x
			case .c:
				maxPoint = toPoint
			case .d:
				minPoint.x = toPoint.x
				maxPoint.y = toPoint.y
			}
		case let .MoveSideBy(side, by):
			switch side {
			case .ab:
				minPoint.y += by
			case .bc:
				maxPoint.x += by
			case .cd:
				maxPoint.y += by
			case .da:
				minPoint.x += by
			}
		}
		
		switch self {
		case .originWidthHeight:
			self = .originWidthHeight(
				origin: minPoint,
				width: maxPoint.x - minPoint.x,
				height: maxPoint.y - minPoint.y
			)
		case .minMax:
			self = .minMax(
				minPoint: minPoint,
				maxPoint: maxPoint
			)
		case .centerOrigin:
			let xRadius = (maxPoint.x - minPoint.x) / 2.0
			let yRadius = (maxPoint.y - minPoint.y) / 2.0
			self = .centerOrigin(
				origin: minPoint.offsetBy(x: xRadius, y: yRadius),
				xRadius: xRadius,
				yRadius: yRadius
			)
		}
	}
}

extension Rectangle: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		self = try source.decodeChoices(
			{
				return try .originWidthHeight(
					origin: $0.decode("origin"),
					width: $0.decode("width"),
					height: $0.decode("height")
				)
			},
			{
				return try .minMax(
					minPoint: $0.decode("minPoint"),
					maxPoint: $0.decode("maxPoint")
				)
			},
			{
				return try .centerOrigin(
					origin: $0.decode("origin"),
					xRadius: $0.decode("xRadius"),
					yRadius: $0.decode("yRadius")
				)
			}
		)
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .originWidthHeight(origin, width, height):
			return .ObjectValue([
				"origin": origin.toJSON(),
				"width": .NumberValue(width),
				"height": .NumberValue(height)
			])
		case let .minMax(minPoint, maxPoint):
			return .ObjectValue([
				"minPoint": minPoint.toJSON(),
				"maxPoint": maxPoint.toJSON()
			])
		case let .centerOrigin(origin, xRadius, yRadius):
			return .ObjectValue([
				"origin": origin.toJSON(),
				"xRadius": xRadius.toJSON(),
				"yRadius": yRadius.toJSON()
			])
		}
	}
}

extension Rectangle {
	func toQuartzRect() -> CGRect {
		let origin = pointForCorner(.a)
		return CGRect(
			x: origin.x,
			y: origin.y,
			width: width,
			height: height
		)
	}
}



typealias RectangleFoundationDetailCornerIndex = IntEnumIndex<Rectangle.DetailCorner>

struct IntEnumIndex<Raw: RawRepresentable where Raw.RawValue == Int>: Equatable, ForwardIndexType {
	private let rawRepresentable: Raw?
	
	init(_ rawRepresentable: Raw?) {
		self.rawRepresentable = rawRepresentable
	}
	
	func successor() -> IntEnumIndex {
		switch rawRepresentable {
		case .None: return IntEnumIndex(nil)
		case let .Some(rawRepresentable):
			return IntEnumIndex(Raw(rawValue: rawRepresentable.rawValue + 1))
		}
	}
}
func ==<Raw: RawRepresentable where Raw.RawValue == Int>(a: IntEnumIndex<Raw>, b: IntEnumIndex<Raw>) -> Bool {
	switch (a.rawRepresentable, b.rawRepresentable) {
	case (.None, .None):
		return true
	case let (.Some(a), .Some(b)):
		return a == b
	default:
		return false
	}
}


public struct RectangularInsets {
	public var sideToDimension: [Rectangle.DetailSide: Dimension]
}

extension RectangularInsets : JSONRepresentable {
	public init(sourceJSON: JSON) throws {
		try self.init(
			sideToDimension: sourceJSON.decodeDictionary(createKey:{ Rectangle.DetailSide(rawValue: $0) })
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue(Dictionary(keysAndValues:
			sideToDimension.lazy.map{ (key, value) in (key.rawValue, value.toJSON()) }
		))
	}
}
