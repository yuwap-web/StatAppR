# PDF Report Generation - Testing Guide

**Last Updated**: 2026-03-06
**Focus**: Verifying improved PDF content rendering with gridExtra

## Quick Summary of Changes

The PDF generation in `subgroup_meta_analysis.R` has been significantly improved:

| Issue | Previous | Now |
|-------|----------|-----|
| Content Incomplete | Text overlaps/cuts off | Full table-based layout |
| Font Rendering | Basic text() function | gridExtra tables + proper UTF-8 |
| Layout Fragility | Manual y-coordinates | Grid viewport system |
| Table Display | Text list format | Professional gridExtra tables |
| Fallback | No fallback | Graceful .generate_pdf_report_simple() |

## Step-by-Step Testing

### Phase 1: Application Preparation (5 minutes)

#### 1.1 Build Application
```bash
cd /Users/uts/StatAppR
xcodebuild -scheme StatAppR -configuration Debug
```

Expected result: `** BUILD SUCCEEDED **` ✅

#### 1.2 Verify Build Success
```bash
ls -la /Users/uts/Library/Developer/Xcode/DerivedData/StatAppR-*/Build/Products/Debug/StatAppR.app/Contents/MacOS/StatAppR
```

Should show the executable exists and is recent (within last few minutes).

#### 1.3 Launch Application
- **Option A**: Use Xcode ▶️ button (easiest)
- **Option B**: Open app manually:
  ```bash
  open "/Users/uts/Library/Developer/Xcode/DerivedData/StatAppR-*/Build/Products/Debug/StatAppR.app"
  ```

### Phase 2: Data Loading (2 minutes)

#### 2.1 Open CSV File
1. In StatAppR window, click **"CSV ファイルを選択"** button (left panel)
2. Navigate to: `/Users/uts/StatAppR/Sample_Data/`
3. Select: `9_SubgroupMetaAnalysis_study_results.csv`
4. Click Open

#### 2.2 Wait for CSV Processing
- Watch console for: `✅ csvColumns更新完了`
- This indicates CSV is loaded and columns are extracted

### Phase 3: Recipe Selection (1 minute)

#### 3.1 Verify Recipe Recommendation
- After CSV loads, verify left panel shows:
  - Category: "メタ分析"
  - Recipes available: "Meta-Analysis" and "Subgroup Meta-Analysis"

#### 3.2 Select Recipe
1. Click on **"Subgroup Meta-Analysis"** (サブグループメタアナリシス)
2. Verify checkboxes appear for parameters:
   - ✓ 効果サイズ (effect_size) - AUTO-CHECKED
   - ✓ 標準誤差 (standard_error) - AUTO-CHECKED
   - □ 研究ラベル (author) - Optional
   - ✓ サブグループ列 (study_type) - AUTO-CHECKED

### Phase 4: Analysis Execution (10 seconds)

#### 4.1 Run Analysis
1. Click **"分析を実行"** button (right panel)
2. Watch console for execution logs
3. Observe R progress messages

#### 4.2 Wait for Completion
Expected console output:
```
🔍 [DEBUG] Executing recipe: subgroup_meta_analysis
✅ JSON saved to /tmp/recipe_output_*.json
✅ Analysis complete!
```

### Phase 5: PDF Verification (5 minutes) ⭐ KEY TEST

#### 5.1 Locate PDF in Results
After analysis completes:
1. Scroll down to **"図表プレビュー"** section
2. Look for entry: **"PDF レポート"** or **"統計報告書（PDF）"**
3. Should show the PDF filename below it

#### 5.2 Open PDF
1. Click **"開く"** button next to PDF entry
2. PDF should open in macOS Preview application

#### 5.3 Verify Page 1 Content ✅

**Expected Display:**

Page 1 header:
```
サブグループメタアナリシス報告書
```

Following content should display clearly in a TABLE format:

