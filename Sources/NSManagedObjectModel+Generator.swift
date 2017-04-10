//
//  NSManagedObjectModel+Generator.swift
//  cdmodeltoswift
//
//  Created by David Beck on 4/7/17.
//
//

import Foundation
import CoreData


extension NSManagedObjectModel {
	func generateSwift() -> Promise<String> {
		let entities = self.entities.sorted(by: { $0.swiftTypeName < $1.swiftTypeName })
		
		let generatePromises = entities.map({ $0.generateExtension() })
		return Promise<String>.all(generatePromises)
			.then({ extensions -> String in
				let extensionsOutput = extensions.joined(separator: "\n\n")
				return "// Generated using modeltoswift\n// https://github.com/davbeck/cdmodeltoswift\n\nimport Foundation\nimport CoreData\n\n\n" + extensionsOutput
			})
	}
}
