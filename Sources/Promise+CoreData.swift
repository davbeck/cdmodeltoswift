//
//  Promise+CoreData.swift
//  Engagement
//
//  Created by David Beck on 3/30/17.
//  Copyright © 2017 ACS Technologies. All rights reserved.
//

import Foundation
import CoreData


extension NSManagedObjectContext: PromiseQueue {
	public func sendPromiseCallback(_ work: @escaping @convention(block) () -> Void) {
		self.perform(work)
	}
}
