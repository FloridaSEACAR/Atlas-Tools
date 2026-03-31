# Executes the scripts for SAV and Discrete (Water Clarity & Nutrients) model aggregation
# Outputs are then utilized within TrendStatusGeneration.Rmd to generate
# 1.) Word document output 2.) Excel workbook formatted in HTML [sent to USF]
# TrendStatusGeneration also utilizes the respective stats outputs for other habitats
# To generate trend statements for these (un-aggregated) habitats

source("sav_ma_models.R")
source("disc_model_agg_bayesian_parallel.R")

rmarkdown::render("TrendStatusGeneration.Rmd", 
                  output_file = paste0("output/TrendStatus_", Sys.Date(), ".docx"))

### TrendTemplate.Rmd produces a preview .HTML with respective trend arrows in a similar format to the expected layout on the SEACAR Atlas.
### It must be compiled directly using Knit -> Knit to HTML