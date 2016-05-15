//
//  ElementArrayAlteration.swift
//  Chassis
//
//  Created by Patrick Smith on 29/03/2016.
//  Copyright © 2016 Burnt Caramel. All rights reserved.
//

import Foundation


// MARK: Types

#if false

public protocol ListItemProtocol : JSONRepresentable {
	associatedtype Alteration : AlterationType
	
	var uuid: NSUUID { get }
}

public struct List<Item : ListItemProtocol> {
	public var items: [Item]
}

public enum ListAlteration<Item : ListItemProtocol>: AlterationType {
	case add(item: Item, index: Int?)
	case alter(uuid: NSUUID, alteration: Item.Alteration)
	case replace(item: Item) // TODO: Is this needed with alterItem above?
	case move(uuid: NSUUID, toIndex: Int)
	case remove(uuid: NSUUID)
}

extension ListAlteration {
	var affectedUUIDs: Set<NSUUID> {
		switch self {
		case let .add(item, _):
			return [item.uuid]
		case let .alter(uuid, _):
			return [uuid]
		case let .replace(item):
			return [item.uuid]
		case let .move(uuid, _):
			return [uuid]
		case let .remove(uuid):
			return [uuid]
		}
	}
}

public enum ListAlterationKind : String, KindType {
	case add = "add"
	case alter = "alter"
	case replace = "replace"
	case move = "move"
	case remove = "remove"
}

extension ListAlteration {
	public typealias Kind = ListAlterationKind
	
	public var kind: Kind {
		switch self {
		case .add: return .add
		case .alter: return .alter
		case .replace: return .replace
		case .move: return .move
		case .remove: return .remove
		}
	}
}

#endif




public struct ElementListItem<Element : ElementType> {
	public var uuid: NSUUID
	public var element: Element
}

public struct ElementList<Element : ElementType> {
	public typealias Item = ElementListItem<Element>
	
	public var items: [Item]
}

extension ElementList {
	public init() {
		items = []
	}
	
	public init<S : SequenceType where S.Generator.Element == Element>(elements: S) {
		items = elements.map{
			ElementListItem(uuid: NSUUID(), element: $0)
		}
	}
	
	mutating func merge
		<C: CollectionType where C.Generator.Element == (NSUUID, Element)>
		(with: C)
	{
		items.appendContentsOf(with.lazy.map{ pair in
			ElementListItem(uuid: pair.0, element: pair.1)
		})
	}
}

extension ElementList : ArrayLiteralConvertible {
	public init(arrayLiteral elements: Element...) {
		self.init(elements: elements)
	}
}

extension ElementList {
	var elements: AnyForwardCollection<Element> {
		return AnyForwardCollection(
			items.lazy.map{ $0.element }
		)
	}
	
	var indexed: [NSUUID: Element] {
		var index = [NSUUID: Element]()
		for item in items {
			index[item.uuid] = item.element
		}
		return index
	}
}


public enum ElementListAlteration<Element : ElementType>: AlterationType {
	case add(element: Element, uuid: NSUUID, index: Int?)
	case alterElement(uuid: NSUUID, alteration: Element.Alteration)
	case replaceElement(uuid: NSUUID, newElement: Element) // TODO: Is this needed with alterElement above?
	case move(uuid: NSUUID, toIndex: Int)
	case remove(uuid: NSUUID)
}

extension ElementListAlteration {
	var affectedUUIDs: Set<NSUUID> {
		switch self {
		case let .add(_, uuid, _):
			return [uuid]
		case let .alterElement(uuid, _):
			return [uuid]
		case let .replaceElement(uuid, _):
			return [uuid]
		case let .move(uuid, _):
			return [uuid]
		case let .remove(uuid):
			return [uuid]
		}
	}
}

public enum ElementListAlterationKind : String, KindType {
	case add = "add"
	case alterElement = "alterElement"
	case replaceElement = "replaceElement"
	case move = "move"
	case remove = "remove"
}

extension ElementListAlteration {
	public typealias Kind = ElementListAlterationKind
	