Subheading with study info (check all visible):
```
サブグループメタ分析: 3グループ, 15研究, p = 0.0000
```

**Metrics Table** (this is the critical part - verify TABLE format):

| 指標 | 値 |
|------|-----|
| 総研究数 | 15 |
| サブグループ数 | 3 |
| 全体効果量 | 0.4881 |
| P値 | ~0 |
| I² | 33.6% |

**Verification Checklist for Page 1:**
- [ ] Title "サブグループメタアナリシス報告書" is visible at top
- [ ] Metrics are displayed in TABLE format (not just text)
- [ ] All 5 metrics rows are visible
- [ ] Values are readable (no overlapping text)
- [ ] No content cutoff at page bottom
- [ ] Footer timestamp visible at bottom

#### 5.4 Verify Page 2+ Content ✅

Flip through remaining pages (should be 3-4 pages total):

**Expected per-subgroup page:**

Header:
```
サブグループ: RCT
```

Statistics Table (verify TABLE format):

| 項目 | 値 |
|------|-----|
| 研究数 | 5 |
| 効果量 | 0.5000 |
| 95% 信頼区間 | [0.424, 0.576] |
| P値 | ~1.23e-45 |
| I² | 13.9% |
| Q統計量 | 4.63 (df=4, p = ...) |

**Verification Checklist per Subgroup Page:**
- [ ] Subgroup name visible in header
- [ ] Statistics displayed in TABLE format (gridExtra format)
- [ ] All rows visible (minimum 5-6 rows per subgroup)
- [ ] Values are clearly readable
- [ ] No text overlapping
- [ ] Footer timestamp visible

#### 5.5 Font Rendering Check ✅

**Critical Check**: Japanese text rendering
- [ ] Title uses proper Japanese characters (not garbled)
- [ ] Column headers (指標, 値) display correctly
- [ ] Row labels (研究数, 効果量, etc.) show proper characters
- [ ] No mojibake or font substitution artifacts
- [ ] All accented characters display correctly

#### 5.6 Layout & Spacing ✅

- [ ] Tables have proper borders/gridlines
- [ ] Column alignment is clean
- [ ] No text cutoff at page edges
- [ ] Margins appear reasonable (not too tight)
- [ ] Page breaks occur between subgroups (not mid-table)

### Phase 6: Comparative Analysis

#### 6.1 File System Check
1. Open Finder
2. Navigate to Results Folder path (shown in UI)
3. Locate the PDF file
4. Note filename format: `report_YYYYMMDD_HHMMSS.pdf`

**Expected location**: `/tmp/StatAppR_results/report_*.pdf`

#### 6.2 File Properties
```bash
ls -lh /tmp/StatAppR_results/report_*.pdf
file /tmp/StatAppR_results/report_*.pdf
```

Expected:
- File size: 100-300 KB (reasonable PDF size)
- File type: PDF document

#### 6.3 Re-open and Verify Consistency
1. Close the PDF in Preview
2. Click "開く" button again
3. Verify same content displays consistently

## Success Criteria ✅

The improved PDF implementation is successful if:

### Must Have (Critical):
1. ✅ PDF file is created and saved to results folder
2. ✅ PDF opens without errors in macOS Preview
3. ✅ Page 1 displays metrics in TABLE format (not just loose text)
4. ✅ All subgroup pages display in TABLE format
5. ✅ Japanese characters render correctly (no garbled text)
6. ✅ No text overlapping or cutoff
7. ✅ All statistical values are visible and readable

### Should Have (Important):
1. ✅ Professional table borders/gridlines visible
2. ✅ Proper alignment of columns and rows
3. ✅ Reasonable spacing and margins
4. ✅ Footer timestamp appears on all pages
5. ✅ Multiple pages with page breaks between subgroups

### Nice to Have (Enhancement):
1. ✅ Bold headers for better readability
2. ✅ Consistent formatting across all pages
3. ✅ Clean, professional appearance

## Troubleshooting

