# Phase 2P3 Quick Start Guide: RecipeExecutionEngine Module

**Current Status**: Phase 2P2 ✅ COMPLETE
**Next Phase**: Phase 2P3 - RecipeExecutionEngine implementation
**Target Size**: ~250 lines
**Expected Impact**: Further reduce ContentView complexity + improve recipe execution orchestration

## What is RecipeExecutionEngine?

A new module that centralizes all recipe execution logic, reducing ContentView from ~1,100 to ~800 lines.

**Current State** (Monolithic):
```
ContentView.executeRecipe() [~66 lines]
├── Load CSV data
├── Get recipe from Models
├── Match parameters
├── Build R command
├── Execute R script
├── Parse JSON output
└── Update UI with results
```

**Target State** (Modular):
```
RecipeExecutionEngine [~250 lines]
├── prepareExecution() - Validate inputs
├── execute() - Run recipe
└── handleError() - Handle failures

ContentView [~800 lines]
├── UI Layer
├── State Management
└── Call RecipeExecutionEngine
```

## Implementation Checklist

### Phase 2P3a: Create RecipeExecutionEngine.swift
- [ ] Create new file: `StatAppR/RecipeExecutionEngine.swift`
- [ ] Define: `class RecipeExecutionEngine`
- [ ] Extract: `executeRecipe()` logic from ContentView
- [ ] Extract: `buildRCommand()` from RecipeRunner
- [ ] Integrate: RecipeParameterMatcher, CSVManager, RecipeRunner
- [ ] Build: Verify compilation succeeds

### Phase 2P3b: Refactor ContentView.swift
- [ ] Replace `executeRecipe()` with call to engine
- [ ] Remove duplicate execution logic
- [ ] Update state management for engine integration
- [ ] Build: Verify compilation succeeds
- [ ] Test: Run with all recipe types

### Phase 2P3c: Testing
- [ ] Test parameter matching (use Meta-Analysis recipe)
- [ ] Test plot generation (use Kaplan-Meier or Subgroup analysis)
- [ ] Test error handling (use invalid CSV)
- [ ] Test result display (verify tables + figures show)
- [ ] Regression test: Verify all previously working recipes still work

### Phase 2P3d: Commit & Merge
- [ ] Create feature branch: `git checkout -b feat/recipe-execution-engine`
- [ ] Commit changes with detailed message
- [ ] Build verification: `xcodebuild build`
- [ ] Merge to main: `git checkout main && git merge feat/recipe-execution-engine`

## Key Methods to Extract

From `ContentView.swift`:
```swift
// Line ~760-830 (executeRecipe method)
private func executeRecipe()
```

From `RecipeRunner.swift`:
```swift
// Line ~40-120 (buildRCommand method)
private func buildRCommand(...)
```

## Integration Points

**Called by**: ContentView button "分析を実行"
**Calls**: RecipeParameterMatcher, CSVManager, RecipeRunner
**Returns**: Result<RecipeOutput, RecipeError>

## Success Criteria

| Check | Target | Verification |
|-------|--------|--------------|
| ContentView size | < 800 lines | `wc -l StatAppR/ContentView.swift` |
| RecipeExecutionEngine size | ~250 lines | `wc -l StatAppR/RecipeExecutionEngine.swift` |
| Build succeeds | No errors | `xcodebuild build` |
| All tests pass | 31 recipes | Manual recipe testing |
| No regressions | Previous working recipes | Subgroup, Meta-analysis, etc. |
| Git history clean | 2 commits | `git log --oneline | head -3` |

## Testing Recipes (Quick Validation)

1. **Meta-Analysis** (simple)
   - File: `8_MetaAnalysis_study_results.csv`
   - Expected: 3 tables, 1 forest plot

2. **Subgroup Meta-Analysis** (complex)
   - File: `8_MetaAnalysis_study_results.csv`
   - Parameters: effect, se, subgroup_column (year)
   - Expected: Multiple forest plots per subgroup

3. **Kaplan-Meier** (plotting)
   - File: `6_SurvivalAnalysis_censored_data.csv`
   - Expected: Survival curves plot

4. **PCA Analysis** (no plot)
   - File: `4_Dimensionality_reduction_data.csv`
   - Expected: Scree plot + loadings + scores tables

## Common Pitfalls to Avoid

❌ **Don't forget**:
- Set `runner_dir` environment variable in R command
- Convert selectedColumnsByParameter to R request format
- Handle nil values in CSV data
- Clean up temp files after execution

✅ **Do remember**:
- Keep RecipeParameterMatcher as standalone dependency
- Maintain CSVManager integration
- Preserve error message i18n (Japanese)
- Test with actual CSV files from Sample_Data/

## Timeline Estimate

- **Phase 2P3a** (Create module): 30 minutes
- **Phase 2P3b** (Refactor ContentView): 20 minutes
- **Phase 2P3c** (Testing): 30 minutes
- **Phase 2P3d** (Commit): 10 minutes
- **Total**: ~90 minutes

## Reference Documentation

- Current: `PHASE_2P2_COMPLETION_REPORT.md` ← Recent modularization work
- Architecture: `SWIFT_ARCHITECTURE_ANALYSIS.md` ← Full design notes
- Implementation: `REFACTORING_IMPLEMENTATION_GUIDE.md` ← Phase-by-phase plan

## Questions?

Refer to:
- `StatAppR/RecipeParameterMatcher.swift` - Parameter matching reference
- `StatAppR/ContentView.swift` - Current executeRecipe() implementation
- `StatAppR/RecipeRunner.swift` - R command building reference

---

**Status**: Ready to begin Phase 2P3 implementation
**Last Updated**: 2026-03-07
**Branch**: main (commit: fb013d3)
