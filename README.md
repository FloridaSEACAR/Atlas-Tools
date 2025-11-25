# Atlas-Tools

Relative paths are used for most files, where the SEACAR_Trend_Analyses repository is assumed to be in the same parent folder as Atlas-Tools. This can be achieved by cloning both repositories into a “SEACAR GitHub” folder on the desktop. The following dependencies are downstream of the individual habitat analyses performed within SEACAR_Trend_Analyses, which should all be performed prior to Atlas-Tools implementation.

## ModelAggregation

### Consists of the following files and their dependencies:

-   run.R (executes the analyses)

    -   WebsiteParameters (via SEACAR package)

-   sav_ma_models.R

    -   SAV_BBpct_LMEresults_All.xlsx

    -   SAV models (SEACAR_Trend_Analyses/SAV/output/models)

        -   SAV_BBpct\_... .rds

        -   Failedmodslist.rds

    -   Simplified SAV .rds trendplots (SEACAR_Trend_Analyses/SAV/output/Figures/BB)

-   disc_model_agg_bayesian_parallel.R

    -   WQ_Discrete_All_KendallTau_Stats.txt

    -   Only for diagnostic plots:

    -   Skt_stats_disc (only for diagnostics - SEACAR_Trend_Analyses/WQ_Cont_Discrete/output/tables/disc/skt_stats_disc.rds)

    -   Rds objects in SEACAR_Trend_Analyses/WQ_Cont_Discrete/output/figuredata/

-   TrendStatusGeneration.Rmd

    -   WQ_agg_results.xlsx (created in disc_model_agg_bayesian_parallel.R above)

    -   WQ_Discrete_All_KendallTau_Stats.txt

    -   all_SAV_MA_Results.xlsx (created in sav_ma_models.R above)

    -   Nekton_SpeciesRichness_MA_Overall_Stats.txt

    -   Nekton_SpeciesRichness_MA_Yr_Stats.txt

    -   CoastalWetlands_SpeciesRichness_MA_Overall_Stats.txt

    -   CoastalWetlands_SpeciesRichness_MA_Yr_Stats.txt

    -   Coral_SpeciesRichness_MA_Overall_Stats.txt

    -   Coral_SpeciesRichness_MA_Yr_Stats.txt

    -   Coral_PC_LME_Stats.txt

    -   Oyster_All_GLMM_Stats.txt

    -   output/disc_model_results.csv (created in disc_model_agg_bayesian_parallel.R above)

    -   ChangeAnalysis_ChangeResultTable_YYYY.xlsx (provided by USF)

## tableDescriptions

#### Consists of the following files and their dependencies:

-   run.R (executes the analyses)

    -   WebsiteParameters (via SEACAR package)

    -   ManagedAreas (via SEACAR package)

-   Each habitat has a .csv file which contains the table descriptions which are generated in-line within each habitat analysis. These files are then combined into the final AtlasDescriptions.xlsx output file.
