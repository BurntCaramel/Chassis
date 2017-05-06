//
//  Element.swift
//  Chassis
//
//  Created by Patrick Smith on 29/11/2015.
//  Copyright © 2015 Burnt Caramel. All rights reserved.
//

import Foundation


public protocol ElementType : JSONRepresentable {
	associatedtype Kind: KindType
	associatedtype Alteration: AlterationType
	
	var kind: Kind { get }
	
	mutating func alter(_ alteration: Alteration) throws
	
	// TODO: remove
	mutating func makeElementAlteration(_ alteration: ElementAlteration) -> Bool
	
	var defaultDesignations: [Designation] { get }
	
	//init(sourceJSON: JSON, kind: Kind) throws
}


extension ElementType where Kind == SingleKind {
	public var kind: SingleKind {
		return .sole
	}
}

extension ElementType where Alteration == NoAlteration {
	public mutating func alter(_ alteration: Alteration) throws {}
}


public protocol ElementContainable {
	var descendantElementReferences: AnyCollection<ElementReferenceSource<AnyElement>> { get }
}

extension ElementType {
	//public typealias Alteration = NoAlteration
	
	mutating public func makeElementAlteration(_ alteration: ElementAlteration) -> Bool {
		return false
	}
	
	public var defaultDesignations: [Designation] {
		return []
	}
}

extension ElementType where Alteration == ElementAlteration {
	public mutating func alter(_ alteration: ElementAlteration) throws {
		makeElementAlteration(alteration)
	}
}

extension ElementType {
	public subscript(alterations: Alteration...) -> () throws -> Self {
		do {
			var copy = self
			for alteration in alterations {
				try copy.alter(alteration)
			}
			return { copy }
		}
		catch {
			return { throw error }
		}
	}
}

extension ElementType {
	func alteredBy(_ alteration: ElementAlteration) -> Self {
		var copy = self
		guard copy.makeElementAlteration(alteration) else { return self }
		return copy
	}
}
