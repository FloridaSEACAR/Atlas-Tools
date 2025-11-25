# As of 11/25/2025, the table descriptions are generated within each individual habitat analysis.
# The outputs of these "*_tableDescriptions.csv" are parsed together with this script.
# The code original from "*_TableDescriptions.Rmd" is now maintained within the SEACAR-DEV package.

library(rstudioapi)
library(knitr)
library(openxlsx)
library(data.table)
library(dplyr)
knitr::opts_chunk$set(warning = FALSE, echo = FALSE, message = FALSE)

wd <- dirname(getActiveDocumentContext()$path)
setwd(wd)

# Read in all relevant habitat outputs from their respective folders
cw <- fread("../../SEACAR_Trend_Analyses/Coastal_Wetlands/output/cw_tableDescriptions.csv")
coral <- fread("../../SEACAR_Trend_Analyses/Coral/output/coral_tableDescriptions.csv")
nekton <- fread("../../SEACAR_Trend_Analyses/Nekton/output/nekton_tableDescriptions.csv")
oyster <- fread("../../SEACAR_Trend_Analyses/Oyster/output/oyster_tableDescriptions.csv")
sav <- fread("../../SEACAR_Trend_Analyses/SAV/output/sav_tableDescriptions.csv")
wq <- fread("../../SEACAR_Trend_Analyses/WQ_Cont_Discrete/output/WQ_tableDescriptions.csv")

descTable <- rbind(cw, coral, nekton, oyster, sav, wq)

# Ensure that "None" entries in "SamplingFrequency" column are rendered as NA in final output
descTable$SamplingFrequency[descTable$SamplingFrequency=="None"] <- NA

websiteParams <- SEACAR::WebsiteParameters %>% 
  select(HabitatName, IndicatorName, ParameterName, SamplingFrequency, ParameterVisId)

websiteParams$IndicatorName[websiteParams$IndicatorName=="Percent Cover" & 
                              websiteParams$HabitatName=="Submerged Aquatic Vegetation"] <- "Percent Cover (by species)"

# Combine ParameterVisId into final output file
descTable <- merge(descTable, websiteParams, all.x = T)

# Add MA AreaID into final output file
MA_All <- SEACAR::ManagedAreas
# Add AreaID into final exports
descTable <- merge(MA_All[, c("ManagedAreaName", "AreaID")], descTable, by = "ManagedAreaName", all.y = T)

# Export output file
write.xlsx(descTable,
           file = paste0("output/Atlas_Descriptions_",
                         gsub("_","-",(Sys.Date())), ".xlsx"),
           asTable = T)

# Import WebsiteParameters.csv
websiteParams <- SEACAR::WebsiteParameters
# Correct order of websiteParams to match format from the Atlas
websiteParams <- websiteParams %>% 
  arrange(factor(IndicatorName, levels = c("Nutrients","Water Quality","Water Clarity")),
          factor(ParameterName, levels = c("Total Nitrogen","Total Phosphorus",
                                           "Dissolved Oxygen", "Dissolved Oxygen Saturation", "Salinity", "Water Temperature", "pH",
                                           "Turbidity", "Total Suspended Solids", "Chlorophyll a, Uncorrected for Pheophytin",
                                           "Chlorophyll a, Corrected for Pheophytin", "Secchi Depth", "Colored Dissolved Organic Matter"))) %>%
  filter(Website==1)
setDT(websiteParams)

# main.Rmd renders a word document containing a selection of table descriptions
rmarkdown::render("main.Rmd", output_file = paste0("output/allTableDescriptions_", Sys.Date(), ".docx"))
