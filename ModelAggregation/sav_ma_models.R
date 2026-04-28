library(rstudioapi)
library(lme4)
library(nlme)
library(glue)
library(tidyverse)
library(data.table)
library(SEACAR)
MA_All <- SEACAR::ManagedAreas

# Set current working directory
wd <- dirname(getActiveDocumentContext()$path)
setwd(wd)

##### SAV Model aggregation overview #####
## Isolate MAs with Total Seagrass/Total SAV values.
## 1.) In these MAs default to using Total SAV > Total Seagrass where available, if not use Total Seagrass.
## 2.) For all others: exclude "Drift algae" and "No grass in quadrat" model results.
## 3.) If only 1 species remains, use that species' model result as the "aggregate" value.
## 4.) If more than 1 species remains, run the model aggregation below.

# Read in stats outputs
sav <- openxlsx::read.xlsx("../../SEACAR_Trend_Analyses/SAV/output/website/SAV_BBpct_LMEresults_All.xlsx") %>% distinct() %>% as.data.table()

# All SAV managed areas
managedareas <- sav[SufficientData==TRUE, unique(ManagedAreaName)]

# Create subset of MAs with successful models
ma_subset <- MA_All[ManagedAreaName %in% managedareas]
sav_mod_locs <- list.files("../../SEACAR_Trend_Analyses/SAV/output/models/", pattern = "SAV_BBpct_", full.names=T)
failedmodslist <- readRDS("../../SEACAR_Trend_Analyses/SAV/output/models/failedmodslist.rds")
# Exclude Drift Algae, Total Seagrass, and Total SAV from aggregate model
short_sp_to_exlcude <- c("DrAl", "ToSe", "ToSa")

#Managed areas that should have Halophila species combined:
ma_halspp <- c("Banana River Aquatic Preserve", "Indian River-Malabar to Vero Beach Aquatic Preserve", 
               "Indian River-Vero Beach to Ft. Pierce Aquatic Preserve", "Jensen Beach to Jupiter Inlet Aquatic Preserve",
               "Loxahatchee River-Lake Worth Creek Aquatic Preserve", "Mosquito Lagoon Aquatic Preserve", 
               "Biscayne Bay Aquatic Preserve", "Florida Keys National Marine Sanctuary")

