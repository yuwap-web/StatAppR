import Foundation

struct RecipeDescriptor: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let description: String
    let variables: [String: String]?
}

struct RecipesCatalogFile: Codable {
    let schema_version: String
    let recipes: [RecipeDescriptor]
}

enum RecipesCatalog {

    static func availableInBundle() -> [RecipeDescriptor] {
        print("========== recipes.json check ==========")

        // 1) recipes.json を探す（どこに入っていても見つかるように候補を広めに）
        let candidates: [(String, URL?)] = [
            ("recipes.json", Bundle.main.url(forResource: "recipes", withExtension: "json")),
            ("Engine/recipes/recipes.json", Bundle.main.url(forResource: "recipes", withExtension: "json", subdirectory: "Engine/recipes")),
            ("recipes.json (subdirectory recipes)", Bundle.main.url(forResource: "recipes", withExtension: "json", subdirectory: "recipes"))
        ]

        // 最初に見つかったものを採用
        let chosen = candidates.first(where: { $0.1 != nil })
        let url = chosen?.1

        print("recipes.json picked = \(chosen?.0 ?? "none")")
        print("recipes.json URL = \(url?.absoluteString ?? "nil")")

        guard let url else { return [] }

        do {
            let data = try Data(contentsOf: url)

            // 2) まず “辞書形式 {schema_version, recipes:[...] }” を試す
            if let obj = try? JSONDecoder().decode(RecipesCatalogFile.self, from: data) {
                let list = filterByBundledR(obj.recipes)
                print("recipes.json decoded as object. count=\(obj.recipes.count) -> available=\(list.count)")
                return list
            }

            // 3) 次に “配列形式 [ ... ]” を試す（昔の形式が残ってても落ちないように）
            if let arr = try? JSONDecoder().decode([RecipeDescriptor].self, from: data) {
                let list = filterByBundledR(arr)
                print("recipes.json decoded as array. count=\(arr.count) -> available=\(list.count)")
                return list
            }

            // 4) どちらでもダメならエラーを出して空
            do {
                _ = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                print("========== recipes.json load error ==========")
                print(error)
            }
            print("decode failed: expected object or array. (Check comments/trailing commas.)")
            return []

        } catch {
            print("========== recipes.json load error ==========")
            print(error)
            return []
        }
    }

    /// recipes.json に列挙されているが、同梱Rが無いものはメニューから除外
    private static func filterByBundledR(_ list: [RecipeDescriptor]) -> [RecipeDescriptor] {
        let filtered = list.filter { hasBundledRecipeR(id: $0.id) }
        if filtered.count != list.count {
            let missing = Set(list.map{$0.id}).subtracting(filtered.map{$0.id})
            print("Missing bundled R for: \(missing.sorted())")
        }
        return filtered
    }

    private static func hasBundledRecipeR(id: String) -> Bool {
        // ここはあなたの現在のBundle構成に合わせて候補を複数見る
        // 例: Engine/recipes/<id>.R が入っている想定
        let hit =
            Bundle.main.url(forResource: id, withExtension: "R", subdirectory: "Engine/recipes") != nil ||
            Bundle.main.url(forResource: id, withExtension: "R", subdirectory: "recipes") != nil ||
            Bundle.main.url(forResource: id, withExtension: "R") != nil

        return hit
    }
}
