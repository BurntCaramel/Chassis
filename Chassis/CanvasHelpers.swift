//
//  CanvasHelpers.swift
//  Chassis
//
//  Created by Patrick Smith on 4/10/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


protocol ComponentRenderee {
	var componentUUID: NSUUID? { get set }
}


extension CALayer: ComponentRenderee {
	var componentUUID: NSUUID? {
		get {
			return valueForKey("UUID") as? NSUUID
		}
		set {
			setValue(newValue, forKey: "UUID")
		}
	}
}


func createOriginLayer(radius radius: Double) -> CALayer {
	let layer = CALayer()
	
	let horizontalBarLayer = CAShapeLayer(rect: CGRect(x: -1.0, y: -radius, width: 2.0, height: radius * 2.0))
	let verticalBarLayer = CAShapeLayer(rect: CGRect(x: -radius, y: -1.0, width: radius * 2.0, height: 2.0))
	
	let whiteColor = NSColor.whiteColor()
	
	horizontalBarLayer.fillColor = whiteColor.CGColor
	horizontalBarLayer.lineWidth = 0.0
	verticalBarLayer.fillColor = whiteColor.CGColor
	verticalBarLayer.lineWidth = 0.0
	
	layer.addSublayer(horizontalBarLayer)
	layer.addSublayer(verticalBarLayer)
	
	return layer
}


func updateLayer(layer: CALayer, withGroup group: FreeformGraphicGroup, context: LayerProducingContext, componentUUIDNeedsUpdate: NSUUID -> Bool) {
	var newSublayers = [CALayer]()
	
	var existingSublayersByUUID = (layer.sublayers ?? [])
		.reduce([NSUUID: CALayer]()) { (var sublayers, sublayer) in
			if let componentUUID = sublayer.componentUUID {
				sublayers[componentUUID] = sublayer
			}
			return sublayers
	}
	
	for graphicReference in group.childGraphicReferences.lazy.reverse() {
		guard let graphic = context.resolveGraphic(graphicReference) else {
			// FIXME: handle missing graphics
			continue
		}
		
		let UUID = graphicReference.instanceUUID
		// Use an existing layer if present, and it has not been changed:
		if let existingLayer = existingSublayersByUUID[UUID] where !componentUUIDNeedsUpdate(UUID) {
			if case let .FreeformGroup(childGroupComponent) = graphic {
				updateLayer(existingLayer, withGroup: childGroupComponent, context: context, componentUUIDNeedsUpdate: componentUUIDNeedsUpdate)
			}
			
			existingLayer.removeFromSuperlayer()
			newSublayers.append(existingLayer)
		}
			// Create a new fresh layer from the component.
		else if let sublayer = graphic.produceCALayer(context, UUID: UUID) {
			sublayer.componentUUID = UUID
			newSublayers.append(sublayer)
		}
	}
	
	// TODO: check if only removing and moving nodes is more efficient?
	layer.sublayers = newSublayers
}


extension CALayer {
	func childLayerAtPoint(point: CGPoint) -> CALayer? {
		guard let sublayers = sublayers else { return nil }
		
		for layer in sublayers.lazy.reverse() {
			let pointInLayer = layer.convertPoint(point, fromLayer: self)
			//print("pointInLayer \(pointInLayer) bounds \(layer.bounds) frame \(layer.frame)")
			if let shapeLayer = layer as? CAShapeLayer {
				if CGPathContainsPoint(shapeLayer.path, nil, pointInLayer, true) {
					return layer
				}
			}
			else if layer.containsPoint(pointInLayer) {
				return layer
			}
		}
		
		return nil
	}
}



class CanvasScrollLayer: CAScrollLayer {
	private func setUp() {
		backgroundColor = NSColor(calibratedWhite: 0.5, alpha: 1.0).CGColor
	}
	
	override init() {
		super.init()
		
		setUp()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		setUp()
	}
	
	override init(layer: AnyObject) {
		super.init(layer: layer)
		
		setUp()
	}
}

// Note: not CATiledLayer, see http://red-glasses.com/index.php/tutorials/catiledlayer-how-to-use-it-how-it-works-what-it-does/
class CanvasLayer: CALayer {
	internal var graphicsLayer = CALayer()
	
	internal var originLayer = createOriginLayer(radius: 10.0)
	
	internal var mainGroup = FreeformGraphicGroup()
	
	private var context = LayerProducingContext()
	
	private var componentUUIDsNeedingUpdate = Set<NSUUID>()
	
	private func setUp() {
		anchorPoint = CGPoint(x: 0.0, y: 1.0)
		
		addSublayer(originLayer)
		
		//mainLayer.yScale = -1.0
		addSublayer(graphicsLayer)
		
		let testLayer = CALayer()
		testLayer.bounds = CGRect(x: 0, y: 0, width: 50.0, height: 50.0)
		testLayer.backgroundColor = Color.SRGB(r: 1.0, g: 0.8, b: 0.8, a: 1.0).CGColor
		testLayer.contents = NSImage(named: "NSApplicationIcon")
		addSublayer(testLayer)
		
		//backgroundColor = NSColor(calibratedWhite: 0.5, alpha: 1.0).CGColor
	}
	
	override init() {
		super.init()
		
		setUp()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		setUp()
	}
	
	override init(layer: AnyObject) {
		super.init(layer: layer)
		
		setUp()
		
		if let canvasLayer = layer as? CanvasLayer {
			mainGroup = canvasLayer.mainGroup
		}
	}
	
	override class func defaultActionForKey(event: String) -> CAAction? {
		return NSNull()
	}
	
	func changeMainGroup(mainGroup: FreeformGraphicGroup, changedComponentUUIDs: Set<NSUUID>) {
		self.mainGroup = mainGroup
		componentUUIDsNeedingUpdate.unionInPlace(changedComponentUUIDs)
		setNeedsDisplay()
	}
	
	override func display() {
		updateGraphicsIfNeeded()
	}
	
	func updateGraphicsIfNeeded() {
		// Copy this to not capture self
		let componentUUIDsNeedingUpdate = self.componentUUIDsNeedingUpdate
		// Bail if nothing to update
		//guard componentUUIDsNeedingUpdate.count > 0 else { return }
		
		//let updateEverything = componentUUIDsNeedingUpdate.contains(mainGroup.UUID)
		let updateEverything = componentUUIDsNeedingUpdate.isEmpty
		let componentUUIDNeedsUpdate: NSUUID -> Bool = updateEverything ? { _ in true } : { componentUUIDsNeedingUpdate.contains($0) }
		
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.0)
		
		updateLayer(graphicsLayer, withGroup: mainGroup, context: context, componentUUIDNeedsUpdate: componentUUIDNeedsUpdate)
		
		CATransaction.commit()
		
		context.finishedUpdating()
		
		self.componentUUIDsNeedingUpdate.removeAll(keepCapacity: true)
	}
	
	func graphicLayerAtPoint(point: CGPoint, deep: Bool = false) -> CALayer? {
		guard let layer = graphicsLayer.childLayerAtPoint(point) else { return nil }
		
		if deep {
			var layer: CALayer = layer
			while let nestedLayer = layer.childLayerAtPoint(point) {
				layer = nestedLayer
			}
			return layer
		}
		else {
			return layer
		}
	}
}

