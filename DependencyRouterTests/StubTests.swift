//
//  StubTests.swift
//  DependencyRouterTests
//
//  Created by Короткий Виталий on 20.03.2019.
//  Copyright © 2019 ProVir. All rights reserved.
//

import XCTest
@testable import DependencyRouter

final class ServiceOne {
    var value: String = "some-service-one"
}

final class ServiceTwo {
    var value: String = "some-service-two"
}

class SomeServiceFactory {
    let serviceOne = ServiceOne()
    let serviceTwo = ServiceTwo()
}
