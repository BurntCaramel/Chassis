//
//  ShapeGraphic.swift
//  Chassis
//
//  Created by Patrick Smith on 2/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Quartz
import Freddy


public struct ShapeGraphic : GraphicType {
	var shapeReference: ElementReferenceSource<Shape>
	var styleReference: ElementReferenceSource<ShapeStyleDefinition>
	
	public var kind: GraphicKind {
		return .ShapeGraphic
	}
	
	//static var types = Set([chassisComponentType("ShapeGraphic")])
}

extension ShapeGraphic {
	public func produceCALayer(_ context: LayerProducingContext, UUID: Foundation.UUID) -> CALayer? {
		print("ShapeGraphic.produceCALayer")
		let layer = context.dequeueShapeLayerWithComponentUUID(UUID)
		
		if let
			shape = context.resolveShape(shapeReference),
			let style = context.resolveShapeStyleReference(styleReference)
		{
			layer.path = shape.createQuartzPath()
			style.applyToShapeLayer(layer, context: context)
		}
		
		return layer
	}
}

extension ShapeGraphic : JSONRepresentable {
	public init(json: JSON) throws {
		try self.init(
			shapeReference: json.decode(at: "shapeReference"),
			styleReference: json.decode(at: "styleReference")
		)
	}
	
	public func toJSON() -> JSON {
		return .dictionary([
			"shapeReference": shapeReference.toJSON(),
			"styleReference": styleReference.toJSON()
		])
	}
}
