//
//  DocumentState.swift
//  Chassis
//
//  Created by Patrick Smith on 8/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation
import Grain


enum EditedElement {
	case stage(sectionUUID: NSUUID, stageUUID: NSUUID)
	
	//case graphicComponent(NSUUID)
}

extension EditedElement : JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		self = try source.decodeChoices(
	  { try .stage(sectionUUID: $0.decodeUUID("sectionUUID"), stageUUID: $0.decodeUUID("stageUUID")) }
		)
	}
	
	func toJSON() -> JSON {
		switch self {
		case let .stage(sectionUUID, stageUUID):
			return .ObjectValue([
				"sectionUUID": sectionUUID.toJSON(),
				"stageUUID": stageUUID.toJSON(),
				])
		}
	}
}


struct DocumentState {
	var work: Work!
	var editedElement: EditedElement?
	var stageEditingMode: StageEditingMode = .visuals
	
	var shapeStyleUUIDForCreating: NSUUID?
}

extension DocumentState: JSONObjectRepresentable {
	init(source: JSONObjectDecoder) throws {
		let work: Work = try source.decode("work")
		
		try self.init(
			work: work,
			editedElement: source.decodeOptional("editedElement"),
			stageEditingMode: source.decode("stageEditingMode"),
			shapeStyleUUIDForCreating: source.optional("shapeStyleUUIDForCreating")?.decodeStringUsing(NSUUID.init)
		)
	}
	
	func toJSON() -> JSON {
		return .ObjectValue([
			"work": work.toJSON(),
			"editedElement": editedElement.toJSON(),
			"stageEditingMode": stageEditingMode.toJSON(),
			"shapeStyleUUIDForCreating": shapeStyleUUIDForCreating.toJSON()
		])
	}
}


class DocumentStateController {
	var displayError: ((ErrorType) -> ())!
	var undoManager: NSUndoManager!
	
	var state = DocumentState()
	
	var activeToolIdentifier: CanvasToolIdentifier = .Move {
		didSet {
			eventListeners.send(
				.activeToolChanged(toolIdentifier: activeToolIdentifier)
			)
		}
	}
	
	var eventListeners = EventListeners<WorkControllerEvent>()
	
	private var contentLoader: ContentLoader!
	
	init() {
		contentLoader = ContentLoader(
			contentDidLoad: self.contentDidLoad,
			localContentDidHash: self.localContentDidHash,
			didErr: self.didErrLoading,
			callbackService: .mainQueue
		)
	}
}

extension DocumentStateController {
	func contentDidLoad(contentReference: ContentReference) {
		eventListeners.send(
			.contentLoaded(contentReference: contentReference)
		)
	}
	
	func localContentDidHash(fileURL: NSURL) {
		// TODO
	}
	
	func didErrLoading(error: ErrorType) {
		displayError(error)
	}
}

extension DocumentStateController {
	func addEventListener(createReceiver: (unsubscriber: Unsubscriber) -> (WorkControllerEvent -> ())) {
		eventListeners.add(createReceiver)
	}
	
	func sendEvent(event: WorkControllerEvent) {
		eventListeners.send(event)
	}
}

extension DocumentStateController {
	func alterActiveStage(stageAlteration: StageAlteration) {
		guard case let .stage(sectionUUID, stageUUID)? = state.editedElement else {
			return
		}
		
		let workAlteration = WorkAlteration.alterSections(
			.alterElement(
				uuid: sectionUUID,
				alteration: .alterStages(
					.alterElement(
						uuid: stageUUID,
						alteration: stageAlteration
					)
				)
			)
		)
		
		var change: WorkChange
		
		switch stageAlteration {
		case let .alterGuideConstructs(guideConstructsAlteration):
			change = .guideConstructs(
				sectionUUID: sectionUUID,
				stageUUID: stageUUID,
				instanceUUIDs: guideConstructsAlteration.affectedUUIDs
			)
		case let .alterGraphicConstructs(graphicConstructsAlteration):
			change = .graphics(
				sectionUUID: sectionUUID,
				stageUUID: stageUUID,
				instanceUUIDs: graphicConstructsAlteration.affectedUUIDs
			)
		default:
			change = .stage(
				sectionUUID: sectionUUID,
				stageUUID: stageUUID
			)
		}
		
		alterWork(workAlteration, change: change)
	}
	
	func alterWork(alteration: WorkAlteration, change: WorkChange) {
		var work = state.work
		
		do {
			try work.alter(alteration)
		}
		catch {
			displayError(error)
		}
		
		changeWork(work, change: change)
	}
	
	private func changeWork(work: Work, change: WorkChange) {
		let oldWork = state.work
		
		if let undoManager = undoManager {
			undoManager.registerUndoWithCommand {
				[weak self] in
				self?.changeWork(oldWork, change: change)
			}
			
			undoManager.setActionName("Graphics changed")
		}
		
		state.work = work
		
		eventListeners.send(.workChanged(work: work, change: change))
	}
	
	private func setStageEditingMode(stageEditingMode: StageEditingMode) {
		state.stageEditingMode = stageEditingMode
		
		eventListeners.send(.stageEditingModeChanged(stageEditingMode: stageEditingMode))
	}
	