	public var kind: Kind {
		switch self {
		case .add: return .add
		case .alterElement: return .alterElement
		case .replaceElement: return .replaceElement
		case .move: return .move
		case .remove: return .remove
		}
	}
}

public enum ElementListAlterationError : ErrorType {
	case itemNotFound(uuid: NSUUID)
}


// MARK: JSON

extension ElementListItem : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		try self.init(
			uuid: source.decodeUUID("uuid"),
			element: source.decode("element")
		)
	}
	
	public func toJSON() -> JSON {
		return .ObjectValue([
			"uuid": uuid.toJSON(),
			"element": element.toJSON()
		])
	}
}

extension ElementList : JSONRepresentable {
  // Use items array directly 
	public init(sourceJSON: JSON) throws {
		try self.init(
			items: sourceJSON.decodeArray()
		)
	}
	
	public func toJSON() -> JSON {
		return .ArrayValue(
      items.map{ $0.toJSON() }
		)
	}
}

extension ElementListAlteration : JSONObjectRepresentable {
	public init(source: JSONObjectDecoder) throws {
		let type = try source.decode("type") as ElementListAlterationKind
		switch type {
		case .add:
			self = try .add(
				element: source.decode("element"),
				uuid: source.decodeUUID("uuid"),
				index: source.decodeOptional("index")
			)
		case .alterElement:
			self = try .alterElement(
				uuid: source.decodeUUID("uuid"),
				alteration: source.decode("alteration")
			)
		case .replaceElement:
			self = try .replaceElement(
				uuid: source.decodeUUID("uuid"),
				newElement: source.decode("newElement")
			)
		case .move:
			self = try .move(
				uuid: source.decodeUUID("uuid"),
				toIndex: source.decode("toIndex")
			)
		case .remove:
			self = try .remove(
				uuid: source.decodeUUID("uuid")
			)
		}
	}
	
	public func toJSON() -> JSON {
		switch self {
		case let .add(element, uuid, index):
			return .ObjectValue([
				"element": element.toJSON(),
				"uuid": uuid.toJSON(),
				"index": index.toJSON()
			])
		case let .alterElement(uuid, alteration):
			return .ObjectValue([
				"uuid": uuid.toJSON(),
				"alteration": alteration.toJSON()
			])
		case let .replaceElement(uuid, newElement):
			return .ObjectValue([
				"uuid": uuid.toJSON(),
				"newElement": newElement.toJSON()
				])
		case let .move(uuid, toIndex):
			return .ObjectValue([
				"uuid": uuid.toJSON(),
				"toIndex": toIndex.toJSON()
			])
		case let .remove(uuid):
			return .ObjectValue([
				"uuid": uuid.toJSON()
			])
		}
	}
}


// MARK

extension ElementList {
	// O(n)
	public subscript(uuid: NSUUID) -> Element? {
		for item in items {
			if item.uuid == uuid {
				return item.element
			}
		}
		
		return nil
	}
	
	public mutating func alter(alteration: ElementListAlteration<Element>) throws {
		switch alteration {
		case let .add(element, uuid, index):
			let item = Item(uuid: uuid, element: element)
			let index = index ?? items.endIndex
			items.insert(item, atIndex: index)
			
		case let .alterElement(uuid, alteration):
			guard let index = items.indexOf({ $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			var item = items[index]
			try item.element.alter(alteration)
			items[index] = item
			
		case let .replaceElement(uuid, newElement):
			guard let index = items.indexOf({ $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			var item = items[index]
			item.element = newElement
			items[index] = item
			
		case let .move(uuid, toIndex):
			guard let index = items.indexOf({ $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			let item = items.removeAtIndex(index)
			items.insert(item, atIndex: toIndex)

		case let .remove(uuid):
			guard let index = items.indexOf({ $0.uuid == uuid }) else {
				throw ElementListAlterationError.itemNotFound(uuid: uuid)
			}
			
			items.removeAtIndex(index)
		}
	}
}

extension ElementList : ElementType {
	public var kind: SingleKind {
		return .sole
	}
}
