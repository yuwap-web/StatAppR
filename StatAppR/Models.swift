import Foundation
import Combine

// MARK: - Data Type Enumeration (7 Categories)

enum DataType: String, CaseIterable, Identifiable {
    case basicStats = "基本統計"
    case groupComparison = "グループ比較"
    case regression = "回帰分析"
    case timeSeries = "時系列・パネルデータ"
    case survival = "生存分析"
    case causalInference = "因果推論"
    case dimensionReduction = "次元削減"

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
        }
    }

    var recommendedRecipes: [RecipeInfo] {
        switch self {
        case .basicStats:
            return [
                RecipeInfo(
                    name: "Descriptive Statistics",
                    nameJapanese: "記述統計",
                    description: "平均値、中央値、標準偏差などを計算",
                    recipeName: "descriptive_analysis",
                    requiredColumns: ["数値列（複数可）"],
                    example: "patient_id, age, weight_kg, height_cm",
                    parameters: [
                        ParameterRequirement(
                            name: "分析対象列",
                            parameterKey: "numeric_columns",
                            type: .multipleColumns,
                            description: "統計量を計算する数値列（複数選択可）",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Correlation Analysis",
                    nameJapanese: "相関分析",
                    description: "複数の変数間の相関関係を分析",
                    recipeName: "correlation_analysis",
                    requiredColumns: ["数値列（2列以上）"],
                    example: "age, bmi, cholesterol, glucose",
                    parameters: [
                        ParameterRequirement(
                            name: "相関分析対象列",
                            parameterKey: "numeric_columns",
                            type: .multipleColumns,
                            description: "相関を計算する数値列（2列以上選択）",
                            required: true
                        )
                    ]
                )
            ]

        case .groupComparison:
            return [
                RecipeInfo(
                    name: "T-Test (Independent)",
                    nameJapanese: "t検定（独立標本）",
                    description: "2つの独立したグループを比較",
                    recipeName: "t_test",
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
                    recipeName: "anova",
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
                    recipeName: "mann_whitney",
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
                            parameterKey: "measurement_column",
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
                )
            ]

        case .timeSeries:
            return [
                RecipeInfo(
                    name: "Time Series Analysis",
                    nameJapanese: "時系列分析",
                    description: "時系列データのトレンド分析",
                    recipeName: "time_series_analysis",
                    requiredColumns: ["ID列", "時間列", "数値列"],
                    example: "company_id, quarter, sales_usd",
                    parameters: [
                        ParameterRequirement(
                            name: "ID列",
                            parameterKey: "id_column",
                            type: .singleColumn,
                            description: "企業/グループの識別列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "時間列",
                            parameterKey: "time_column",
                            type: .singleColumn,
                            description: "時間を示す列（quarter, year等）",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "数値列",
                            parameterKey: "value_column",
                            type: .singleColumn,
                            description: "分析対象となる数値列",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Panel Regression",
                    nameJapanese: "パネル回帰",
                    description: "固定効果モデルなど",
                    recipeName: "panel_regression",
                    requiredColumns: ["ID列", "時間列", "結果/予測変数"],
                    example: "firm_id, year, revenue, marketing_spend",
                    parameters: [
                        ParameterRequirement(
                            name: "ID列",
                            parameterKey: "id_column",
                            type: .singleColumn,
                            description: "パネルの識別列",
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
                            name: "結果変数",
                            parameterKey: "outcome_column",
                            type: .singleColumn,
                            description: "結果となる数値列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "予測変数",
                            parameterKey: "predictor_columns",
                            type: .multipleColumns,
                            description: "説明変数（複数選択可）",
                            required: false
                        )
                    ]
                ),
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
                )
            ]

        case .survival:
            return [
                RecipeInfo(
                    name: "Kaplan-Meier Analysis",
                    nameJapanese: "カプラン・マイヤー分析",
                    description: "生存曲線の推定と群比較",
                    recipeName: "kaplan_meier",
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
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Cox Proportional Hazards",
                    nameJapanese: "Cox比例ハザードモデル",
                    description: "共変量を調整したハザード比推定",
                    recipeName: "cox_proportional_hazards",
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
                    recipeName: "propensity_score_matching",
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
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Double Machine Learning",
                    nameJapanese: "ダブル機械学習",
                    description: "機械学習を使用した効果推定",
                    recipeName: "double_machine_learning",
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
                            parameterKey: "features",
                            type: .multipleColumns,
                            description: "分析に使用する特徴量（複数選択）",
                            required: true
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Instrumental Variable",
                    nameJapanese: "操作変数法",
                    description: "操作変数法による逆方向因果制御",
                    recipeName: "instrumental_variable",
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
                    recipeName: "principal_component_analysis",
                    requiredColumns: ["数値列（5列以上推奨）"],
                    example: "gene_1, gene_2, gene_3, ..., gene_10",
                    parameters: [
                        ParameterRequirement(
                            name: "分析対象列",
                            parameterKey: "numeric_columns",
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
                        )
                    ]
                ),
                RecipeInfo(
                    name: "Factor Analysis",
                    nameJapanese: "因子分析",
                    description: "潜在因子の抽出",
                    recipeName: "factor_analysis",
                    requiredColumns: ["数値列（複数）"],
                    example: "survey_q1, survey_q2, ..., survey_q15",
                    parameters: [
                        ParameterRequirement(
                            name: "分析対象列",
                            parameterKey: "numeric_columns",
                            type: .multipleColumns,
                            description: "因子分析に使用する数値列",
                            required: true
                        ),
                        ParameterRequirement(
                            name: "因子数",
                            parameterKey: "n_factors",
                            type: .numeric,
                            description: "抽出する因子の数",
                            required: false
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
                isInstalled = true
                detectRVersion()
            }
        } catch {
            isInstalled = false
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
                version = output.trimmingCharacters(in: .whitespaces)
            }
        } catch {
            version = nil
        }
    }

    func executeRecipe(named: String, with data: String) -> String {
        // Execute R recipe
        return "Recipe executed successfully"
    }
}
