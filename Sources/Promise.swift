//
//  Promise.swift
//  Promise
//
//  Created by Soroush Khanlou on 7/21/16.
//  https://github.com/khanlou/Promise/blob/master/Promise/Promise.swift
//
//
import Foundation


public protocol PromiseQueue {
	func sendPromiseCallback(_ work: @escaping @convention(block) () -> Swift.Void)
}

extension DispatchQueue: PromiseQueue {
	public func sendPromiseCallback(_ work: @escaping @convention(block) () -> Void) {
		self.async(execute: work)
	}
}

extension OperationQueue: PromiseQueue {
	public func sendPromiseCallback(_ work: @escaping @convention(block) () -> Void) {
		self.addOperation(work)
	}
}


private struct Callback<Value> {
	let onFulfilled: (Value) -> Void
	let onRejected: (Error) -> Void
	let queue: PromiseQueue
	
	func callFulfill(_ value: Value) {
		queue.sendPromiseCallback({
			self.onFulfilled(value)
		})
	}
	
	func callReject(_ error: Error) {
		queue.sendPromiseCallback({
			self.onRejected(error)
		})
	}
}

private enum State<Value>: CustomStringConvertible {
	/// The promise has not completed yet.
	/// Will transition to either the `fulfilled` or `rejected` state.
	case pending
	
	/// The promise now has a value.
	/// Will not transition to any other state.
	case fulfilled(value: Value)
	
	/// The promise failed with the included error.
	/// Will not transition to any other state.
	case rejected(error: Error)
	
	
	var isPending: Bool {
		if case .pending = self {
			return true
		} else {
			return false
		}
	}
	
	var isFulfilled: Bool {
		if case .fulfilled = self {
			return true
		} else {
			return false
		}
	}
	
	var isRejected: Bool {
		if case .rejected = self {
			return true
		} else {
			return false
		}
	}
	
	var value: Value? {
		if case let .fulfilled(value) = self {
			return value
		}
		return nil
	}
	
	var error: Error? {
		if case let .rejected(error) = self {
			return error
		}
		return nil
	}
	
	
	var description: String {
		switch self {
		case .fulfilled(let value):
			return "Fulfilled (\(value))"
		case .rejected(let error):
			return "Rejected (\(error))"
		case .pending:
			return "Pending"
		}
	}
}


public final class Promise<Value> {
	private var state: State<Value>
	private let lockQueue = DispatchQueue(label: "promise_lock_queue", qos: .userInitiated)
	private var callbacks: [Callback<Value>] = []
	
	public init() {
		state = .pending
	}
	
	public init(value: Value) {
		state = .fulfilled(value: value)
	}
	
	public init(error: Error) {
		state = .rejected(error: error)
	}
	
	public convenience init(queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated), work: @escaping () throws -> Value) {
		self.init()
		
		queue.async(execute: {
			do {
				let value = try work()
				self.fulfill(value)
			} catch let error {
				self.reject(error)
			}
		})
	}
	
	/// - note: This one is "flatMap"
	@discardableResult
	public func then<NewValue>(on queue: PromiseQueue = DispatchQueue.main, _ onFulfilled: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {
		let promise = Promise<NewValue>()
		
		self.addCallbacks(
			on: queue,
			onFulfilled: { value in
				do {
					try onFulfilled(value).then(promise.fulfill, promise.reject)
				} catch let error {
					promise.reject(error)
				}
			},
			onRejected: reject
		)
		
		return promise
	}
	
	/// - note: This one is "map"
	@discardableResult
	public func then<NewValue>(on queue: PromiseQueue = DispatchQueue.main, _ onFulfilled: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {
		return then(on: queue, { (value) -> Promise<NewValue> in
			do {
				return Promise<NewValue>(value: try onFulfilled(value))
			} catch let error {
				return Promise<NewValue>(error: error)
			}
		})
	}
	
	@discardableResult
	public func then(on queue: PromiseQueue = DispatchQueue.main, _ onFulfilled: @escaping (Value) -> Void, _ onRejected: @escaping (Error) -> Void = { _ in }) -> Promise<Value> {
		let promise = Promise<Value>()
		
		self.addCallbacks(
			on: queue,
			onFulfilled: { value in
				onFulfilled(value)
				promise.fulfill(value)
			},
			onRejected: { error in
				onRejected(error)
				promise.reject(error)
			}
		)
		
		return promise
	}
	
	@discardableResult
	public func `catch`(on queue: PromiseQueue = DispatchQueue.main, _ onRejected: @escaping (Error) -> Void) -> Promise<Value> {
		return then(on: queue, { _ in }, onRejected)
	}
	
	public func reject(_ error: Error) {
		updateState(.rejected(error: error))
	}
	
	public func fulfill(_ value: Value) {
		updateState(.fulfilled(value: value))
	}
	
	public var isPending: Bool {
		return !isFulfilled && !isRejected
	}
	
	public var isFulfilled: Bool {
		return value != nil
	}
	
	public var isRejected: Bool {
		return error != nil
	}
	
	public var value: Value? {
		return lockQueue.sync(execute: {
			return self.state.value
		})
	}
	
	public var error: Error? {
		return lockQueue.sync(execute: {
			return self.state.error
		})
	}
	
	private func updateState(_ state: State<Value>) {
		guard self.isPending else { return }
		lockQueue.sync(execute: {
			self.state = state
		})
		fireCallbacksIfCompleted()
	}
	
	private func addCallbacks(on queue: PromiseQueue, onFulfilled: @escaping (Value) -> Void, onRejected: @escaping (Error) -> Void) {
		let callback = Callback(onFulfilled: onFulfilled, onRejected: onRejected, queue: queue)
		lockQueue.async(execute: {
			self.callbacks.append(callback)
		})
		fireCallbacksIfCompleted()
	}
	
	private func fireCallbacksIfCompleted() {
		lockQueue.async(execute: {
			guard !self.state.isPending else { return }
			self.callbacks.forEach { callback in
				switch self.state {
				case let .fulfilled(value):
					callback.callFulfill(value)
				case let .rejected(error):
					callback.callReject(error)
				default:
					break
				}
			}
			self.callbacks.removeAll()
		})
	}
}
