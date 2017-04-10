//
//  NSPropertyDescription+Generator.swift
//  cdmodeltoswift
//
//  Created by David Beck on 4/10/17.
//
//

import Foundation
import CoreData


extension NSPropertyDescription {
	var needsAccessors: Bool {
		if forceAccessors {
			return true
		}
		
		if rawType != nil {
			return true
		}
		
		if let attribute = self as? NSAttributeDescription {
			switch attribute.attributeType {
			case .integer16AttributeType,
			     .integer32AttributeType,
			     .integer64AttributeType:
				return self.isOptional
			case .decimalAttributeType,
			     .doubleAttributeType,
			     .floatAttributeType:
				return self.isOptional
			case .booleanAttributeType:
				return self.isOptional
			case .stringAttributeType:
				return !self.isOptional
			case .dateAttributeType:
				return !self.isOptional
			case .binaryDataAttributeType:
				return !self.isOptional
			case .transformableAttributeType:
				return !self.isOptional
			case .objectIDAttributeType,
			     .undefinedAttributeType:
				return false
			}
		} else {
			return false
		}
	}
	
	var forceAccessors: Bool {
		if let override = userInfo?["forceAccessors"] as? String {
			switch override {
			case "true", "1":
				return true
			default:
				return false
			}
		}
		
		return false
	}
	
	var shouldGenerate: Bool {
		if let override = userInfo?["generate"] as? String {
			switch override {
			case "true", "1":
				return true
			default:
				return false
			}
		}
		
		return true
	}
	
	var shouldOverride: Bool {
		if let override = userInfo?["override"] as? String {
			switch override {
			case "true", "1":
				return true
			default:
				return false
			}
		}
		
		return false
	}
	
	var typeOverride: String? {
		if let typeOverride = self.userInfo?["type"] as? String, !typeOverride.isEmpty {
			return  typeOverride
		}
		
		return nil
	}
	
	var rawType: String? {
		if let typeOverride = self.userInfo?["rawType"] as? String, !typeOverride.isEmpty {
			return  typeOverride
		}
		
		return nil
	}
	
	var storageType: String {
		if let typeOverride = self.typeOverride {
			return  typeOverride
		} else if let attribute = self as? NSAttributeDescription {
			switch attribute.attributeType {
			case .integer16AttributeType:
				return "Int16"
			case .integer32AttributeType:
				return "Int32"
			case .integer64AttributeType:
				return "Int64"
			case .decimalAttributeType:
				return "Decimal"
			case .doubleAttributeType:
				return "Double"
			case .floatAttributeType:
				return "Float"
			case .booleanAttributeType:
				return "Bool"
			case .stringAttributeType:
				return "String"
			case .dateAttributeType:
				return "Date"
			case .binaryDataAttributeType:
				return "Data"
			case .transformableAttributeType,
			     .objectIDAttributeType,
			     .undefinedAttributeType:
				return attribute.attributeValueClassName ?? "Any"
			}
		} else if let relationship = self as? NSRelationshipDescription {
			guard let destinationEntity = relationship.destinationEntity else { return "Any" }
			
			if relationship.isToMany {
				if relationship.isOrdered {
					return "NSOrderedSet"
				} else {
					return "Set<\(destinationEntity.swiftTypeName)>"
				}
			} else {
				return destinationEntity.swiftTypeName
			}
		} else {
			return "Any"
		}
	}
	
	var baseType: String {
		if let typeOverride = rawType {
			return  typeOverride
		}
		
		return storageType
	}
	
	var isSwiftOptional: Bool {
		if let isTypeOptional = userInfo?["isTypeOptional"] as? String {
			switch isTypeOptional {
			case "true", "1":
				return true
			default:
				return false
			}
		}
		
		return isOptional
	}
	
	var swiftType: String {
		var type = self.baseType
		
		if self.isSwiftOptional {
			type.append("?")
		}
		
		return type
	}
	
	var swiftAccess: String {
		if let override = self.userInfo?["access"] as? String {
			return override
		} else {
			return "public"
		}
	}
	
