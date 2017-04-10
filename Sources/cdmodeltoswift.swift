import Foundation
import CoreData


@available(macOS 10.12, *)
public func cdmodeltoswift(modelPath: String) -> Promise<Void> {
	let xcdatamodeldURL = URL(fileURLWithPath: modelPath)
	print("xcdatamodeldURL: \(xcdatamodeldURL)")
	
	let outputURL = xcdatamodeldURL.deletingPathExtension().appendingPathExtension("swift")
	print("outputURL: \(outputURL)")
	
	do {
		let modelLastModified = try FileManager.default.attributesOfItem(atPath: modelPath)[.modificationDate] as? Date
		let outputModified = try FileManager.default.attributesOfItem(atPath: outputURL.path)[.modificationDate] as? Date
		
		if let outputModified = outputModified, let modelLastModified = modelLastModified, outputModified > modelLastModified {
			print("model has not been modified")
			return Promise<Void>(value: ())
		}
	} catch {
		print("failed to get last modified dates: \(error)")
	}
	
	let xcodePath = shell("xcode-select -p")
	let momcPath = "\(xcodePath)/usr/bin/momc"
	print("momcPath: \(momcPath)")
	
	let momdURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("momd")
	print("momdURL: \(momdURL)")
	
	shell([momcPath, xcdatamodeldURL.path, momdURL.path])
	
	guard let model = NSManagedObjectModel(contentsOf: momdURL) else { fatalError("Failed to read model") }
	
	
	let group = DispatchGroup()
	
	group.enter()
	DispatchQueue.global().async {
		_ = try? FileManager.default.removeItem(at: momdURL)
		group.leave()
	}
	
	return model.generateSwift()
		.then({ output -> Void in
			print("writing output")
			try output.write(to: outputURL, atomically: true, encoding: .utf8)
			
			group.wait()
		})
}
