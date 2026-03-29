# Mummichog Analysis Parameters

**Analysis Date:** 2026-03-16

**Database:** hsa_kegg

**MetaboAnalystR 'Set' Function Outputs:**
- SetPeakFormat: mpr
- SetPeakEnrichMethod: mummichog (v2)
- SetMummichogPvalFromPercent: 0.1 (top 10% of peaks)

**Instrument Parameters (UpdateInstrumentParameters):**
- instrumentOpt: 5
- msModeOpt: mixed
- force_primary_ion: yes
- rt_frac: 0.02

**Analysis Parameters:**
- Peak filtering method: Top 10% of peaks (dynamic)
- Peak filtering threshold (rounded): 0.05
- Peak filtering threshold (precise): 0.0856595308702631
- Peaks analyzed: 552 out of 23692
- Pathways analyzed: 59
- Significant pathways (p < 0.05): 7
- Pathway p-values range: 0.006654 to 0.99382
- Pathway FDR: Not calculated (using raw p-values)
- Pathway enrichment FDR threshold: 0.05 (fixed)
- Minimum pathway size: 3
- Background permutations: 100

**Input Data:**
- Number of features: 23692
- Output directory: Outputs/mummichog/allsev/KEGG

