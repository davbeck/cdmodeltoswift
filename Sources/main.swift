//
//  main.swift
//  modeltoswift
//
//  Created by David Beck on 4/3/17.
//  Copyright © 2017 ThinkUltimate LLC. All rights reserved.
//

import Foundation
import CoreData


if #available(macOS 10.12, *) {
	guard CommandLine.arguments.count > 1, let modelPath = CommandLine.arguments.last else { fatalError("Missing model path") }
	
	cdmodeltoswift(modelPath: modelPath)
		.then({
			exit(0)
		})
		.catch({ error in
			exit(1)
		})
	
	dispatchMain()
}


fatalError("This program requires macOS 10.12 or greater.")