	var swiftAttribute: String? {
		if rawType != nil {
			return nil
		}
		
		if isSwiftOptional, let attribute = self as? NSAttributeDescription {
			switch attribute.attributeType {
			case .integer16AttributeType,
			     .integer32AttributeType,
			     .integer64AttributeType,
			     .decimalAttributeType,
			     .doubleAttributeType,
			     .floatAttributeType,
			     .booleanAttributeType:
				return nil
			case .stringAttributeType,
			     .dateAttributeType,
			     .binaryDataAttributeType,
			     .transformableAttributeType,
			     .objectIDAttributeType,
			     .undefinedAttributeType:
				break
			}
		}
		
		return needsAccessors ? "@objc" : "@NSManaged"
	}
	
	var fallbackValue: String? {
		guard !self.isSwiftOptional else { return nil }
		
		if let fallbackValue = userInfo?["fallbackValue"] as? String {
			return fallbackValue
		}
		
		if self.baseType == "UUID" {
			return "UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))"
		} else if let attribute = self as? NSAttributeDescription, self.typeOverride == nil {
			switch attribute.attributeType {
			case .integer16AttributeType,
			     .integer32AttributeType,
			     .integer64AttributeType,
			     .decimalAttributeType,
			     .doubleAttributeType,
			     .floatAttributeType:
				return "0"
			case .booleanAttributeType:
				return "false"
			case .stringAttributeType:
				return "\"\""
			case .dateAttributeType:
				return "Date()"
			case .binaryDataAttributeType:
				return "Data()"
			case .transformableAttributeType,
			     .objectIDAttributeType,
			     .undefinedAttributeType:
				break
			}
		}
		
		return nil
	}
	
	var customGetter: String {
		var output = ""
		
		let key = "\"\(name)\""
		
		output += "\t\tget {\n"
		
		output += "\t\t\tself.willAccessValue(forKey: \(key))\n"
		output += "\t\t\tlet value = self.primitiveValue(forKey: \(key)) as? \(storageType)\n"
		output += "\t\t\tself.didAccessValue(forKey: \(key))\n\n"
		
		if let typeOverride = rawType {
			output += "\t\t\treturn value.flatMap({ \(typeOverride)(rawValue: $0) })"
		} else {
			output += "\t\t\treturn value"
		}
		if let fallbackValue = fallbackValue {
			output += " ?? \(fallbackValue)"
		}
		output += "\n"
		
		output += "\t\t}"
		
		return output
	}
	
	var customSetter: String {
		var output = ""
		
		let key = "\"\(name)\""
		
		output += "\t\tset {\n"
		
		output += "\t\t\tself.willChangeValue(forKey: \(key))\n"
		
		output += "\t\t\tself.setPrimitiveValue("
		if rawType != nil {
			if isSwiftOptional {
				output += "newValue?.rawValue"
			} else {
				output += "newValue.rawValue"
			}
		} else {
			output += "newValue"
		}
		output += ", forKey: \(key))\n"
		
		output += "\t\t\tself.didChangeValue(forKey: \(key))\n"
		
		output += "\t\t}\n"
		
		return output
	}
	
	var customSwiftAccessory: String {
		var output = ""
		
		output += " {\n"
		output += [
			customGetter,
			customSetter,
			].joined(separator: "\n")
		output += "\t}"
		
		return output
	}
	
	var swiftDeclaration: String {
		var output = ""
		if let userInfo = self.userInfo, userInfo.count > 0 {
			do {
				let formatted = try String(data: JSONSerialization.data(withJSONObject: userInfo), encoding: .utf8) ?? ""
				output += "\t// userInfo: \(formatted)\n"
			} catch {
				print("failed to format user info: \(error)")
			}
		}
		output += "\t"
		if let swiftAttribute = swiftAttribute {
			output += swiftAttribute + " "
		}
		if shouldOverride {
			output += "override "
		}
		output += "\(swiftAccess) var \(name): \(swiftType)"
		if needsAccessors {
			output += customSwiftAccessory
		}
		return output
	}
}

extension NSRelationshipDescription {
	override var needsAccessors: Bool {
		if isToMany {
			return true // unfortunately, CD often returns nil for collections
		} else {
			return super.needsAccessors
		}
	}
	
	override var isSwiftOptional: Bool {
		if isToMany {
			return false
		} else {
			return super.isSwiftOptional
		}
	}
	
	override var fallbackValue: String? {
		if isToMany {
			return "[]"
		}
		
		return nil
	}
}
