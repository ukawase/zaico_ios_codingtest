//
//  APIClient.swift
//  zaico_ios_codingtest
//
//  Created by ryo hirota on 2025/03/11.
//

import Foundation

struct CreateInventoryResponse: Codable {
    let code: Int
    let status: String
    let message: String
    let dataId: Int

    enum CodingKeys: String, CodingKey {
        case code, status, message
        case dataId = "data_id"
    }
}

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "https://web.zaico.co.jp"
    private let token = "etWXaPuKbWapRvUjE7281szrYH3k2Mkq" // 実際のトークンに置き換える
    
    private init() {}

    func fetchInventories() async throws -> [Inventory] {
        let endpoint = "/api/v1/inventories"
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if !(200...299).contains(httpResponse.statusCode) {
                    throw URLError(.badServerResponse)
                }
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("[APIClient] API Response: \(jsonString)")
            }
            
            return try JSONDecoder().decode([Inventory].self, from: data)
        } catch {
            throw error
        }
    }
    
    func fetchInventorie(id: Int?) async throws -> Inventory {
        var endpoint = "/api/v1/inventories"
        
        if let id = id {
            endpoint += "/\(id)"
        }
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if !(200...299).contains(httpResponse.statusCode) {
                    throw URLError(.badServerResponse)
                }
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("[APIClient] API Response: \(jsonString)")
            }
            
            return try JSONDecoder().decode(Inventory.self, from: data)
        } catch {
            throw error
        }
    }
  
  func createInventory(name: String) async throws -> Inventory {
    let endpoint = "/api/v1/inventories"
    
    guard let url = URL(string: baseURL + endpoint) else {
        throw URLError(.badURL)
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let body: [String: String] = ["title": name]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                throw URLError(.badServerResponse)
            }
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("[APIClient] API Response: \(jsonString)")
        }
      
        let createInventoryResponse = try JSONDecoder().decode(CreateInventoryResponse.self, from: data)
        let inventory = try await fetchInventorie(id: createInventoryResponse.dataId)
        
        return inventory
    } catch {
        throw error
    }
  }
}

