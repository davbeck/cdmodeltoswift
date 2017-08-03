//
//  NSEntityDescription+Generator.swift
//  modeltoswift
//
//  Created by David Beck on 4/3/17.
//  Copyright © 2017 ThinkUltimate LLC. All rights reserved.
//

import Foundation
import CoreData


extension NSEntityDescription {
	var swiftTypeName: String {
		return self.managedObjectClassName?.trimmingCharacters(in: CharacterSet(charactersIn: ".")) ?? "NSManagedObject"
	}
	
	
	var swiftSuperclass: String {
		return self.userInfo?["superclass"] as? String ?? "NSManagedObject"
	}
	
	
	func generateExtension() -> Promise<String> {
		return Promise(work: {
			var output = ""
			
			output += "public class \(self.swiftTypeName)Storage: \(self.swiftSuperclass) {\n"
			
			var declarations: Array<String> = []
			declarations += self.attributesByName.values.filter({ $0.shouldGenerate }).sorted(by: { $0.name < $1.name }).map({ $0.swiftDeclaration })
			declarations += self.relationshipsByName.values.filter({ $0.shouldGenerate }).sorted(by: { $0.name < $1.name }).map({ $0.swiftDeclaration })
			
			output += declarations.joined(separator: "\n\n")
			
			output += "\n}\n"
			
			return output
		})
	}
}
