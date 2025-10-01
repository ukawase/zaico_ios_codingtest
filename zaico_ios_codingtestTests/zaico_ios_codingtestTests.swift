//
//  zaico_ios_codingtestTests.swift
//  zaico_ios_codingtestTests
//
//  Created by ryo hirota on 2025/03/11.
//

import Testing
@testable import zaico_ios_codingtest
import Foundation

@Suite(.serialized)
@MainActor
struct zaico_ios_codingtestTests {

    // URLProtocol to intercept URLSession.shared requests for testing
    final class TestURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

        override class func canInit(with request: URLRequest) -> Bool {
            // Intercept all requests
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let handler = TestURLProtocol.requestHandler else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() { }
    }

    // MARK: - Tests

    @Test
    func fetchInventories_success() async throws {
        URLProtocol.registerClass(TestURLProtocol.self)
        defer { URLProtocol.unregisterClass(TestURLProtocol.self) }

        TestURLProtocol.requestHandler = { request in
            // Expect a GET to /api/v1/inventories
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/api/v1/inventories")

            let json = """
            [
              { "id": 1, "title": "Item A", "quantity": "5", "item_image": { "url": "https://example.com/a.png" } },
              { "id": 2, "title": "Item B", "quantity": null, "item_image": { "url": null } }
            ]
            """.data(using: .utf8)!

            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let items = try await APIClient.shared.fetchInventories()
        #expect(items.count == 2)
        #expect(items[0].id == 1)
        #expect(items[0].title == "Item A")
        #expect(items[0].quantity == "5")
        #expect(items[0].itemImage?.url == "https://example.com/a.png")
        #expect(items[1].id == 2)
        #expect(items[1].quantity == nil)
        #expect(items[1].itemImage?.url == nil)
    }

    @Test
    func fetchInventories_serverError_throws() async {
        URLProtocol.registerClass(TestURLProtocol.self)
        defer { URLProtocol.unregisterClass(TestURLProtocol.self) }

        TestURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await APIClient.shared.fetchInventories()
            #expect(Bool(false), "Expected to throw on server error")
        } catch {
            let urlError = error as? URLError
            #expect(urlError != nil)
            #expect(urlError?.code == .badServerResponse)
        }
    }

    @Test
    func fetchInventorie_success() async throws {
        URLProtocol.registerClass(TestURLProtocol.self)
        defer { URLProtocol.unregisterClass(TestURLProtocol.self) }

        let expectedId = 123
        TestURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "GET")
            #expect(request.url?.path == "/api/v1/inventories/\(expectedId)")

            let json = """
            { "id": 123, "title": "Item X", "quantity": "10", "item_image": { "url": "https://example.com/x.png" } }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let item = try await APIClient.shared.fetchInventorie(id: expectedId)
        #expect(item.id == expectedId)
        #expect(item.title == "Item X")
        #expect(item.quantity == "10")
        #expect(item.itemImage?.url == "https://example.com/x.png")
    }

    @Test
    func createInventory_success() async throws {
        URLProtocol.registerClass(TestURLProtocol.self)
        defer { URLProtocol.unregisterClass(TestURLProtocol.self) }

        var callCount = 0
        TestURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount == 1 {
                // First call: POST /api/v1/inventories returns CreateInventoryResponse
                #expect(request.httpMethod == "POST")
                #expect(request.url?.path == "/api/v1/inventories")

                let createResponse = """
                { "code": 200, "status": "success", "message": "ok", "data_id": 999 }
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, createResponse)
            } else {
                // Second call: GET /api/v1/inventories/999 returns created inventory
                #expect(request.httpMethod == "GET")
                #expect(request.url?.path == "/api/v1/inventories/999")

                let inventoryJSON = """
                { "id": 999, "title": "New", "quantity": "0", "item_image": { "url": null } }
                """.data(using: .utf8)!
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, inventoryJSON)
            }
        }

        let created = try await APIClient.shared.createInventory(name: "New")
        #expect(created.id == 999)
        #expect(created.title == "New")
        #expect(created.quantity == "0")
        #expect(created.itemImage?.url == nil)
    }
}

