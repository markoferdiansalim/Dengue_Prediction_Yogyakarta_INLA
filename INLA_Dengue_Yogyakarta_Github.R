# INLA Model Script for Spatio-Temporal Dengue Prediction
# Author: Marko Ferdian Salim
# GitHub: https://github.com/markoferdiansalim/Dengue_Prediction_Yogyakarta_INLA

################################################################################
############################## INLA SETUP ######################################
################################################################################

# 1. Install INLA package (only once)
install.packages("INLA", repos="https://inla.r-inla-download.org/R/stable", type="binary")

# Load required packages
library(readxl)
library(INLA)
library(sf)
library(spdep)
library(ggplot2)
library(dplyr)
library(RColorBrewer)
library(patchwork)

################################################################################
########################## Load and Prepare Data ###############################
################################################################################

setwd("~/Documents/R Studio/Regresi")

# Load panel data from Excel
data_panel <- read_excel('data panel dbd.xlsx')

# Load shapefile
shapefile <- st_read('Kecamatan_DIY_Edit.shp')
st_is_valid(shapefile)

# Remove Z/M dimensions and convert to Spatial format
shapefile_2d <- st_zm(shapefile, drop = TRUE, what = "ZM")
shapefile_spatial <- as(shapefile_2d, "Spatial")

# Create spatial weights using rook contiguity
nb <- poly2nb(shapefile_spatial, queen = FALSE)
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)
nb2INLA("spatial_adj.graph", nb)
spatial_adjacency <- inla.read.graph("spatial_adj.graph")

################################################################################
###################### Split Data: Training & Testing ##########################
################################################################################

n_bulan <- 72
n_train <- 58
n_test <- 14

# Split dataset
data_train <- data_panel %>% group_by(Subdistrict) %>% slice(1:n_train) %>% ungroup()
data_test <- data_panel %>% group_by(Subdistrict) %>% slice((n_train + 1):n_bulan) %>% ungroup()

# Create numeric ID for districts
data_train$IDSubdistrict <- as.numeric(as.factor(data_train$Subdistrict))
data_test$IDSubdistrict <- as.numeric(as.factor(data_test$Subdistrict))

# Convert 'Month' to numeric format YYYYMM
data_train$Month <- as.numeric(format(data_train$Month, "%Y%m"))
data_test$Month <- as.numeric(format(data_test$Month, "%Y%m"))

################################################################################
########################## Define INLA Model Formula ###########################
################################################################################

formula_bym2 <- DengueIncidence ~ PopDensity + Rainfall + RainfallLag1 + 
  RainfallLag2 + RainfallLag3 + TempAvg + HumRev +
  WindSpeed + AtmPress + BuiltArea + Crops + Water + Trees + FloodedVegetation +
  f(IDSubdistrict, model = "bym2", graph = spatial_adjacency, scale.model = TRUE) + 
  f(Month, model = "rw2")

# Run INLA
result_train_bym2 <- inla(formula_bym2, family = "poisson", data = data_train,
                          control.predictor = list(compute = TRUE, link = 1),
                          control.compute = list(dic = TRUE, waic = TRUE))
summary(result_train_bym2)

################################################################################
######################## Prediction and Evaluation #############################
################################################################################

# Add "set" label to split data
data_train$set <- "training"
data_test$set <- "testing"
data_combined <- rbind(data_train, data_test)

# Rerun model on full data for prediction
data_combined$set <- factor(data_combined$set)
result_combined_bym2 <- inla(formula_bym2, family = "poisson", data = data_combined,
                             control.predictor = list(compute = TRUE, link = 1),
                             control.compute = list(dic = TRUE, waic = TRUE))

# Extract predicted values for test set
data_test$predicted <- result_combined_bym2$summary.fitted.values[which(data_combined$set == "testing"), "mean"]
data_test$predicted <- round(data_test$predicted)

# Evaluate predictions
comparison <- data.frame(
  Subdistrict = data_test$Subdistrict,
  Month = data_test$Month,
  Actual = data_test$DengueIncidence,
  Predicted = data_test$predicted
)

mae <- mean(abs(comparison$Actual - comparison$Predicted))
rmse <- sqrt(mean((comparison$Actual - comparison$Predicted)^2))

cat("Mean Absolute Error (MAE):", mae, "\n")
cat("Root Mean Squared Error (RMSE):", rmse, "\n")

################################################################################
############################ Visualization #####################################
################################################################################

# Bar plot of actual vs predicted per month
summary_comparison <- comparison %>%
  group_by(Month) %>%
  summarise(Total_Actual = sum(Actual), Total_Predicted = sum(Predicted)) %>%
  pivot_longer(cols = c(Total_Actual, Total_Predicted), names_to = "Category", values_to = "Total")

plot_bar <- ggplot(summary_comparison, aes(x = as.factor(Month), y = Total, fill = Category)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c("Total_Actual" = "blue", "Total_Predicted" = "red")) +
  labs(title = "Monthly Actual vs Predicted Dengue Cases", x = "Month", y = "Total Cases") +
  theme_minimal()

ggsave("Monthly_Comparison_Actual_vs_Predicted.png", plot = plot_bar, width = 10, height = 6, dpi = 300)

################################################################################
############################# Spatial Mapping ##################################
################################################################################

# Prepare shapefile
shapefile_2d <- shapefile_2d %>% rename(Subdistrict = WADMKC)
shapefile_2d$Subdistrict <- trimws(toupper(shapefile_2d$Subdistrict))
data_test$Subdistrict <- trimws(toupper(data_test$Subdistrict))

# Merge spatial and prediction data
shapefile_aktual <- shapefile_2d %>% left_join(data_test, by = "Subdistrict")

# Plot actual and predicted cases
for (bulan in unique(data_test$Month)) {
  shapefile_bulan <- shapefile_aktual %>% filter(Month == bulan)
  
  p_aktual <- ggplot(shapefile_bulan) +
    geom_sf(aes(fill = DengueIncidence), color = "black") +
    scale_fill_viridis_c(option = "plasma") +
    labs(title = paste("Actual Cases -", bulan), fill = "Actual") +
    theme_minimal()
  
  p_prediksi <- ggplot(shapefile_bulan) +
    geom_sf(aes(fill = predicted), color = "black") +
    scale_fill_viridis_c(option = "plasma") +
    labs(title = paste("Predicted Cases -", bulan), fill = "Predicted") +
    theme_minimal()
  
  combined_plot <- p_aktual + p_prediksi + plot_layout(ncol = 2)
  ggsave(paste0("Map_Comparison_Month_", bulan, ".png"), combined_plot, width = 12, height = 6)
}

################################################################################
########################### Evaluation Summary #################################
################################################################################

evaluation_results <- data.frame(
  Metric = c("MAE", "RMSE", "DIC", "WAIC", "Effective Parameters"),
  Value = c(mae, rmse, result_train_bym2$dic$dic, result_train_bym2$waic$waic, result_train_bym2$dic$p.eff)
)
print(evaluation_results)
