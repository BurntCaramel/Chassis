//
//  GraphicSheet.swift
//  Chassis
//
//  Created by Patrick Smith on 28/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public enum GraphicSheetGraphics {
	case Freeform(FreeformGraphicGroup)
}

extension GraphicSheetGraphics {
	var descendantElementReferences: AnySequence<ElementReference<AnyElement>> {
		switch self {
			case let .Freeform(group):
				return group.descendantElementReferences
		}
	}
	
	mutating func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		switch self {
		case var .Freeform(group):
			group.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
			self = .Freeform(group)
		}
	}
}

extension GraphicSheetGraphics: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		do {
			self = try .Freeform(source.decode("freeform"))
		}
		catch let error as JSONDecodeError where error.noMatch {}

		throw JSONDecodeError.NoCasesFound
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .Freeform(freeform):
			return .ObjectValue([
				"freeform": freeform.toJSON()
			])
		}
	}
}



public struct GraphicSheet {
	var graphics: GraphicSheetGraphics
	
	//var UUID: NSUUID
	//var size: Dimension2D?
	var bounds: Rectangle? = nil // bounds can have an origin away from 0,0
	//var guideSheet: GuideSheet
	var guideSheetReference: ElementReference<GuideSheet>? = nil
}

extension GraphicSheet {
	public init(freeformGraphicReferences: [ElementReference<Graphic>]) {
		self.graphics = .Freeform(FreeformGraphicGroup(childGraphicReferences: freeformGraphicReferences))
	}
}

extension GraphicSheet: ContainingElementType {
	public var kind: SheetKind {
		return .Graphic
	}
	
	public var descendantElementReferences: AnySequence<ElementReference<AnyElement>> {
		return graphics.descendantElementReferences
	}
	
	mutating public func makeAlteration(alteration: ElementAlteration, toInstanceWithUUID instanceUUID: NSUUID, holdingUUIDsSink: NSUUID -> ()) {
		graphics.makeAlteration(alteration, toInstanceWithUUID: instanceUUID, holdingUUIDsSink: holdingUUIDsSink)
	}
}

extension GraphicSheet: JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			graphics: source.decode("graphics"),
			bounds: allowOptional{ try source.decode("bounds") },
			guideSheetReference: allowOptional{ try source.decode("guideSheetReference") }
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"graphics": graphics.toJSON(),
			"bounds": bounds?.toJSON() ?? .NullValue,
			"guideSheetReference": guideSheetReference?.toJSON() ?? .NullValue
		])
	}
}
