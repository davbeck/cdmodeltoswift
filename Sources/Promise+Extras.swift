//
//  Promise+Extras.swift
//  Engagement
//
//  Created by David Beck on 12/15/16.
//  Copyright © 2016 ACS Technologies. All rights reserved.
//

import Foundation


public struct PromiseCheckError: Error {}

extension Promise {
	/// Wait for all the promises you give it to fulfill, and once they have, fulfill itself
	/// with the array of all fulfilled values.
	public static func all<T>(_ promises: [Promise<T>]) -> Promise<[T]> {
		guard !promises.isEmpty else { return Promise<[T]>(value: []) }
		
		let allPromise = Promise<[T]>()
		for promise in promises {
			promise.then({ value in
				if !promises.contains(where: { $0.isRejected || $0.isPending }) {
					allPromise.fulfill(promises.flatMap({ $0.value }))
				}
			}).catch({ error in
				allPromise.reject(error)
			})
		}
		
		return allPromise
	}
	
	/// Resolves itself after some delay.
	/// - parameter delay: In seconds
	public static func delay(_ delay: TimeInterval) -> Promise<()> {
		let promise = Promise<()>()
		
		DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
			promise.fulfill(())
		})
		
		return promise
	}
	
	/// This promise will be rejected after a delay.
	public static func timeout<T>(_ timeout: TimeInterval) -> Promise<T> {
		let promise = Promise<T>()
		
		delay(timeout).then({ _ in
			promise.reject(NSError(domain: "com.khanlou.Promise", code: -1111, userInfo: [NSLocalizedDescriptionKey: "Timed out"]))
		})
		
		return promise
	}
	
	/// Fulfills or rejects with the first promise that completes
	/// (as opposed to waiting for all of them, like `.all()` does).
	public static func race<T>(_ promises: [Promise<T>]) -> Promise<T> {
		let racePromise = Promise<T>()
		
		guard !promises.isEmpty else { fatalError() }
		for promise in promises {
			promise.then(racePromise.fulfill, racePromise.reject)
		}
		
		return racePromise
	}
	public func addTimeout(_ timeout: TimeInterval) -> Promise<Value> {
		return Promise.race(Array([self, Promise<Value>.timeout(timeout)]))
	}
	
	@discardableResult
	public func always(on queue: DispatchQueue, _ onComplete: @escaping () -> Void) -> Promise<Value> {
		return then(on: queue, { _ in
			onComplete()
		}, { _ in
			onComplete()
		})
	}
	
	@discardableResult
	public func always(_ onComplete: @escaping () -> Void) -> Promise<Value> {
		return always(on: DispatchQueue.main, onComplete)
	}
	
	
	public func recover(_ recovery: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
		let promise = Promise()
		
		self.then(fulfill).catch({ error in
			do {
				try recovery(error).then(promise.fulfill, promise.reject)
			} catch (let error) {
				promise.reject(error)
			}
		})
		
		return promise
	}
	
	public func ensure(_ check: @escaping (Value) -> Bool) -> Promise<Value> {
		return self.then({ (value: Value) -> Value in
			guard check(value) else {
				throw PromiseCheckError()
			}
			return value
		})
	}
	
	
	public static func retry<T>(count: Int, delay: TimeInterval, generate: @escaping () -> Promise<T>) -> Promise<T> {
		if count <= 0 {
			return generate()
		}
		
		let promise = Promise<T>()
		generate().recover({ error in
			return self.delay(delay).then({
				return retry(count: count - 1, delay: delay, generate: generate)
			})
		}).then(promise.fulfill).catch(promise.reject)
		return promise
	}
	
	public static func zip<T, U>(_ first: Promise<T>, and second: Promise<U>) -> Promise<(T, U)> {
		let promise = Promise<(T, U)>()
		
		let resolver: (Any) -> Void = { _ in
			if let firstValue = first.value, let secondValue = second.value {
				promise.fulfill((firstValue, secondValue))
			}
		}
		first.then(resolver, promise.reject)
		second.then(resolver, promise.reject)
		
		return promise
	}
}
