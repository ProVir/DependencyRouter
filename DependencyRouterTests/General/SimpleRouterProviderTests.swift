//
//  SimpleRouterProviderTests.swift
//  DependencyRouterTests
//
//  Created by Короткий Виталий on 20.03.2019.
//  Copyright © 2019 ProVir. All rights reserved.
//

import XCTest
@testable import DependencyRouter

class SimpleRouterProviderTests: XCTestCase {
    var someServices = SomeServiceFactory()

    override func tearDown() {
        someServices = SomeServiceFactory()
    }

    func testSupportFactoryRouters() {
        let provider = makeSimpleRouterProvider()
        let multiProvider = makeMultiRouterProviderWithAllContainers()

        XCTAssertEqual(provider.isSupport(factoryType: SomeFactoryRouterUnique.self), true)
        XCTAssertEqual(provider.isSupport(factoryType: SomeFactoryRouterGlobal.self), true)
        XCTAssertEqual(provider.isSupport(factoryType: SomeFactoryRouterFullUnique.self), false)

        XCTAssertEqual(multiProvider.isSupport(factoryType: SomeFactoryRouterUnique.self), true)
        XCTAssertEqual(multiProvider.isSupport(factoryType: SomeFactoryRouterGlobal.self), true)
        XCTAssertEqual(multiProvider.isSupport(factoryType: SomeFactoryRouterFullUnique.self), true)
    }

    func testCreateFactoryWithUniqueContainer() {
        let provider = makeSimpleRouterProvider()

        let factory: SomeFactoryRouterUnique = provider.factoryOrFatalError()
        XCTAssert(provider === factory.container.routerProvider)

        factory.container.serviceOne.value = "some-test1"
        XCTAssertEqual(factory.container.serviceOne.value, someServices.serviceOne.value)
    }

    func testCreateFactoryWithGlobalContainer() {
        let provider = makeSimpleRouterProvider()

        let factory: SomeFactoryRouterGlobal = provider.factoryOrFatalError()
        XCTAssert(someServices === factory.container)

        factory.container.serviceOne.value = "some-test2"
        XCTAssertEqual(factory.container.serviceOne.value, someServices.serviceOne.value)
    }

    func testCreateFactoryWithFullUniqueContainer() {
        let provider = makeSimpleRouterProvider()

        do {
            _ = try provider.factory(SomeFactoryRouterFullUnique.self)
            XCTFail("FactoryRouter not need support create from provider")
        } catch { }
    }

    func testCreateFactoryWithUniqueContainerFromMultiAsSimple() {
        let provider = makeMultiRouterProviderAsSimple()

        let factory: SomeFactoryRouterUnique = provider.factoryOrFatalError()
        XCTAssert(provider === factory.container.routerProvider)

        factory.container.serviceOne.value = "some-test3"
        XCTAssertEqual(factory.container.serviceOne.value, someServices.serviceOne.value)
    }

    func testCreateFactoryWithGlobalContainerFromMultiAsSimple() {
        let provider = makeMultiRouterProviderAsSimple()

        let factory: SomeFactoryRouterGlobal = provider.factoryOrFatalError()
        XCTAssert(someServices === factory.container)

        factory.container.serviceOne.value = "some-test4"
        XCTAssertEqual(factory.container.serviceOne.value, someServices.serviceOne.value)
    }

    func testCreateFactoryWithFullUniqueContainerFromMultiAsSimple() {
        let provider = makeMultiRouterProviderAsSimple()

        do {
            _ = try provider.factory(SomeFactoryRouterFullUnique.self)
            XCTFail("FactoryRouter not need support create from provider")
        } catch { }
    }

    func testCreateFactoryWithUniqueContainerFromMulti() {
        let provider = makeMultiRouterProviderWithAllContainers()

        let factory: SomeFactoryRouterUnique = provider.factoryOrFatalError()
        XCTAssert(factory.container.routerProvider == nil)

        factory.container.serviceOne.value = "some-test5"
        XCTAssert(factory.container.serviceOne.value != someServices.serviceOne.value)
    }

    func testCreateFactoryWithGlobalContainerFromMulti() {
        let provider = makeMultiRouterProviderWithAllContainers()

        let factory: SomeFactoryRouterGlobal = provider.factoryOrFatalError()
        XCTAssert(someServices === factory.container)

        factory.container.serviceOne.value = "some-test6"
        XCTAssert(factory.container.serviceOne.value == someServices.serviceOne.value)
    }

    func testCreateFactoryWithFullUniqueContainerFromMulti() {
        let provider = makeMultiRouterProviderWithAllContainers()

        let factory: SomeFactoryRouterUnique = provider.factoryOrFatalError()
        XCTAssert(factory.container.routerProvider == nil)

        factory.container.serviceOne.value = "some-test7"
        XCTAssert(factory.container.serviceOne.value != someServices.serviceOne.value)
    }
}

extension SimpleRouterProviderTests {
    private func makeSimpleRouterProvider() -> RouterProvider {
        return SimpleRouterProvider(someServices)
    }

    private func makeMultiRouterProviderAsSimple() -> RouterProvider {
        return MultiRouterProvider([someServices])
    }

    private func makeMultiRouterProviderWithAllContainers() -> RouterProvider {
        let container1 = SomeFactoryRouterUnique.Container(routerProvider: nil, serviceOne: ServiceOne())
        let container2 = SomeFactoryRouterFullUnique.Container(serviceOne: ServiceOne())
        return MultiRouterProvider([container1, container2, someServices])
    }
}

private struct SomeFactoryRouterUnique: FactoryRouter {
    let container: Container
    struct Container {
        let routerProvider: RouterProvider?
        let serviceOne: ServiceOne
    }
}

extension SomeFactoryRouterUnique.Container: RouterServiceContainer {
    init(_ services: SomeServiceFactory, routerProvider provider: RouterProvider) {
        routerProvider = provider
        serviceOne = services.serviceOne
    }
}

private struct SomeFactoryRouterGlobal: FactoryRouter {
    let container: SomeServiceFactory
}

private struct SomeFactoryRouterFullUnique: FactoryRouter {
    let container: Container
    struct Container {
        let serviceOne: ServiceOne
    }
}
