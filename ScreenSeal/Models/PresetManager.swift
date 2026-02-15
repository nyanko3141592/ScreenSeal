import Foundation

struct WindowSnapshot: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let mosaicType: String
    let intensity: Double
}

struct LayoutPreset: Codable, Identifiable {
    let id: UUID
    var name: String
    var windows: [WindowSnapshot]

    init(name: String, windows: [WindowSnapshot]) {
        self.id = UUID()
        self.name = name
        self.windows = windows
    }
}

final class PresetManager: ObservableObject {
    @Published private(set) var presets: [LayoutPreset] = []

    private static let storageKey = "ScreenSeal.presets"

    init() {
        load()
    }

    func add(_ preset: LayoutPreset) {
        presets.append(preset)
        persist()
    }

    func delete(_ preset: LayoutPreset) {
        presets.removeAll { $0.id == preset.id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([LayoutPreset].self, from: data) else { return }
        presets = decoded
    }
}