	private func processAction(action: WorkControllerAction) {
		switch action {
		case let .alterWork(alteration):
			alterWork(alteration, change: .entirety)
		case let .alterActiveStage(alteration):
			alterActiveStage(alteration)
		case let .changeStageEditingMode(mode):
			setStageEditingMode(mode)
		default:
			fatalError("Unimplemented")
		}
	}
	
	func dispatchAction(action: WorkControllerAction) {
		GCDService.mainQueue.async{
			self.processAction(action)
		}
	}
}

extension DocumentStateController : WorkControllerQuerying {
	var work: Work {
		return state.work
	}
	
	var editedStage: (stage: Stage, sectionUUID: NSUUID, stageUUID: NSUUID)? {
		switch state.editedElement {
		case let .stage(sectionUUID, stageUUID)?:
			return work.sections[sectionUUID]?.stages[stageUUID].map{ (
				stage: $0,
				sectionUUID: sectionUUID,
				stageUUID: stageUUID
			) }
		default:
			return nil
		}
	}
	
	var stageEditingMode: StageEditingMode {
		return state.stageEditingMode
	}
	
	func catalogWithUUID(uuid: NSUUID) -> Catalog? {
		if (uuid == state.work.catalog.UUID) {
			return state.work.catalog
		}
		
		return nil
	}
	
	var shapeStyleUUIDForCreating: NSUUID? {
		return state.shapeStyleUUIDForCreating
	}
	
	func loadedContentForReference(contentReference: ContentReference) -> LoadedContent? {
		return contentLoader[contentReference]
	}
}

extension DocumentStateController {
	func setUpDefault() {
		print("setUpDefault")
		// MARK: Catalog
		
		let catalogUUID = NSUUID()
		var catalog = Catalog(UUID: catalogUUID)
		
		let defaultShapeStyle = ShapeStyleDefinition(
			fillColorReference: ElementReferenceSource.Direct(element: Color.sRGB(r: 0.8, g: 0.9, b: 0.3, a: 0.8)),
			lineWidth: 1.0,
			strokeColor: Color.sRGB(r: 0.8, g: 0.9, b: 0.3, a: 0.8)
		)
		let defaultShapeStyleUUID = NSUUID()
		catalog.makeAlteration(.AddShapeStyle(UUID: defaultShapeStyleUUID, shapeStyle: defaultShapeStyle, info: nil))
		
		state.shapeStyleUUIDForCreating = defaultShapeStyleUUID
		
		// MARK: Work
		
		var work = Work()
		work.catalog = catalog
		
		func stageWithHashtag(hashtag: Hashtag) -> Stage {
			return Stage(
				hashtags: [
					hashtag
				],
				name: nil,
				contentConstructs: [],
				bounds: nil,
				guideConstructs: [],
				guideTransforms: [],
				graphicConstructs: []
			)
		}
		
		let section = Section(
			stages: [
				stageWithHashtag(.text("empty")),
				stageWithHashtag(.text("filled"))
			],
			hashtags: [],
			name: "Home",
			contentInputs: []
		)
		
		let sectionUUID = NSUUID()
		let stageUUID = section.stages.items[0].uuid
		
		try! work.alter(
			.alterSections(.add(element: section, uuid: sectionUUID, index: 0))
		)
		
		try! work.usedCatalogItems.usedShapeStyles.alter(.add(
			element: CatalogItemReference(
				itemKind: StyleKind.FillAndStroke,
				itemUUID: defaultShapeStyleUUID,
				catalogUUID: catalogUUID
			),
			uuid: defaultShapeStyleUUID,
			index: 0
			))
		
		state.work = work
		state.editedElement = .stage(sectionUUID: sectionUUID, stageUUID: stageUUID)
	}
}

extension DocumentStateController {
	enum Error: ErrorType {
		case SourceJSONParsing(JSONParseError)
		case SourceJSONDecoding(JSONDecodeError)
		case SourceJSONInvalid
		case SourceJSONMissingKey(String)
		case JSONSerialization
	}
	
	func JSONData() throws -> NSData {
		let json = state.toJSON()
		let serializer = DefaultJSONSerializer()
		let string = serializer.serialize(json)
		
		guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {
			throw Error.JSONSerialization
		}
		
		return data
	}
	
	func readFromJSONData(data: NSData) throws {
		//let source = NSJSONSerialization.JSONObjectWithData(data, options: [])
		
		let bytesPointer = UnsafePointer<UInt8>(data.bytes)
		let buffer = UnsafeBufferPointer(start: bytesPointer, count: data.length)
		
		let parser = GenericJSONParser(buffer)
		do {
			let sourceJSON = try parser.parse()
			
			guard let sourceDecoder = sourceJSON.objectDecoder else {
				throw Error.SourceJSONInvalid
			}
			
			state = try DocumentState(source: sourceDecoder)
		}
		catch let error as JSONParseError {
			print("Error opening document (parsing) \(error)")
			
			throw Error.SourceJSONParsing(error)
		}
		catch let error as JSONDecodeError {
			print("Error opening document (decoding) \(error)")
			
			throw Error.SourceJSONDecoding(error)
		}
		catch {
			throw Error.SourceJSONInvalid
		}
	}
}