### Issue: PDF file not created

**Symptoms**: No PDF entry in results section

**Diagnosis**:
```bash
tail -100 /tmp/recipe_output_*.json | grep -i error
```

**Solutions**:
1. Check console for error messages
2. Verify gridExtra package is available:
   ```bash
   R --vanilla --slave -e "require('gridExtra'); cat('gridExtra available\n')"
   ```
3. Check `/tmp/StatAppR_results/` folder exists:
   ```bash
   ls -la /tmp/StatAppR_results/ | head -10
   ```

### Issue: PDF created but content incomplete

**Symptoms**: PDF opens but pages are blank or partially filled

**This should NO LONGER occur** with the gridExtra implementation.

**If it does occur** (unlikely):
1. Fallback mechanism activates (should use `.generate_pdf_report_simple()`)
2. Content should still display, just in simpler format
3. Report to developer with console output

### Issue: PDF opens but text garbled/unreadable

**Symptoms**: Japanese text shows as ? or weird characters

**This should NOT occur** with UTF-8 encoding fix.

**If it does**:
1. Indicates encoding issue in R
2. Fallback should still work
3. Check R locale:
   ```bash
   R --vanilla --slave -e "Sys.getlocale()"
   ```

### Issue: PDF tables don't align or look misaligned

**Symptoms**: Table columns misaligned, borders missing

**Solutions**:
1. gridExtra should handle this automatically
2. Try regenerating PDF (re-run analysis)
3. Check PDF isn't corrupted:
   ```bash
   pdfinfo /tmp/StatAppR_results/report_*.pdf
   ```

## Performance Metrics

**Expected Timing:**
- CSV loading: 1-2 seconds
- Recipe selection: <1 second
- Analysis execution: 3-5 seconds
- PDF generation: 1-2 seconds
- PDF rendering (Preview): 1-2 seconds

**Total workflow**: ~10-15 seconds from load to viewing PDF

## Detailed Content Expectations

### Sample Data: 9_SubgroupMetaAnalysis_study_results.csv

**Input Data**:
- 15 studies total
- 3 subgroups: RCT (5 studies), Observational (5 studies), Cohort (5 studies)
- Effect sizes: 0.2-0.8 range
- Standard errors: 0.05-0.15 range

**Expected Output Metrics**:

**Page 1 Summary**:
```
総研究数: 15
サブグループ数: 3
全体効果量: 0.4881 (approximately)
P値: < 0.0001
I²: 33.6%
```

**Subgroup Results**:

RCT Group:
- n_studies: 5
- Effect: ~0.500
- 95% CI: ~[0.424, 0.576]
- I²: ~13.9%

Observational Group:
- n_studies: 5
- Effect: ~0.323
- 95% CI: ~[0.220, 0.426]
- I²: ~0%

Cohort Group:
- n_studies: 5
- Effect: ~0.561
- 95% CI: ~[0.488, 0.635]
- I²: ~0%

## Next Steps After Verification

If all tests pass ✅:
1. PDF generation is working properly
2. Content is complete and properly formatted
3. Japanese rendering is correct
4. Ready for production use

If any issues encountered:
1. Note exact symptoms
2. Collect console output
3. Save PDF file for inspection
4. Report with details

## Reference Documentation

- `/Users/uts/StatAppR/Engine/recipes/subgroup_meta_analysis.R` - Implementation
- `/Users/uts/StatAppR/QUICKTEST_SUBGROUP.md` - Quick test guide
- `/Users/uts/StatAppR/SUBGROUP_METANALYSIS_IMPLEMENTATION.md` - Full implementation details
- `/Users/uts/StatAppR/PDF_IMPROVEMENT_SUMMARY.md` - Technical improvements

---

**Test Version**: 2026-03-06
**Improvements Applied**: gridExtra-based PDF with table rendering, UTF-8 encoding, grid viewport layout
**Status**: Ready for user testing
