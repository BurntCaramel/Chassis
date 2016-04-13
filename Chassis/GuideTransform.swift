//
//  GuideTransform.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GuideTransform {
	case duplicateOffsetting( // TODO: rotate, scale?
		guideUUID: NSUUID,
		x: Dimension,
		y: Dimension,
		xCount: Int,
		yCount: Int,
		createdUUID: NSUUID
	)
	
	case joinMarks(
		originUUID: NSUUID,
		endUUID: NSUUID,
		createdUUID: NSUUID
	)
	
	case insetRectangle(
		guideUUID: NSUUID,
		insets: RectangularInsets,
		createdUUID: NSUUID
	)
	
	case gridWithinRectangle(
		guideUUID: NSUUID,
		xDivision: QuadDivision,
		yDivision: QuadDivision,
		createdUUID: NSUUID
	)
	
	case rectangleWithinGridCell(
		gridUUID: NSUUID,
		column: Int,
		row: Int,
		insets: RectangularInsets,
		createdUUID: NSUUID
	)
	
	//case extractMark
	//case extractPoint
	//case useCatalogedTransform(UUID: NSUUID, catalogUUID: NSUUID, transformUUID: NSUUID)
	
	
	public enum Error: ErrorType {
		case sourceGuideNotFound(uuid: NSUUID)
		case sourceGuideInvalidKind(uuid: NSUUID, expectedKind: Guide.Kind, actualKind: Guide.Kind)
	}
}

extension GuideTransform : ElementType {
	public enum Kind : String, KindType {
		case duplicateOffsetting = "duplicateOffsetting"
		case joinMarks = "joinMarks"
		case insetRectangle = "insetRectangle"
		case gridWithinRectangle = "gridWithinRectangle"
		case rectangleWithinGridCell = "rectangleWithinGridCell"
	}
	
	public var kind: Kind {
		switch self {
		case .duplicateOffsetting: return .duplicateOffsetting
		case .joinMarks: return .joinMarks
		case .insetRectangle: return .insetRectangle
		case .gridWithinRectangle: return .gridWithinRectangle
		case .rectangleWithinGridCell: return .rectangleWithinGridCell
		}
	}
}

extension GuideTransform {
	public func transform(sourceGuidesWithUUID: NSUUID throws -> Guide?) throws -> [(NSUUID, Guide)] {
		func getGuide(uuid: NSUUID) throws -> Guide {
			guard let sourceGuide = try sourceGuidesWithUUID(uuid) else { throw Error.sourceGuideNotFound(uuid: uuid) }
			return sourceGuide
		}
		
		func getMarkGuide(uuid: NSUUID) throws -> Mark {
			let sourceGuide = try getGuide(uuid)
			guard case let .mark(mark) = sourceGuide else {
				throw Error.sourceGuideInvalidKind(uuid: uuid, expectedKind: .mark, actualKind: sourceGuide.kind)
			}
			return mark
		}
		
		switch self {
		case let .duplicateOffsetting(uuid, x, y, xCount, yCount, createdUUID):
			let sourceGuide = try getGuide(uuid)
			return (1...xCount).flatMap{ xIndex in
				(1...yCount).lazy.flatMap{ yIndex in
					// TODO: what to do about multiple UUIDs? Identifier.combined(.UUID(...), .index(...))
					[ (NSUUID(), sourceGuide.offsetBy(x: x * Dimension(xIndex), y: y * Dimension(yIndex))) ]
				}
			}
			//return try [ (createdUUID, getGuide(uuid).offsetBy(x: x, y: y)) ]
		case let .joinMarks(originUUID, endUUID, createdUUID):
			let joinedLine = Line.Segment(
				origin: try getMarkGuide(originUUID).origin,
				end: try getMarkGuide(endUUID).origin
			)
			return [ (createdUUID, .line(joinedLine)) ]
		default:
			fatalError("Unimplemented")
		}
	}
}

extension GuideTransform : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		self = try source.decodeChoices(
			{
				try .duplicateOffsetting(
					guideUUID: $0.decodeUUID("guideUUID"),
					x: $0.decode("x"),
					y: $0.decode("y"),
					xCount: $0.decode("xCount"),
					yCount: $0.decode("yCount"),
					createdUUID: $0.decodeUUID("createdUUID")
				)
			},
			{
				try .joinMarks(
					originUUID: $0.decodeUUID("originUUID"),
					endUUID: $0.decodeUUID("endUUID"),
					createdUUID: $0.decodeUUID("createdUUID")
				)
			},
			{
				try .insetRectangle(
					guideUUID: $0.decodeUUID("guideUUID"),
					insets: $0.decode("insets"),
					createdUUID: $0.decodeUUID("createdUUID")
				)
			}
		) as GuideTransform
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .duplicateOffsetting(guideUUID, x, y, xCount, yCount, createdUUID):
			return .ObjectValue([
				"guideUUID": guideUUID.toJSON(),
				"x": x.toJSON(),
				"y": y.toJSON(),
				"xCount": xCount.toJSON(),
				"yCount": yCount.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		case let .joinMarks(originUUID, endUUID, createdUUID):
			return .ObjectValue([
				"originUUID": originUUID.toJSON(),
				"endUUID": endUUID.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		case let .insetRectangle(guideUUID, insets, createdUUID):
			return .ObjectValue([
				"guideUUID": guideUUID.toJSON(),
				"insets": insets.toJSON(),
				"createdUUID": createdUUID.toJSON()
			])
		default:
			fatalError("Unimplemented")
		}
	}
}
