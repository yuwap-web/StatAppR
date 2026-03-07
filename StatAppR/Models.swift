import Foundation
import Combine

// MARK: - App Settings (User Preferences)

class AppSettings: ObservableObject {
    @Published var resultsFolder: String = "/tmp/StatAppR_results"
    @Published var generatePDF: Bool = true
    @Published var autoOpenResults: Bool = false

    private let userDefaults = UserDefaults.standard
    private let resultsKey = "StatAppR_ResultsFolder"
    private let pdfKey = "StatAppR_GeneratePDF"
    private let autoOpenKey = "StatAppR_AutoOpen"

    init() {
        // Load saved preferences
        if let saved = userDefaults.string(forKey: resultsKey) {
            resultsFolder = saved
        }
        generatePDF = userDefaults.bool(forKey: pdfKey) || !userDefaults.bool(forKey: pdfKey)
        autoOpenResults = userDefaults.bool(forKey: autoOpenKey)
    }

    func updateResultsFolder(_ path: String) {
        resultsFolder = path
        userDefaults.set(path, forKey: resultsKey)
    }

    func setGeneratePDF(_ value: Bool) {
        generatePDF = value
        userDefaults.set(value, forKey: pdfKey)
    }

    func setAutoOpenResults(_ value: Bool) {
        autoOpenResults = value
        userDefaults.set(value, forKey: autoOpenKey)
    }