all_data <- data.frame()
sav_results <- data.frame()
for(ma in managedareas){
  # abbreviated MA name
  ma_abrev <- MA_All[ManagedAreaName==ma, Abbreviation]
  # locate models from a given MA
  ma_mods <- str_subset(sav_mod_locs, ma_abrev)
  ma_data <- data.frame()
  for(m in ma_mods){
    filename <- tail(str_split_1(m, "/"),1)
    # Skip failed models; if they are listed in "failedmodslist"
    if(filename %in% failedmodslist$model) next
    # Extract species name from model filename
    sp <- str_split_1(tail(str_split_1(filename, "_"),1), ".rds")[1]
    # Exclude species in short_sp_to_exlcude
    if(sp %in% short_sp_to_exlcude) next
    mod <- readRDS(m)
    # Ensure that MAs with halophila species combined use the correct column
    if(ma %in% ma_halspp){
      column <- as.name("analysisunit")
    } else {
      column <- as.name("analysisunit_halid")
    }
    # Store raw data for each species within the MA, convert common names to match previous model results
    temp_data <- mod$data
    temp_data <- temp_data %>% mutate(
      common_name = case_when(
        get(column) == "Halodule wrightii" ~ "Shoal grass",
        get(column) == "Syringodium filiforme" ~ "Manatee grass",
        get(column) == "Thalassia testudinum" ~ "Turtle grass",
        get(column) == "Ruppia maritima" ~ "Widgeon grass",
        get(column) == "Halophila johnsonii" ~ "Johnson's seagrass",
        get(column) == "Halophila decipiens" ~ "Paddle grass",
        get(column) == "Halophila engelmannii" ~ "Star grass",
        .default = as.character(get(column))
      )
    )
    ma_data <- bind_rows(ma_data, temp_data)
  }
  # Only run model when there are >1 species available
  # When only 1 species available, record results for that individual species
  if(length(unique(ma_data$analysisunit))<2){
    temp_ma <- sav %>% filter(ManagedAreaName==ma, 
                              Species %in% unique(ma_data$common_name))
    # Compile results
    ma_model_results <- data.frame(
      "ManagedAreaName" = ma,
      "Intercept" = temp_ma$LME_Intercept,
      "Slope" = temp_ma$LME_Slope,
      "p" = round(temp_ma$p,6),
      "Source" = unique(ma_data$common_name),
      "SpIncluded" = unique(ma_data$common_name)
    )
    # Store model result overviews
    sav_results <- bind_rows(sav_results, ma_model_results)
  }
  # Run a fixed effects model for each MA, using species (common_name) as factor
  model_fixed <- try(nlme::lme(BB_pct ~ relyear + common_name, 
                               random = list(SiteIdentifier = ~relyear),
                               control = list(msMaxIter = 1000, msMaxEval = 1000, 
                                              sing.tol=1e-20),
                               na.action = na.omit,
                               data = ma_data),
                     silent = TRUE)
  species_included <- paste(unique(ma_data$common_name), collapse = "|")
  # Collect necessary information from models which were successful
  if(class(try(model_fixed)) != "try-error"){
    ma_mod_results <- broom.mixed::tidy(model_fixed) %>% filter(effect == "fixed") %>% as.data.table()
    ma_model_results <- data.frame(
      "ManagedAreaName" = ma,
      "Intercept" = ma_mod_results[term=="(Intercept)", estimate],
      "Slope" = ma_mod_results[term=="relyear", estimate],
      "p" = round(ma_mod_results[term=="relyear", p.value],6),
      "Source" = "aggregate",
      "SpIncluded" = species_included
    )
    
    # Store model result overviews
    sav_results <- bind_rows(sav_results, ma_model_results)
  # Account for models that failed
  } else if(!ma %in% unique(sav_results$ManagedAreaName)){
    avail_sp <- sav %>% filter(ManagedAreaName==ma) %>% pull(Species)
    # Record results for either Total SAV or Total Seagrass (Total SAV prioritized over Total Seagrass)
    if(any(c("Total SAV", "Total Seagrass") %in% avail_sp)){
      if("Total SAV" %in% avail_sp){
        temp_ma <- sav %>% filter(ManagedAreaName==ma, Species=="Total SAV")
      } else if("Total Seagrass" %in% avail_sp){
        temp_ma <- sav %>% filter(ManagedAreaName==ma, Species=="Total Seagrass")
      }
      ma_model_results <- data.frame(
        "ManagedAreaName" = ma,
        "Intercept" = temp_ma$LME_Intercept,
        "Slope" = temp_ma$LME_Slope,
        "p" = round(temp_ma$p,6),
        "Source" = unique(temp_ma$Species),
        "SpIncluded" = unique(temp_ma$Species)
      ) 
    } else {
      # Return NULL results if model failed and neither Total SAV or Total Seagrass were available
      ma_model_results <- data.frame(
        "ManagedAreaName" = ma,
        "Intercept" = NA,
        "Slope" = NA,
        "p" = NA,
        "Source" = NA,
        "SpIncluded" = NA
      )
    }
    
    # Store model result overviews for Total SAV, Total Seagrass, or NA results
    sav_results <- bind_rows(sav_results, ma_model_results)
  }
  
  # Store all data for each MA
  all_data <- bind_rows(all_data, ma_data)

}
# Determine trend values for each result (1 = pos trend, -1 = neg trend, 0 = no trend)
sav_results <- sav_results %>% rowwise() %>%
  mutate(Trend = ifelse(p<=0.05 & Slope>0, 1, ifelse(p<=0.05 & Slope<0, -1, 0)))

# Add additional info which may be used in indicator summaries text
extra_info <- sav %>% 
  filter(!N_Data==0) %>% 
  group_by(ManagedAreaName) %>% 
  summarise(N_Data = sum(N_Data), 
            N_Programs = max(N_Programs),
            minYear = min(EarliestYear),
            maxYear = max(LatestYear))

# Merge extra info into sav_results and write to file (used as input in TrendStatusGeneration.Rmd)
openxlsx::write.xlsx(merge(sav_results, extra_info), file = "output/all_SAV_MA_Results.xlsx", asTable = T)

# Create visualizations of aggregate results, overlaid on previous simplified sav plots
simple_plots <- list.files("../../SEACAR_Trend_Analyses/SAV/output/Figures/BB/", pattern = "trendplot", full.names=T)
simple_plots <- str_subset(simple_plots, "_BBpct_")

all_plots <- list()
for(ma in sav_results$ManagedAreaName){
  subset <- sav_results %>% filter(ManagedAreaName==ma)
  ma_abrev <- MA_All[ManagedAreaName==ma, Abbreviation]
  
  plot <- readRDS(str_subset(simple_plots, paste0("_",ma_abrev,"_")))
  plot <- plot +
    geom_abline(aes(linewidth = subset$Source, intercept = subset$Intercept, 
                    slope = subset$Slope), color = "blue") +
    labs(linewidth = "model source")
  ggsave(filename = paste0("output/sav_plots/agg_model_", ma_abrev, ".png"), plot, height = 10, width = 10)
  all_plots[[ma]] <- plot
}
