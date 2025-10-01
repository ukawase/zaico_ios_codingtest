import SwiftUI
import UIKit

// SwiftUI list for inventories
struct InventoryListView: View {
    @State private var inventories: [Inventory] = []
    @State private var newInventoryName: String? = nil
    @State private var isCreatingInventory: Bool = false
    @FocusState private var isFocus: Bool

    var body: some View {
        contents
            .navigationTitle("在庫一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
              ToolbarItem(placement: .primaryAction) {
                if newInventoryName == nil {
                    Button("在庫を追加", systemImage: "plus.app") {
                      withAnimation {
                        newInventoryName = ""
                      }
                    }
                } else {
                  Button("キャンセル", role: .destructive) {
                    withAnimation {
                      newInventoryName = nil
                    }
                  }
                }
              }
            })
            .onChange(of: newInventoryName, { oldValue, newValue in
              if newValue == nil {
                isFocus = false
              } else if oldValue == nil && newValue != nil {
                isFocus = true
              }
            })
            .task { await fetchData() }
    }
  
    private var contents: some View {
      List {
        Section(content: {
          ForEach(inventories, id: \.id) { item in
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
        }, header: {
          if newInventoryName != nil {
            newInventoryCell(
              name: Binding(
                get: { newInventoryName ?? "" },
                set: { newValue in
                  if !newValue.isEmpty {
                    newInventoryName = newValue
                  }
                }
              )
            )
          }
        })
      }
    }
  
    private func newInventoryCell(name: Binding<String>) -> some View {
        HStack {
          TextField("追加する在庫名", text: name)
            .frame(maxWidth: .infinity)
            .focused($isFocus)
            .onSubmit {
              if name.wrappedValue.isEmpty {
                withAnimation {
                  newInventoryName = nil
                }
              }
            }
          Button( isCreatingInventory ? "追加中" : "追加") {
            Task {
              await createData()
            }
          }.disabled(name.wrappedValue.isEmpty || isCreatingInventory)
        }
        .padding(.vertical)
    }
  
    private func createData() async {
      print("createData")
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


