//
//  main.swift
//  modeltoswift
//
//  Created by David Beck on 4/3/17.
//  Copyright © 2017 ThinkUltimate LLC. All rights reserved.
//

import Foundation
import CoreData


let optionPrefix = "--"


if #available(macOS 10.12, *) {
	let arguments = CommandLine.arguments.dropFirst() // first is always the path to the executable
	let models = arguments.filter({ !$0.hasPrefix(optionPrefix) })
	guard models.count > 0 else { fatalError("Missing model path") }
	
	let options = arguments.flatMap({ arg -> Option? in
		guard let range = arg.range(of: "--"), range.lowerBound == arg.startIndex else { return nil }
		return Option(rawValue: arg.substring(from: range.upperBound))
	})
	
	cdmodeltoswift(modelPaths: models, options: options)
		.then({ _ in
			exit(0)
		})
		.catch({ error in
			exit(1)
		})
	
	dispatchMain()
}


fatalError("This program requires macOS 10.12 or greater.")
