//
//  shell.swift
//  modeltoswift
//
//  Created by David Beck on 4/3/17.
//  Copyright © 2017 ThinkUltimate LLC. All rights reserved.
//

import Foundation


@discardableResult
func shell(_ args: String) -> String {
	return shell(args.components(separatedBy: .whitespaces))
}


@discardableResult
func shell(_ args: [String]) -> String {
	let command = args.map({ ($0.rangeOfCharacter(from: .whitespacesAndNewlines) == nil) ? $0 : "\"\($0)\"" }).joined(separator: " ")
	print("shell: \(command)")
	
	let task = Process()
	task.launchPath = "/usr/bin/env"
	task.arguments = args
	
	let pipe = Pipe()
	task.standardOutput = pipe
	
	task.launch()
	task.waitUntilExit()
	
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	guard let output = String(data: data, encoding: String.Encoding.utf8) else { return "" }
	
	if output.characters.count > 0 {
		let lastIndex = output.index(before: output.endIndex)
		return output[output.startIndex ..< lastIndex]
	}
	
	return output
}
