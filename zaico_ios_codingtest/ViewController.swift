import SwiftUI
import UIKit

struct MainNavigationView: View {
  
  var body: some View {
    NavigationStack {
      InventoryListView()
    }
  }
}

// SwiftUI list for inventories
struct InventoryListView: View {
    @State private var inventories: [Inventory] = []

    var body: some View {
        List(inventories, id: \.id) { item in
            NavigationLink {
                DetailViewRepresentable(id: item.id)
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
        .navigationTitle("在庫一覧")
        .navigationBarTitleDisplayMode(.inline)
        .task { await fetchData() }
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

// Wrap existing UIKit DetailViewController so we can push it from SwiftUI
struct DetailViewRepresentable: UIViewControllerRepresentable {
    let id: Int

    func makeUIViewController(context: Context) -> UIViewController {
        DetailViewController(id: id)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No-op: detail view is configured via initializer
    }
}

// Optional SwiftUI preview (ignored at runtime)
#if DEBUG
#Preview {
    InventoryListView()
}
#endif
