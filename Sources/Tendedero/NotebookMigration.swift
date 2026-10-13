import Foundation

/// Bring the notebook from the earlier personal build into the separately
/// identified fork. Do not import screenshot capture settings or file paths.
enum NotebookMigration {
    static func run(defaults: UserDefaults = .standard,
                    legacy: UserDefaults? = UserDefaults(suiteName: "app.tendedero.Tendedero")) {
        let marker = "importedLegacyNotebook.v1"
        guard !defaults.bool(forKey: marker) else { return }
        let key = "todoNotebook.v1"
        if defaults.object(forKey: key) == nil, let data = legacy?.data(forKey: key) {
            defaults.set(data, forKey: key)
        }
        defaults.set(true, forKey: marker)
    }
}
