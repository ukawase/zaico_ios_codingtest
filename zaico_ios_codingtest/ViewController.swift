import SwiftUI
import UIKit

// SwiftUI list for inventories
struct InventoryListView: View {
    @State private var inventories: [Inventory] = []
    @State private var isShowNewInventoryInput = false
    @State private var newInventoryName = ""
    @State private var isCreatingInventory: Bool = false
    @FocusState private var isFocus: Bool

    var body: some View {
        contents
            .navigationTitle("在庫一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
              ToolbarItem(placement: .primaryAction) {
                if !isShowNewInventoryInput {
                    Button("在庫を追加", systemImage: "plus.app") {
                      withAnimation {
                        isShowNewInventoryInput = true
                      }
                    }
                } else {
                  Button("キャンセル", role: .destructive) {
                    withAnimation {
                      isShowNewInventoryInput = false
                    }
                  }
                }
              }
            })
            .onChange(of: isShowNewInventoryInput, { oldValue, newValue in
              if newValue {
                isFocus = true
              } else {
                isFocus = false
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
          if isShowNewInventoryInput {
            newInventoryCell
          }
        })
      }
    }
  
    private var newInventoryCell:  some View {
        HStack {
          TextField("追加する在庫名", text: $newInventoryName)
            .frame(maxWidth: .infinity)
            .focused($isFocus)
            .font(.body)
            .disabled(isCreatingInventory)
            .onSubmit {
              if newInventoryName.isEmpty {
                withAnimation {
                  isShowNewInventoryInput = false
                }
              } else {
                Task {
                  await createData()
                }
              }
            }
          Button( isCreatingInventory ? "追加中" : "追加") {
            Task {
              await createData()
            }
          }.disabled(newInventoryName.isEmpty || isCreatingInventory)
        }
        .padding(.vertical)
    }
  
    private func createData() async {
      isCreatingInventory = true
      do {
        let response = try await APIClient.shared.createInventory(name: newInventoryName)
      } catch {
        // TODO エラー処理
        print(error)
      }
      isCreatingInventory = false
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


