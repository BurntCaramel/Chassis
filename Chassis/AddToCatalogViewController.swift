//
//  AddToCatalogViewController.swift
//  Chassis
//
//  Created by Patrick Smith on 23/01/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Cocoa

class AddToCatalogViewController: NSViewController {
	@IBOutlet var nameField: NSTextField!
	@IBOutlet var designationsField: NSTokenField!
	
	var addCallback: ((name: String, designations: [String]) -> ())?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
	}
	
	@IBAction func add(sender: NSButton) {
		let name = nameField.stringValue
		let designations = designationsField.objectValue as? [String] ?? []
		addCallback?(name: name, designations: designations)
	}
}