    func ensureResultsFolderExists() {
        if !FileManager.default.fileExists(atPath: resultsFolder) {
            try? FileManager.default.createDirectory(atPath: resultsFolder, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Data Type Enumeration (7 Categories)

enum DataType: String, CaseIterable, Identifiable {
    case basicStats = "基本統計"
    case groupComparison = "グループ比較"
    case regression = "回帰分析"
    case timeSeries = "時系列・パネルデータ"
    case survival = "生存分析"
    case causalInference = "因果推論"
    case dimensionReduction = "次元削減"
    case metaAnalysis = "メタアナリシス"

    var id: String { self.rawValue }

    var description: String {
        switch self {
        case .basicStats:
            return "平均値、標準偏差、相関などの記述統計量を計算します。基本的な統計分析に最適。"
        case .groupComparison:
            return "2つ以上のグループの比較。t検定、ANOVA、Mann-Whitney U検定など。"
        case .regression:
            return "連続変数の予測。線形回帰、重回帰、多項式回帰を実行できます。"
        case .timeSeries:
            return "時系列データやパネルデータの分析。トレンド分析や差分の差推定。"
        case .survival:
            return "イベント発生時間の分析。Kaplan-Meier曲線やCoxモデル。"
        case .causalInference:
            return "因果効果の推定。マッチング、傾向スコア、機械学習ベースの手法。"
        case .dimensionReduction:
            return "多数の変数を少数に圧縮。主成分分析、因子分析、部分最小二乗法。"
        case .metaAnalysis:
            return "複数の研究結果を統合。メタアナリシスによる効果の推定。"
        }
    }

    var detailedDescription: String {
        switch self {
        case .basicStats:
            return """
            【用途】記述統計量の計算、平均値・標準偏差・中央値などの算出

            【使用例】患者データ分析
            - 患者ID、年齢、体重、身長、血圧、コレステロール値
            - → 各項目の平均/標準偏差、BMI計算、相関分析

            【必須要件】
            ✅ 数値列のみ（または数値に変換可能）
            ✅ 行数: 最小10以上推奨
            ✅ 列数: 2列以上
            """
        case .groupComparison:
            return """
            【用途】2群以上の比較（t検定、Mann-Whitney U検定、ANOVA）

            【使用例】治療効果比較
            - 治療群 vs 対照群
            - 治療前後のスコア比較
            - グループ間の改善度の比較

            【必須要件】
            ✅ グループ識別列（treatment/control など）
            ✅ 各グループ: 最小6サンプル推奨
            ✅ 比較対象となる数値列
            """
        case .regression:
            return """
            【用途】連続アウトカムを複数の予測変数で説明

            【使用例】不動産価格予測
            - 価格 = 面積 + 寝室数 + バスルーム数 + 築年数
            - 各要素の影響度を定量化

            【必須要件】
            ✅ 結果変数（outcome）: 1列
            ✅ 予測変数: 2列以上推奨
            ✅ 行数: 最小12行以上
            ✅ 全て数値データ
            """
        case .timeSeries:
            return """
            【用途】時系列追跡、パネルデータ分析

            【使用例】四半期売上分析
            - 複数企業の時間経過による売上推移
            - マーケティング支出との相関
            - 地域別のトレンド比較

            【必須要件】
            ✅ ID列（company_id、企業識別など）
            ✅ 時間列（quarter, year など）
            ✅ 行数: ID × 時間ポイント（例：3企業 × 6四半期=18行）
            """
        case .survival:
            return """
            【用途】イベント発生時間の分析

            【使用例】患者フォローアップ研究
            - フォローアップ期間（月数）
            - イベント発生有無（治癒/再発など）
            - 治療群別の生存曲線比較
            - COVID感染者の回復時間分析

            【必須要件】
            ✅ 患者ID
            ✅ フォローアップ時間（月、年など）
            ✅ イベント発生の有無（0/1）
            ✅ グループ分類（治療群など）
            """
        case .causalInference:
            return """
            【用途】政策効果、介入効果の推定

            【使用例】教育政策の効果測定
            - 処置: プログラム参加有無
            - アウトカム: 年収
            - 共変量: 年齢、教育年数、前年度年収
            - → プログラムの因果効果を推定

            【必須要件】
            ✅ 処置変数（0/1, yes/no）
            ✅ アウトカム変数: 数値型
            ✅ 共変量: 複数
            ✅ 行数: 最小20行以上推奨
            """
        case .dimensionReduction:
            return """
            【用途】多数の特徴量を少数に圧縮、パターン認識

            【使用例】遺伝子発現データ解析
            - 数千の遺伝子発現量データ
            - → 主成分分析で数個の主成分に圧縮
            - 疾患状態の判別や新規バイオマーカー発見

            【必須要件】
            ✅ 特徴量列: 最小5列以上（多いほど効果的）
            ✅ 全て数値データ
            ✅ 行数: 特徴数より多い（例：10特徴なら最小15サンプル）
            """
        case .metaAnalysis:
            return """
            【用途】複数の研究結果を統合・合成

            【使用例】治療効果のメタアナリシス
            - 複数の臨床試験の効果サイズ
            - 各試験のサンプルサイズ
            - → 統合効果量の推定と異質性検定

            【必須要件】
            ✅ 研究ID列（study_id など）
            ✅ 効果サイズまたは要約統計量
            ✅ 標準誤差または信頼区間
            ✅ 行数: 最小3研究以上推奨
            """
        }
    }

    var emoji: String {
        switch self {
        case .basicStats: return "📊"
        case .groupComparison: return "⚖️"
        case .regression: return "📈"
        case .timeSeries: return "📉"
        case .survival: return "⏱️"
        case .causalInference: return "🎯"
        case .dimensionReduction: return "🎨"
        case .metaAnalysis: return "📚"
        }
    }

    var sampleFilename: String {
        switch self {
        case .basicStats: return "1_BasicStats_patient_demographics.csv"
        case .groupComparison: return "2_GroupComparison_treatment_vs_control.csv"
        case .regression: return "3_Regression_house_price_prediction.csv"
        case .timeSeries: return "4_TimeSeries_quarterly_sales.csv"
        case .survival: return "5_Survival_patient_followup.csv"
        case .causalInference: return "6_CausalInference_policy_evaluation.csv"
        case .dimensionReduction: return "7_DimensionReduction_gene_expression.csv"
        case .metaAnalysis: return "8_MetaAnalysis_study_results.csv"
        }
    }

    var recommendedRecipes: [RecipeInfo] {
        switch self {
        case .basicStats:
            return [
            ]

        case .groupComparison:
            return [
                RecipeInfo(
                    name: "T-Test (Independent)",
                    nameJapanese: "t検定（独立標本）",
                    description: "2つの独立したグループを比較",
                    recipeName: "two_group_continuous",
                    requiredColumns: ["グループ列", "数値アウトカム列"],
                    example: "group (treatment/control), outcome_score",
                    parameters: [
                        ParameterRequirement(
                            name: "グループ列",
                            parameterKey: "group_column",
                            type: .singleColumn,
                            description: "比較するグループを示す列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム列",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "比較対象となる数値列",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "ANOVA",
                    nameJapanese: "分散分析",
                    description: "3つ以上のグループを比較",
                    recipeName: "anova_continuous",
                    requiredColumns: ["グループ列", "数値アウトカム列"],
                    example: "treatment_type, response_score",
                    parameters: [
                        ParameterRequirement(
                            name: "グループ列",
                            parameterKey: "group_column",
                            type: .singleColumn,
                            description: "比較するグループ（3つ以上）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム列",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "比較対象となる数値列",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Mann-Whitney U Test",
                    nameJapanese: "マン・ホイットニーU検定",
                    description: "ノンパラメトリック検定",
                    recipeName: "two_group_categorical",
                    requiredColumns: ["グループ列", "数値アウトカム列"],
                    example: "group, measurement",
                    parameters: [
                        ParameterRequirement(
                            name: "グループ列",
                            parameterKey: "group_column",
                            type: .singleColumn,
                            description: "比較するグループ",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "計測列",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "比較対象となる列",
                            required: true
                        )
                    ]
                )
            ]

        case .regression:
            return [
                RecipeInfo(
                    name: "Linear Regression",
                    nameJapanese: "線形回帰",
                    description: "1つの予測変数による線形回帰",
                    recipeName: "linear_regression",
                    requiredColumns: ["結果変数", "予測変数"],
                    example: "price, size_sqft",
                    parameters: [
                        ParameterRequirement(
                            name: "結果変数",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "予測対象となる数値列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "予測変数",
                            parameterKey: "predictor_column",
                            type: .singleColumn,
                            description: "予測に使用する数値列",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Multiple Regression",
                    nameJapanese: "重回帰",
                    description: "複数の予測変数を使用",
                    recipeName: "multiple_regression",
                    requiredColumns: ["結果変数", "予測変数（複数）"],
                    example: "price, size, bedrooms, bathrooms, age",
                    parameters: [
                        ParameterRequirement(
                            name: "結果変数",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "予測対象となる数値列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "予測変数",
                            parameterKey: "predictor_columns",
                            type: .multipleColumns,
                            description: "予測に使用する数値列（複数選択）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "VIF計算",
                            parameterKey: "compute_vif",
                            type: .categorical,
                            description: "分散拡大係数の計算（TRUE/FALSE）",
                            required: false
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Logistic Regression",
                    nameJapanese: "ロジスティック回帰",
                    description: "二項アウトカムの予測",
                    recipeName: "logistic_regression",
                    requiredColumns: ["0/1アウトカム", "予測変数"],
                    example: "disease_status (0/1), age, bmi, smoking",
                    parameters: [
                        ParameterRequirement(
                            name: "アウトカム列",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "0/1の二項アウトカム列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "予測変数",
                            parameterKey: "predictor_columns",
                            type: .multipleColumns,
                            description: "予測に使用する列",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Bayesian Regression",
                    nameJapanese: "ベイズ回帰",
                    description: "ベイズ推定による回帰分析",
                    recipeName: "bayesian_regression",
                    requiredColumns: ["結果変数", "予測変数"],
                    example: "outcome, x1, x2, x3",
                    parameters: [
                        ParameterRequirement(
                            name: "結果変数",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "予測対象となる数値列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "予測変数",
                            parameterKey: "predictor_columns",
                            type: .multipleColumns,
                            description: "予測に使用する数値列（複数選択）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "プライア",
                            parameterKey: "prior_type",
                            type: .categorical,
                            description: "プライア分布の指定（weak/informative）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "MCMC抽出数",
                            parameterKey: "n_draw",
                            type: .numeric,
                            description: "MCMC抽出サンプル数",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "シード",
                            parameterKey: "seed",
                            type: .numeric,
                            description: "乱数シード値",
                            required: false
                        )
                    ]
                )
            ]

        case .timeSeries:
            return [
                RecipeInfo(
                    name: "Difference-in-Differences",
                    nameJapanese: "差分の差（DiD）",
                    description: "政策評価用の準実験デザイン",
                    recipeName: "difference_in_differences",
                    requiredColumns: ["グループ", "時間", "アウトカム"],
                    example: "treat (0/1), time (pre/post), outcome",
                    parameters: [
                        ParameterRequirement(
                            name: "処置グループ列",
                            parameterKey: "treatment_column",
                            type: .singleColumn,
                            description: "処置の有無（0/1）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "時間列",
                            parameterKey: "time_column",
                            type: .singleColumn,
                            description: "前後を示す列（pre/post）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム列",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる数値列",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Event Study",
                    nameJapanese: "イベントスタディ",
                    description: "イベント前後の経時変化分析",
                    recipeName: "event_study",
                    requiredColumns: ["ユニットID", "時間", "イベント時期", "アウトカム"],
                    example: "firm_id, quarter, event_date, stock_return",
                    parameters: [
                        ParameterRequirement(
                            name: "ユニットID",
                            parameterKey: "unit_id",
                            type: .singleColumn,
                            description: "企業・観察単位の識別列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "時間列",
                            parameterKey: "time_column",
                            type: .singleColumn,
                            description: "時間を示す列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "イベント日付列",
                            parameterKey: "event_date_column",
                            type: .singleColumn,
                            description: "イベント発生日付",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる列",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Synthetic Control",
                    nameJapanese: "合成コントロール法",
                    description: "政策効果の準実験評価法",
                    recipeName: "synthetic_control",
                    requiredColumns: ["ユニットID", "時間", "処置ユニット", "アウトカム"],
                    example: "state, year, treated_state, outcome",
                    parameters: [
                        ParameterRequirement(
                            name: "ユニットID",
                            parameterKey: "unit_id",
                            type: .singleColumn,
                            description: "地域・ユニットの識別列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "時間列",
                            parameterKey: "time_column",
                            type: .singleColumn,
                            description: "時間を示す列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "処置ユニット",
                            parameterKey: "treated_unit",
                            type: .singleColumn,
                            description: "処置を受けたユニット（通常は1つ）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "処置開始時点",
                            parameterKey: "treat_time",
                            type: .singleColumn,
                            description: "処置が開始された時点（例：2020）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "共変量（オプション）",
                            parameterKey: "covariates",
                            type: .multipleColumns,
                            description: "予測に使用する共変量（オプション）",
                            required: false
                        )
                    ]
                )
            ]

        case .survival:
            return [
                RecipeInfo(
                    name: "Kaplan-Meier Analysis",
                    nameJapanese: "カプラン・マイヤー分析",
                    description: "生存曲線の推定と群比較",
                    recipeName: "survival_km",
                    requiredColumns: ["時間列", "イベント列（0/1）", "グループ列"],
                    example: "time_months, event_occurred (0/1), treatment_group",
                    parameters: [
                        ParameterRequirement(
                            name: "時間列",
                            parameterKey: "time_column",
                            type: .singleColumn,
                            description: "フォローアップ期間（月、年など）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "イベント列",
                            parameterKey: "event_column",
                            type: .singleColumn,
                            description: "イベント発生有無（0/1）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "グループ列",
                            parameterKey: "group_column",
                            type: .singleColumn,
                            description: "治療群など比較するグループ",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "信頼区間",
                            parameterKey: "conf_int",
                            type: .numeric,
                            description: "信頼水準（0.95等）",
                            required: false
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Cox Proportional Hazards",
                    nameJapanese: "Cox比例ハザードモデル",
                    description: "共変量を調整したハザード比推定",
                    recipeName: "cox_regression",
                    requiredColumns: ["時間列", "イベント列", "共変量"],
                    example: "follow_up_time, status, age, stage, comorbidity",
                    parameters: [
                        ParameterRequirement(
                            name: "時間列",
                            parameterKey: "time_column",
                            type: .singleColumn,
                            description: "フォローアップ期間",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "イベント列",
                            parameterKey: "event_column",
                            type: .singleColumn,
                            description: "イベント発生有無（0/1）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "処置変数",
                            parameterKey: "treatment_column",
                            type: .singleColumn,
                            description: "主な処置・治療変数",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "共変量",
                            parameterKey: "covariates",
                            type: .multipleColumns,
                            description: "調整変数（複数選択可）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "比例ハザード性検定",
                            parameterKey: "check_ph",
                            type: .categorical,
                            description: "PH仮定の検定（TRUE/FALSE）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "堅牢標準誤差",
                            parameterKey: "robust_se",
                            type: .categorical,
                            description: "堅牢分散の使用（TRUE/FALSE）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "同着時の方法",
                            parameterKey: "ties",
                            type: .categorical,
                            description: "efron/breslow/exact",
                            required: false
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Case-Crossover Analysis",
                    nameJapanese: "ケース交差デザイン",
                    description: "ケース交差設計による急性効果の推定",
                    recipeName: "case_crossover",
                    requiredColumns: ["ケースID", "時間", "暴露", "結果"],
                    example: "case_id, date, exposure, outcome",
                    parameters: [
                        ParameterRequirement(
                            name: "ケースID",
                            parameterKey: "case_id",
                            type: .singleColumn,
                            description: "ケースの識別列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "時間列",
                            parameterKey: "time_column",
                            type: .singleColumn,
                            description: "時間を示す列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "暴露変数",
                            parameterKey: "exposure_column",
                            type: .singleColumn,
                            description: "暴露・処置変数",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Conditional Logistic Regression",
                    nameJapanese: "条件付きロジスティック回帰",
                    description: "マッチングケースコントロールの分析",
                    recipeName: "conditional_logistic_regression",
                    requiredColumns: ["マッチセット", "ケース/コントロール", "暴露"],
                    example: "matched_set, case_control (0/1), exposure",
                    parameters: [
                        ParameterRequirement(
                            name: "マッチセット列",
                            parameterKey: "matchset_column",
                            type: .singleColumn,
                            description: "マッチングのセット識別",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "ケース/コントロール列",
                            parameterKey: "case_control_column",
                            type: .singleColumn,
                            description: "ケース(1)/コントロール(0)",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "暴露変数",
                            parameterKey: "exposure_columns",
                            type: .multipleColumns,
                            description: "暴露・処置変数（複数選択可）",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Target Trial Emulation",
                    nameJapanese: "ターゲットトライアルエミュレーション",
                    description: "観察データから準実験設計をシミュレート",
                    recipeName: "target_trial_emulation",
                    requiredColumns: ["患者ID", "時間", "処置", "アウトカム"],
                    example: "patient_id, date, treatment, outcome",
                    parameters: [
                        ParameterRequirement(
                            name: "患者ID",
                            parameterKey: "patient_id",
                            type: .singleColumn,
                            description: "患者の識別列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "時間列",
                            parameterKey: "time_column",
                            type: .singleColumn,
                            description: "時間を示す列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "処置変数",
                            parameterKey: "treatment_column",
                            type: .singleColumn,
                            description: "処置の有無",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる列",
                            required: true
                        )
                    ]
                )
            ]

        case .causalInference:
            return [
                RecipeInfo(
                    name: "Propensity Score Matching",
                    nameJapanese: "傾向スコアマッチング",
                    description: "傾向スコアマッチングによる効果推定",
                    recipeName: "ps_matching",
                    requiredColumns: ["処置変数（0/1）", "アウトカム", "共変量"],
                    example: "treatment, outcome, age, education, prior_score",
                    parameters: [
                        ParameterRequirement(
                            name: "処置変数",
                            parameterKey: "treatment_column",
                            type: .singleColumn,
                            description: "処置の有無（0/1）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "共変量",
                            parameterKey: "covariates",
                            type: .multipleColumns,
                            description: "調整変数（複数選択）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "バランス閾値",
                            parameterKey: "balance_threshold",
                            type: .numeric,
                            description: "標準化平均差の閾値",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "キャリパー",
                            parameterKey: "caliper",
                            type: .numeric,
                            description: "マッチング距離の最大値",
                            required: false
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Double Machine Learning",
                    nameJapanese: "ダブル機械学習",
                    description: "機械学習を使用した効果推定",
                    recipeName: "double_ml_ate",
                    requiredColumns: ["処置変数", "アウトカム", "共変量"],
                    example: "treatment (0/1), earnings, age, education",
                    parameters: [
                        ParameterRequirement(
                            name: "処置変数",
                            parameterKey: "treatment_column",
                            type: .singleColumn,
                            description: "処置の有無",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "共変量",
                            parameterKey: "covariates",
                            type: .multipleColumns,
                            description: "機械学習の特徴量（複数選択）",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Causal Forest",
                    nameJapanese: "因果フォレスト",
                    description: "異質な処置効果の推定",
                    recipeName: "causal_forest",
                    requiredColumns: ["処置", "アウトカム", "特徴量"],
                    example: "treatment, outcome, x1, x2, x3",
                    parameters: [
                        ParameterRequirement(
                            name: "処置変数",
                            parameterKey: "treatment_column",
                            type: .singleColumn,
                            description: "処置の有無",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "特徴量",
                            parameterKey: "predictor_columns",
                            type: .multipleColumns,
                            description: "分析に使用する特徴量（複数選択）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "ツリー数",
                            parameterKey: "n_trees",
                            type: .numeric,
                            description: "Random Forest のツリー数",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "プロット",
                            parameterKey: "plot",
                            type: .categorical,
                            description: "プロット表示（TRUE/FALSE）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "シード",
                            parameterKey: "seed",
                            type: .numeric,
                            description: "乱数シード値",
                            required: false
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Instrumental Variable",
                    nameJapanese: "操作変数法",
                    description: "操作変数法による逆方向因果制御",
                    recipeName: "iv_2sls",
                    requiredColumns: ["結果", "処置", "操作変数"],
                    example: "earnings, education, distance_to_college",
                    parameters: [
                        ParameterRequirement(
                            name: "結果変数",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "最終的な結果",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "処置変数",
                            parameterKey: "treatment_column",
                            type: .singleColumn,
                            description: "処置またはエンドジェナス変数",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "操作変数",
                            parameterKey: "instrument",
                            type: .singleColumn,
                            description: "処置と相関し結果には直接影響しない変数",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "共変量（オプション）",
                            parameterKey: "covariates",
                            type: .multipleColumns,
                            description: "統制する共変量（複数選択可）",
                            required: false
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Placebo Test",
                    nameJapanese: "プラセボテスト",
                    description: "因果推論の仮定検証用プラセボテスト",
                    recipeName: "placebo_test",
                    requiredColumns: ["処置", "アウトカム", "共変量"],
                    example: "treatment, outcome, covar1, covar2",
                    parameters: [
                        ParameterRequirement(
                            name: "処置変数",
                            parameterKey: "treatment_column",
                            type: .singleColumn,
                            description: "処置の有無（0/1）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "プラセボアウトカム",
                            parameterKey: "placebo_outcome_column",
                            type: .singleColumn,
                            description: "処置に影響されないはずのアウトカム",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "AIPW (Augmented IPW)",
                    nameJapanese: "増強逆確率重み付け",
                    description: "二重堅牢性を持つ効果推定",
                    recipeName: "aipw_ate",
                    requiredColumns: ["処置", "アウトカム", "共変量"],
                    example: "treatment, outcome, age, education",
                    parameters: [
                        ParameterRequirement(
                            name: "処置変数",
                            parameterKey: "treatment_column",
                            type: .singleColumn,
                            description: "処置の有無（0/1）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "共変量",
                            parameterKey: "covariates",
                            type: .multipleColumns,
                            description: "調整変数（複数選択）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "傾向スコアモデル",
                            parameterKey: "ps_model",
                            type: .categorical,
                            description: "logit/probit モデル",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "安定化重み",
                            parameterKey: "stabilized",
                            type: .categorical,
                            description: "重みの安定化（TRUE/FALSE）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "トリミング",
                            parameterKey: "trim",
                            type: .numeric,
                            description: "傾向スコアトリミング（0-0.5）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "バランス閾値",
                            parameterKey: "balance_threshold",
                            type: .numeric,
                            description: "標準化平均差の閾値",
                            required: false
                        )
                    ]
                ),
                RecipeInfo(
                    name: "IPTW (Inverse Probability Treatment Weighting)",
                    nameJapanese: "逆確率重み付け",
                    description: "逆確率重み付けによる効果推定",
                    recipeName: "iptw_ate",
                    requiredColumns: ["処置", "アウトカム", "共変量"],
                    example: "treatment, outcome, age, baseline_score",
                    parameters: [
                        ParameterRequirement(
                            name: "処置変数",
                            parameterKey: "treatment_column",
                            type: .singleColumn,
                            description: "処置の有無（0/1）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "アウトカム",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "共変量",
                            parameterKey: "covariates",
                            type: .multipleColumns,
                            description: "傾向スコア計算用の変数",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "傾向スコアモデル",
                            parameterKey: "ps_model",
                            type: .categorical,
                            description: "logit/probit モデル",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "安定化重み",
                            parameterKey: "stabilized",
                            type: .categorical,
                            description: "重みの安定化（TRUE/FALSE）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "トリミング",
                            parameterKey: "trim",
                            type: .numeric,
                            description: "傾向スコアトリミング（0-0.5）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "バランス閾値",
                            parameterKey: "balance_threshold",
                            type: .numeric,
                            description: "標準化平均差の閾値",
                            required: false
                        )
                    ]
                )
            ]

        case .dimensionReduction:
            return [
                RecipeInfo(
                    name: "Principal Component Analysis",
                    nameJapanese: "主成分分析",
                    description: "多数の変数を主成分に圧縮",
                    recipeName: "pca_analysis",
                    requiredColumns: ["数値列（5列以上推奨）"],
                    example: "gene_1, gene_2, gene_3, ..., gene_10",
                    parameters: [
                        ParameterRequirement(
                            name: "分析対象列",
                            parameterKey: "predictor_columns",
                            type: .multipleColumns,
                            description: "PCAに使用する数値列（5列以上推奨）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "主成分数",
                            parameterKey: "n_components",
                            type: .numeric,
                            description: "抽出する主成分の数",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "中央化",
                            parameterKey: "center",
                            type: .categorical,
                            description: "センタリング（TRUE/FALSE）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "スケーリング",
                            parameterKey: "scale",
                            type: .categorical,
                            description: "スケーリング（TRUE/FALSE）",
                            required: false
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Partial Least Squares",
                    nameJapanese: "部分最小二乗法",
                    description: "予測と次元削減を同時実施",
                    recipeName: "pls_regression",
                    requiredColumns: ["結果変数", "予測変数（複数）"],
                    example: "y, x1, x2, x3, x4, x5",
                    parameters: [
                        ParameterRequirement(
                            name: "結果変数",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "予測対象となる列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "予測変数",
                            parameterKey: "predictor_columns",
                            type: .multipleColumns,
                            description: "PLSに使用する数値列（複数選択）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "CV折数",
                            parameterKey: "cv_folds",
                            type: .numeric,
                            description: "クロスバリデーション折数",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "最大成分数",
                            parameterKey: "ncomp_max",
                            type: .numeric,
                            description: "PLS成分の最大数",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "スケーリング",
                            parameterKey: "scale",
                            type: .categorical,
                            description: "スケーリング（TRUE/FALSE）",
                            required: false
                        )
                    ]
                ),
            ]

        case .metaAnalysis:
            return [
                RecipeInfo(
                    name: "Meta-Analysis",
                    nameJapanese: "メタアナリシス",
                    description: "複数の研究結果を統合し効果量を推定",
                    recipeName: "meta_analysis",
                    requiredColumns: ["効果サイズ", "標準誤差"],
                    example: "study_id, effect_size, se",
                    parameters: [
                        ParameterRequirement(
                            name: "効果サイズ",
                            parameterKey: "effect",
                            type: .singleColumn,
                            description: "各研究の効果量（Cohen's d等）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "標準誤差",
                            parameterKey: "se",
                            type: .singleColumn,
                            description: "効果サイズの標準誤差",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "研究ラベル（オプション）",
                            parameterKey: "label",
                            type: .singleColumn,
                            description: "各研究の名前または識別子（オプション）",
                            required: false
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Subgroup Meta-Analysis",
                    nameJapanese: "サブグループメタアナリシス",
                    description: "層別分析により複数グループの効果を比較",
                    recipeName: "subgroup_meta_analysis",
                    requiredColumns: ["効果サイズ", "標準誤差", "サブグループ列"],
                    example: "study_id, effect_size, se, year",
                    parameters: [
                        ParameterRequirement(
                            name: "効果サイズ",
                            parameterKey: "effect",
                            type: .singleColumn,
                            description: "各研究の効果量（Cohen's d等）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "標準誤差",
                            parameterKey: "se",
                            type: .singleColumn,
                            description: "効果サイズの標準誤差",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "研究ラベル（オプション）",
                            parameterKey: "label",
                            type: .singleColumn,
                            description: "各研究の名前または識別子（オプション）",
                            required: false
                        ),
                        ParameterRequirement(
                            name: "サブグループ列",
                            parameterKey: "subgroup_column",
                            type: .multipleColumns,
                            description: "層別分析に使用するカテゴリ列（年代、著者等）",
                            required: true
                        )
                    ]
                )
            ]
        }
    }
}

// MARK: - Recipe Information Model

struct RecipeInfo: Identifiable {
    let id = UUID()
    let name: String
    let nameJapanese: String
    let description: String
    let recipeName: String
    let requiredColumns: [String]
    let example: String
    let parameters: [ParameterRequirement]
}

// MARK: - Parameter Requirement Model

struct ParameterRequirement: Identifiable {
    let id = UUID()
    let name: String           // 表示名（「時間列」など）
    let parameterKey: String   // パラメータキー（「time_column」など）
    let type: ParameterType    // パラメータ型
    let description: String    // 説明
    let required: Bool         // 必須か
}

enum ParameterType {
    case singleColumn          // 1つの列を選ぶ
    case multipleColumns       // 複数の列を選ぶ
    case categorical           // カテゴリから選ぶ
    case numeric               // 数値入力
}

// MARK: - Package Information

struct RPackage: Identifiable {
    let id: String
    let name: String
    let description: String
    let isRequired: Bool
    let installCommand: String

    static let allPackages = [
        RPackage(
            id: "base",
            name: "Base R",
            description: "R基本パッケージ（インストール済み）",
            isRequired: true,
            installCommand: ""
        ),
        RPackage(
            id: "tidyverse",
            name: "Tidyverse",
            description: "データハンドリングと可視化",
            isRequired: false,
            installCommand: "install.packages('tidyverse')"
        ),
        RPackage(
            id: "pls",
            name: "PLS (部分最小二乗法)",
            description: "次元削減分析用",
            isRequired: false,
            installCommand: "install.packages('pls')"
        ),
        RPackage(
            id: "grf",
            name: "GRF (Causal Forest)",
            description: "因果推論用（異質処置効果）",
            isRequired: false,
            installCommand: "install.packages('grf')"
        ),
        RPackage(
            id: "AER",
            name: "Applied Econometrics (AER)",
            description: "操作変数法などの計量経済学手法",
            isRequired: false,
            installCommand: "install.packages('AER')"
        ),
        RPackage(
            id: "survival",
            name: "Survival",
            description: "生存分析（インストール済み）",
            isRequired: true,
            installCommand: ""
        ),
        RPackage(
            id: "MatchIt",
            name: "MatchIt",
            description: "傾向スコアマッチング",
            isRequired: false,
            installCommand: "install.packages('MatchIt')"
        ),
        RPackage(
            id: "WeightIt",
            name: "WeightIt",
            description: "逆確率重み付けと増強IPW",
            isRequired: false,
            installCommand: "install.packages('WeightIt')"
        ),
        RPackage(
            id: "bayesm",
            name: "Bayesm",
            description: "ベイズ回帰分析",
            isRequired: false,
            installCommand: "install.packages('bayesm')"
        ),
        RPackage(
            id: "metafor",
            name: "Metafor",
            description: "メタアナリシス",
            isRequired: false,
            installCommand: "install.packages('metafor')"
        )
    ]
}

// MARK: - Analysis Result

struct AnalysisResult: Identifiable {
    let id = UUID()
    let recipeName: String
    let timestamp: Date
    let summary: String
    let results: [String: String]

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - CSV Column Information

struct CSVColumn: Identifiable {
    let id: String
    let name: String
    let dataType: String
    let sampleValue: String
    let missingCount: Int

    var completeness: Double {
        return 1.0 - (Double(missingCount) / 100.0) // Assuming 100 rows for demo
    }
}

// MARK: - R Environment Helper Class

class REnvironment: ObservableObject {
    @Published var isInstalled = false
    @Published var version: String?
    @Published var installedPackages: Set<String> = []
    @Published var showRInstallationNeeded = false
    @Published var isInstallingR = false
    @Published var rInstallationMessage = ""

    func detectR() {
        // Detect R installation
        // This would actually execute: which Rscript
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["Rscript"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if !data.isEmpty {
                DispatchQueue.main.async {
                    self.isInstalled = true
                    self.detectRVersion()
                }
            } else {
                DispatchQueue.main.async {
                    self.isInstalled = false
                    self.showRInstallationNeeded = true
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isInstalled = false
                self.showRInstallationNeeded = true
            }
        }
    }

    private func detectRVersion() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/Rscript")
        process.arguments = ["-e", "cat(R.version$version.string)"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.version = output.trimmingCharacters(in: .whitespaces)
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.version = nil
            }
        }
    }

    func installRUsingHomebrew() {
        isInstallingR = true
        rInstallationMessage = "Homebrewを確認中..."

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", "which brew"]

            let pipe = Pipe()
            process.standardOutput = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if data.isEmpty {
                    // Homebrew not found - attempt auto-installation
                    DispatchQueue.main.async {
                        self.rInstallationMessage = "Homebrewをインストール中...\n(パスワードの入力が求められる場合があります)"
                    }
                    self.installHomebrew()
                } else {
                    DispatchQueue.main.async {
                        self.rInstallationMessage = "Rをインストール中...\n(この処理は数分かかります)"
                    }
                    self.performRInstallation()
                }
            } catch {
                DispatchQueue.main.async {
                    self.rInstallationMessage = "エラーが発生しました: \(error.localizedDescription)"
                    self.isInstallingR = false
                }
            }
        }
    }

    private func installHomebrew() {
        // Try to install Homebrew automatically
        let brewInstallScript = """
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", brewInstallScript]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                // Homebrew installed successfully, proceed with R installation
                DispatchQueue.main.async {
                    self.rInstallationMessage = "Homebrewのインストールが完了しました。\nRをインストール中...\n(この処理は数分かかります)"
                }
                self.performRInstallation()
            } else {
                // Homebrew installation failed, provide manual instructions
                DispatchQueue.main.async {
                    self.rInstallationMessage = """
                    ⚠️ Homebrew の自動インストール に失敗しました。

                    【手動インストール手順】
                    1. ターミナルを開く
                    2. 以下をコピーして貼り付け:
                       /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    3. Enterキーを押す
                    4. パスワードを入力 (表示されません)
                    5. インストール完了後、アプリで「今すぐインストール」を再度選択

                    詳細: https://brew.sh
                    """
                    self.isInstallingR = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.rInstallationMessage = """
                Homebrew のインストール中にエラーが発生しました。

                【手動インストール手順】
                1. ターミナルを開く
                2. 以下をコピーして貼り付け:
                   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                3. Enterキーを押す
                4. パスワードを入力
                5. インストール完了後、このダイアログを閉じて「今すぐインストール」を再度選択

                詳細: https://brew.sh
                エラー詳細: \(error.localizedDescription)
                """
                self.isInstallingR = false
            }
        }
    }

    private func performRInstallation() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "brew install r"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()

            // Read output in background
            DispatchQueue.global(qos: .userInitiated).async {
                while process.isRunning {
                    let data = outputPipe.fileHandleForReading.availableData
                    if data.count > 0 {
                        if let output = String(data: data, encoding: .utf8) {
                            DispatchQueue.main.async {
                                self.rInstallationMessage = "インストール中...\n" + output
                            }
                        }
                    }
                    usleep(100000) // Wait 0.1 seconds
                }

                process.waitUntilExit()

                // Check if installation was successful
                DispatchQueue.main.async {
                    if process.terminationStatus == 0 {
                        self.rInstallationMessage = "Rのインストールが完了しました！\nアプリを再起動してください。"
                        self.detectR() // Re-check
                    } else {
                        self.rInstallationMessage = "インストール中にエラーが発生しました。\nターミナルから 'brew install r' を実行してください。"
                    }
                    self.isInstallingR = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.rInstallationMessage = "エラーが発生しました: \(error.localizedDescription)"
                self.isInstallingR = false
            }
        }
    }

    func executeRecipe(named: String, with data: String) -> String {
        // Execute R recipe
        return "Recipe executed successfully"
    }
}
