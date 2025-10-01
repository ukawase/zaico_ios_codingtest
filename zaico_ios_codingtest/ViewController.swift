import SwiftUI
import UIKit

// SwiftUI list for inventories
struct InventoryListView: View {
    @State private var inventories: [Inventory] = []

    var body: some View {
        contents
            .navigationTitle("在庫一覧")
            .navigationBarTitleDisplayMode(.inline)
            .task { await fetchData() }
    }
  
    private var contents: some View {
      List(inventories, id: \.id) { item in
          NavigationLink {
              InventoryDetailView(id: item.id)
                  .navigationTitle("詳細")
          } label: {
              HStack {
                  Text("\(item.id)")
                      .monospacedDigit()
                      .foregroundStyle(.secondary)
                  Spacer()
                  Text(item.title)
                      .foregroundStyle(.primary)
                      .lineLimit(2)
              }
              .padding(.vertical, 4)
          }
      }
    }

    private func fetchData() async {
        do {
            let data = try await APIClient.shared.fetchInventories()
            await MainActor.run {
                inventories = data
            }
        } catch {
            // Consider surfacing an alert/toast in a real app
            print("Error fetching data: \(error.localizedDescription)")
        }
    }
}

// Optional SwiftUI preview (ignored at runtime)
#if DEBUG
#Preview {
    InventoryListView()
}
#endif
