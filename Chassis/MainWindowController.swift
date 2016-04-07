//
//  MainWindowController.swift
//  Chassis
//
//  Created by Patrick Smith on 5/09/2015.
//  Copyright (c) 2015 Burnt Caramel. All rights reserved.
//

import Cocoa


var elementStoryboard = NSStoryboard(name: "Element", bundle: nil)

class ToolbarPopoverManager: NSResponder {
	var sectionsPopoverController: PopoverController<SectionListUIController> = PopoverController {
		let vc = elementStoryboard.instantiateControllerWithIdentifier("sections") as! SectionListUIController
		
		return vc
	}
	
	var addToCatalogPopoverController: PopoverController<AddToCatalogViewController> = PopoverController {
		let vc = elementStoryboard.instantiateControllerWithIdentifier("catalog-add") as! AddToCatalogViewController
		
		vc.addCallback = { name, designations in
			// TODO
		}
		
		return vc
	}
	
	lazy var catalogListPopoverController: PopoverController<CatalogListViewController> = PopoverController {
		let vc = elementStoryboard.instantiateControllerWithIdentifier("catalog-list") as! CatalogListViewController
		
		vc.changeInfoCallback = { UUID, info in
			// TODO
		}
		
		return vc
	}
}

class MainWindowController : NSWindowController {
	let toolbarPopoverManager = ToolbarPopoverManager()
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		toolbarPopoverManager.nextResponder = self
		
		//window?.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
	}
	
	@IBAction func setUpWorkController(sender: AnyObject) {
		print("setUpWorkController \(sender)")
		print("document \(document)")
		
		if let document = self.document as? Document {
			print("document.setUpWorkController")
			document.setUpWorkController(sender)
		}
	}
}


enum ToolbarItemRepresentative: String {
	case outlineShow = "outline-show"
	case layersShow = "layers-show"
	case catalogAdd = "catalog-add"
	case catalogShow = "catalog-show"
}

extension ToolbarItemRepresentative {
	var action: Selector {
		switch self {
		case .outlineShow: return #selector(ToolbarPopoverManager.showSectionsPopover(_:))
		case .layersShow: return #selector(ToolbarPopoverManager.showLayersPopover(_:))
		case .catalogAdd: return #selector(ToolbarPopoverManager.showAddToCatalogPopover(_:))
		case .catalogShow: return #selector(ToolbarPopoverManager.showCatalogListPopover(_:))
		}
	}
}

func setUpImageToolbarButton(button: NSButton) {
	button.imagePosition = .ImageOnly
	
	var frame = button.frame
	frame.size.width = 36
	button.frame = frame
}

extension ToolbarItemRepresentative {
	func setUpItem(item: NSToolbarItem, target: AnyObject) {
		var imageButton: NSButton?
		switch self {
		case .outlineShow, .layersShow, .catalogAdd, .catalogShow:
			imageButton = (item.view as! NSButton)
		}
		
		if let imageButton = imageButton {
			setUpImageToolbarButton(imageButton)
			imageButton.target = target
			imageButton.action = action
		}
	}
}

extension ToolbarPopoverManager {
	func togglePopover(popover: NSPopover, button: NSButton) {
		popover.nextResponder = self
		popover.contentViewController?.nextResponder = self
		
		if popover.shown {
			popover.close()
		}
		else {
			popover.showRelativeToRect(.zero, ofView: button, preferredEdge: .MinY)
		}
	}
	
	@IBAction func showSectionsPopover(sender: NSButton) {
		togglePopover(sectionsPopoverController.popover, button: sender)
	}
	
	@IBAction func showLayersPopover(sender: NSButton) {
		
	}
	
	@IBAction func showAddToCatalogPopover(sender: NSButton) {
		togglePopover(addToCatalogPopoverController.popover, button: sender)
	}
	
	@IBAction func showCatalogListPopover(sender: NSButton) {
		togglePopover(catalogListPopoverController.popover, button: sender)
	}
}

extension MainWindowController: NSToolbarDelegate {
	func toolbarWillAddItem(notification: NSNotification) {
		let item = notification.userInfo!["item"] as! NSToolbarItem
		if let representative = ToolbarItemRepresentative(rawValue: item.itemIdentifier) {
			representative.setUpItem(item, target: toolbarPopoverManager)
		}
	}
}
