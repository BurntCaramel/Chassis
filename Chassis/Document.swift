//
//  Document.swift
//  Chassis
//
//  Created by Patrick Smith on 14/07/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa
import Grain


class Document: NSDocument {
	typealias WorkChangeListener = WorkChange -> ()
	typealias EventReceiver = WorkControllerEvent -> ()
	
	private var stateController = DocumentStateController()
	
	private var eventSinks = [NSUUID: EventReceiver]()
	
	internal var activeToolIdentifier: CanvasToolIdentifier {
		get {
			return stateController.activeToolIdentifier
		}
		set {
			stateController.activeToolIdentifier = newValue
			
			sendWorkEvent(
				.activeToolChanged(toolIdentifier: activeToolIdentifier)
			)
		}
	}
	
	private func errorChangingStage(error: ErrorType) {
		// self.presentError(error)
		// TODO
	}
	
	/*override init() {
	super.init()
	
	stateController.setUpDefault()
	}*/
	
	convenience init(type typeName: String) throws {
		self.init()
		
		print("INIT")
		
		fileType = typeName
		
		stateController.setUpDefault()
	}
	
	override class func autosavesInPlace() -> Bool {
		return true
	}
	
	override func canAsynchronouslyWriteToURL(url: NSURL, ofType typeName: String, forSaveOperation saveOperation: NSSaveOperationType) -> Bool {
		return true
	}
	
	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: "Main", bundle: nil)
		
		let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! MainWindowController
		
		self.addWindowController(windowController)
		windowController.didSetDocument(self)
	}
}

extension Document {
	override func dataOfType(typeName: String) throws -> NSData {
		return try stateController.JSONData()
	}
	
	override func readFromData(data: NSData, ofType typeName: String) throws {
		try stateController.readFromJSONData(data)
	}
}

extension Document {
	// TODO: remove
	@objc private func performUndoCommand(command: UndoCommand) {
		command.perform()
	}
	
	private func sendWorkEvent(event: WorkControllerEvent) {
		for receiver in eventSinks.values {
			receiver(event)
		}
	}
	
	private func alterActiveStage(stageAlteration: StageAlteration) {
		guard case let .stage(sectionUUID, stageUUID)? = stateController.state.editedElement else {
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
	
	private func alterWork(alteration: WorkAlteration, change: WorkChange) {
		var work = stateController.state.work
		
		do {
			try work.alter(alteration)
		}
		catch {
			self.errorChangingStage(error)
		}
		
		changeWork(work, change: change)
	}
	
	private func changeWork(work: Work, change: WorkChange) {
		let oldWork = stateController.state.work
		
		if let undoManager = undoManager {
			undoManager.registerUndoWithCommand {
				self.changeWork(oldWork, change: change)
			}
			
			undoManager.setActionName("Graphics changed")
		}
		
		stateController.state.work = work
		
		sendWorkEvent(.workChanged(work: work, change: change))
	}
	
	private func setStageEditingMode(stageEditingMode: StageEditingMode) {
		stateController.state.stageEditingMode = stageEditingMode
		
		sendWorkEvent(.stageEditingModeChanged(stageEditingMode: stageEditingMode))
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

extension Document {
	@IBAction func changeStageEditingMode(sender: AnyObject) {
		guard let mode = StageEditingMode(sender: sender) else {
	  return
		}
		
		dispatchAction(.changeStageEditingMode(mode))
	}
}

extension Document {
	func addGraphicConstruct(graphicConstruct: GraphicConstruct, instanceUUID: NSUUID = NSUUID()) {
		alterActiveStage(
			.alterGraphicConstructs(
				.add(
					element: graphicConstruct,
					uuid: instanceUUID,
					index: 0
				)
			)
		)
	}
	
	@IBAction func insertImage(sender: AnyObject?) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowedFileTypes = [kUTTypeImage as String]
		
		guard let window = windowForSheet else { return }
		openPanel.beginSheetModalForWindow(window) { result in
			let fileURLs = openPanel.URLs
			for fileURL in fileURLs {
				let imageSource = ImageSource(reference: .localFile(fileURL: fileURL))
				(LoadedImage.load(imageSource, environment: GCDService.utility) + GCDService.mainQueue).perform {
					useLoadedImage in
					do {
						let loadedImage = try useLoadedImage()
						
						self.addGraphicConstruct(
							GraphicConstruct.freeform(
								created: .image(
									image: imageSource,
									origin: .zero,
									size: loadedImage.size,
									imageStyleUUID: NSUUID() /* FIXME */
								),
								createdUUID: NSUUID()
							)
						)
					}
					catch let error as NSError {
						let alert = NSAlert(error: error)
						alert.beginSheetModalForWindow(window) { modalResponse in
							
						}
					}
					catch {
						
					}
				}
			}
		}
	}
}

extension Document {
	var initializationEvents: [WorkControllerEvent] {
		let possibleEvents: [WorkControllerEvent?] = [
			.activeToolChanged(toolIdentifier: activeToolIdentifier)
		]
		
		return possibleEvents.flatMap{ $0 }
	}
	
	@IBAction func setUpWorkController(sender: AnyObject) {
		guard let controller = sender as? WorkControllerType else {
			return
		}
		
		controller.workControllerActionDispatcher = { [weak self] action in
			self?.processAction(action)
		}
		
		controller.workControllerQuerier = stateController
		
		let uuid = NSUUID()
		
		let eventSink = controller.createWorkEventReceiver { [weak self] in
			self?.eventSinks.removeValueForKey(uuid)
		}
		
		// TODO: remove, replace with usage of querier above
		eventSink(.initialize(events: initializationEvents))
		
		eventSinks[uuid] = eventSink
	}
}

extension Document: ToolsMenuTarget {
	@IBAction func changeActiveToolIdentifier(sender: ToolsMenuController) {
		activeToolIdentifier = sender.activeToolIdentifier
	}
	
	@IBAction func updateActiveToolIdentifierOfController(sender: ToolsMenuController) {
		sender.activeToolIdentifier = activeToolIdentifier
	}
}

