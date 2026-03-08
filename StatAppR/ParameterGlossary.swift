import Foundation

/// ParameterGlossary
/// Provides user-friendly explanations for statistical parameter terminology.
/// Helps users understand what each parameter means and identify corresponding data columns.
///
/// Usage:
/// ```swift
/// let explanation = ParameterGlossary.getExplanation(for: "treatment")
/// Text(explanation).font(.caption)
/// ```

struct ParameterGlossary {

    /// Dictionary mapping parameter keys to user-friendly explanations
    private static let glossary: [String: String] = [
        // ===== Outcome/Target Variables =====
        "outcome_column": "分析で説明・予測したい結果。例：disease_status（病気の有無）、outcome（結果）",
        "outcome": "分析で説明・予測したい結果。例：disease_status（病気の有無）、outcome（結果）",
        "y": "統計モデルの従属変数・目的変数。予測対象となる数値。",
        "result": "分析の結果を示す変数。実験やテストの結果を格納した列。",
        "event": "追跡調査で発生した重要な出来事。通常0/1で表現される。",

        // ===== Group/Treatment Variables =====
        "group_column": "分析対象の「グループ」を示す列。比較するグループを区別する変数。例：control（対照群）、treatment（処置群）",
        "group": "データを分けるグループ。比較対象となる群を示す。例：control、treatment、group_A",
        "treatment": "実験・施策を受けたか否かを示す変数。介入の有無（0/1など）。",
        "arm": "臨床試験の「群」。異なる治療法を受けるグループ。",
        "condition": "実験条件。異なる処置や環境条件を示す列。",
        "treatment_group": "治療を受けたグループを示す列。通常、対照群と比較される。",

        // ===== Confounders/Covariates =====
        "covariates": "分析結果に影響を与える可能性のある背景要因。年齢、性別などの調整変数。",
        "covariate": "分析結果に影響する背景要因。調整が必要な変数。例：age（年齢）、gender（性別）",
        "x": "統計モデルの独立変数。説明変数として使用される列。",
        "confounders": "結果に影響を与える交絡要因。統計分析で調整する必要のある変数。",
        "control_vars": "コントロール変数。分析で調整する背景要因。例：年齢、性別",

        // ===== Exposure Variables =====
        "exposure_column": "対象者の曝露状況。環境要因や有害物質への暴露を示す列。",
        "exposure": "対象者が特定の要因にどの程度さらされたか。例：喫煙量、放射線被爆量",
        "exposed": "曝露の有無。0/1で表現されることが多い。",

        // ===== ID/Identifier Variables =====
        "id": "個人や対象を識別するID。患者ID、学生ID など。",
        "patient_id": "患者を一意に識別するID。追跡調査で同じ人物を判別するのに使用。",
        "subject_id": "研究対象者のID。複数の観測値が同じ個人に属することを示す。",
        "individual_id": "個人を識別するID。階層的データで個人を特定するのに使用。",
        "unit_id": "分析単位を識別するID。国、州、企業などの識別子。",

        // ===== Time Variables =====
        "time_column": "追跡時間。疾患発症や治療開始から経過した時間。例：time_months（月数）、days（日数）",
        "time": "経過時間。観測開始からの期間。例：treatment開始後の日数、月数。",
        "start": "観測・治療開始の時点。初期状態を記録する列。",
        "start_time": "イベント開始の時刻。時系列データの開始点。",
        "stop_time": "観測終了の時刻。追跡終了時点。",
        "followup": "フォローアップ期間。初期受診から次の検査までの期間。",
        "duration": "継続期間。イベント開始から終了までの時間。",

        // ===== Event/Status Variables =====
        "event_column": "イベント発生の有無。0/1で表現される。例：event_occurred（イベント発生有無）",
        "status": "現在の状態。イベント発生（1）or検査打ち切り（0）。",
        "event_occurred": "イベントが発生したかどうか。通常0/1。",
        "censor": "検査打ち切りを示すフラグ。追跡中にイベント発生なしで観測終了。",

        // ===== Meta-Analysis Variables =====
        "effect": "各研究から抽出した効果量の推定値。例：Cohen's d、オッズ比",
        "effect_size": "実験結果の効果の大きさ。統計的な影響度を数値化。",
        "estimate": "パラメータの推定値。回帰係数、平均差など。",
        "coefficient": "回帰モデルの係数。変数が目的変数に与える影響の大きさ。",
        "se": "標準誤差。効果量の不確実性を表す値。小さいほど正確な推定。",
        "standard_error": "推定値のばらつきを示す標準誤差。信頼区間の計算に使用。",
        "stderr": "標準エラー。推定値の精度を示す指標。",

        // ===== Study/Label Variables =====
        "label": "研究の識別ラベル。著者名、年号、研究名など。",
        "author": "研究の著者。メタアナリシスで研究を識別するのに使用。",
        "study": "研究の名称。複数研究を区別する識別子。",
        "study_name": "研究プロジェクトの名前。",

        // ===== Instrumental Variables =====
        "instrument": "操作変数。処置内生性の問題を解決するのに使用。例：距離、地理的要因",
        "instrument_var": "操作変数としての役割を果たす外生変数。",
        "z": "操作変数を示す一般的な記号。処置に影響するが結果には直接影響しない。",
        "iv": "Instrumental Variable（操作変数）。因果推論の手法で使用。",

        // ===== Weight Variables =====
        "weight_column": "分析に使用する重み。各観測値の相対的重要性を示す。",
        "weight": "観測値の重み。不均等な標本抽出やメタアナリシスで使用。",
        "weights": "複数の観測値に対する重みのベクトル。",
        "sample_weight": "標本抽出デザインに基づく調査重み。",

        // ===== Subgroup Variables =====
        "subgroup_column": "層別分析用の分類変数。年代、性別、地域など。",
        "subgroup": "サブグループ。層別分析で効果が異なるかを検証。",
        "stratum": "層別分析の層。例：年代別、地域別",
        "category": "カテゴリ変数。グループ分けの基準となる列。",
    ]

    /// Get explanation for a parameter key
    /// - Parameter key: The parameter key (e.g., "treatment", "outcome_column")
    /// - Returns: User-friendly explanation or nil if not found
    static func getExplanation(for key: String) -> String? {
        return glossary[key]
    }

    /// Get explanation with fallback text
    /// - Parameter key: The parameter key
    /// - Returns: Explanation or default message if not found
    static func getExplanationOrDefault(for key: String) -> String {
        return glossary[key] ?? "このパラメータについて追加情報が利用できません。"
    }

    /// Get all glossary terms
    /// - Returns: Dictionary of all glossary entries
    static func getAllTerms() -> [String: String] {
        return glossary
    }

    /// Search glossary by keyword
    /// - Parameter keyword: Search term
    /// - Returns: Array of matching keys and explanations
    static func search(keyword: String) -> [(key: String, explanation: String)] {
        let lowercaseKeyword = keyword.lowercased()
        return glossary
            .filter { key, explanation in
                key.lowercased().contains(lowercaseKeyword) ||
                explanation.lowercased().contains(lowercaseKeyword)
            }
            .map { key, explanation in
                (key: key, explanation: explanation)
            }
            .sorted { $0.key < $1.key }
    }
}
