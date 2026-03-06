# StatAppR R レシピファイル マッピング

## アプリに統合されている分析手法（20個）

### 📊 基本統計
| Rファイル | 内容 |
|:---|:---|
| `descriptive_analysis.R` | 平均、中央値、標準偏差などの記述統計量 |
| `correlation_analysis.R` | 複数変数間の相関係数・相関行列 |

### ⚖️ グループ比較
| Rファイル | アプリ表示名 | 内容 |
|:---|:---|:---|
| `two_group_continuous.R` | **T-Test (Independent)** | 2群のWelch's t-test（連続変数） |
| `anova_continuous.R` | **ANOVA** | 3群以上の分散分析 |
| `two_group_categorical.R` | **Mann-Whitney U Test** | ノンパラメトリック2群検定 |

### 📈 回帰分析
| Rファイル | アプリ表示名 | 内容 |
|:---|:---|:---|
| `linear_regression.R` | **Linear Regression** | 単回帰分析 |
| `multiple_regression.R` | **Multiple Regression** | 重回帰分析 |
| `logistic_regression.R` | **Logistic Regression** | ロジスティック回帰 |

### 📉 時系列・パネルデータ
| Rファイル | アプリ表示名 | 内容 |
|:---|:---|:---|
| (series_analysis.R推定) | **Time Series Analysis** | 時系列トレンド分析 |
| (panel_regression.R推定) | **Panel Regression** | パネル回帰・固定効果モデル |
| `difference_in_differences.R` | **Difference-in-Differences** | DID推定 |

### ⏱️ 生存分析
| Rファイル | アプリ表示名 | 内容 |
|:---|:---|:---|
| `survival_km.R` | **Kaplan-Meier Analysis** | カプラン・マイヤー分析 |
| `cox_regression.R` | **Cox Proportional Hazards** | Cox比例ハザードモデル |

### 🎯 因果推論
| Rファイル | アプリ表示名 | 内容 |
|:---|:---|:---|
| `ps_matching.R` | **Propensity Score Matching** | 傾向スコアマッチング |
| `double_ml_ate.R` | **Double Machine Learning** | ダブル機械学習 |
| `causal_forest.R` | **Causal Forest** | 因果フォレスト |
| `instrumental_variable.R` / `iv_2sls.R` | **Instrumental Variable** | 操作変数法・2SLS |

### 🎨 次元削減
| Rファイル | アプリ表示名 | 内容 |
|:---|:---|:---|
| `pca_analysis.R` | **Principal Component Analysis** | 主成分分析 |
| `pls_regression.R` | **Partial Least Squares** | 部分最小二乗法 |
| `factor_analysis.R` | **Factor Analysis** | 因子分析 |

---

## アプリに未統合のRレシピファイル（10個）

これらのファイルはEngine/recipes/ディレクトリに存在しますが、アプリのUIには統合されていません：

| Rファイル | 説明 |
|:---|:---|
| `aipw_ate.R` | Augmented IPW (AIPW) - 増強逆確率重み付け |
| `iptw_ate.R` | Inverse Probability of Treatment Weighting |
| `iptw_km_survival.R` | IPTW × Kaplan-Meier生存分析 |
| `balance_table.R` | バランステーブル（共変量バランス評価） |
| `bayesian_regression.R` | ベイズ回帰 |
| `case_crossover.R` | ケース交差デザイン |
| `conditional_logistic_regression.R` | 条件付きロジスティック回帰 |
| `event_study.R` | イベントスタディ |
| `meta_analysis.R` | メタアナリシス |
| `mixed_model.R` | 混合効果モデル |
| `placebo_test.R` | プラセボテスト |
| `synthetic_control.R` | 合成コントロール法 |
| `target_trial_emulation.R` | ターゲットトライアルエミュレーション |

---

## まとめ

**アプリUIに表示される分析手法**: 20種類
**Engine/recipesに実装されている手法**: 30種類
**カバレッジ**: 約67%

### 注記
- `two_group_continuous.R` は内部的には **T-Test (Independent)** として動作します
- 未統合のレシピは、将来のバージョンアップでUIに追加される可能性があります
- すべてのレシピはR実装として完成しており、RecipeRunnerを通じて直接実行可能です
