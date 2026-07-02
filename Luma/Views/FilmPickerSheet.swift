import SwiftUI

struct FilmPickerSheet: View {
    @Binding var film: FilmStock
    @Environment(\.dismiss) private var dismiss
    @State private var manualISO = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Pellicules courantes") {
                    ForEach(FilmStock.catalog) { stock in
                        Button {
                            film = stock; dismiss()
                        } label: {
                            HStack {
                                Text(stock.name).foregroundStyle(Theme.ink)
                                Spacer()
                                Text("ISO \(Int(stock.iso))").foregroundStyle(Theme.subtle)
                                if stock == film {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.fm2Red)
                                }
                            }
                        }
                    }
                }
                Section("ISO manuel") {
                    HStack {
                        TextField("ex. 250", text: $manualISO)
                            .keyboardType(.numberPad)
                        Button("Valider") {
                            if let iso = Double(manualISO), iso >= 12, iso <= 6400 {
                                film = .manual(iso: iso); dismiss()
                            }
                        }
                        .disabled(Double(manualISO).map { $0 < 12 || $0 > 6400 } ?? true)
                    }
                }
            }
            .navigationTitle("Pellicule chargée")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
