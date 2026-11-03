# Applied regression case studies: banking profiles and a water-oil experiment
# Run this file from the project folder with: Rscript analysis.R
# Everything in this script uses base R; no extra packages are needed.

dir.create("figures", showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Banking market profiles
# -----------------------------------------------------------------------------

# Read the data from the data folder inside this project.
bank <- read.csv("data/BANKING.csv")
cat("Banking data: ", nrow(bank), " rows\n", sep = "")
print(summary(bank))

# Correlations show the strength and direction of pairwise relationships.
bank_cor <- cor(bank)
cat("\nBanking correlation matrix\n")
print(round(bank_cor, 3))

# Plot balance against each potential predictor. Orange lines are local smoothers.
png("figures/banking-associations.png", width = 1500, height = 950, res = 150)
par(mfrow = c(2, 3), mar = c(4.3, 4.5, 3, 1))

plot(bank$Age, bank$Balance, xlab = "Age", ylab = "Average bank balance ($)",
     main = "Balance vs Age", pch = 19, col = "#2B6F77")
lines(lowess(bank$Age, bank$Balance), col = "#C56A3D", lwd = 2)

plot(bank$Education, bank$Balance, xlab = "Education", ylab = "Average bank balance ($)",
     main = "Balance vs Education", pch = 19, col = "#2B6F77")
lines(lowess(bank$Education, bank$Balance), col = "#C56A3D", lwd = 2)

plot(bank$Income, bank$Balance, xlab = "Income ($)", ylab = "Average bank balance ($)",
     main = "Balance vs Income", pch = 19, col = "#2B6F77")
lines(lowess(bank$Income, bank$Balance), col = "#C56A3D", lwd = 2)

plot(bank$HomeVal, bank$Balance, xlab = "Home value ($)", ylab = "Average bank balance ($)",
     main = "Balance vs Home Value", pch = 19, col = "#2B6F77")
lines(lowess(bank$HomeVal, bank$Balance), col = "#C56A3D", lwd = 2)

plot(bank$Wealth, bank$Balance, xlab = "Household wealth ($)", ylab = "Average bank balance ($)",
     main = "Balance vs Wealth", pch = 19, col = "#2B6F77")
lines(lowess(bank$Wealth, bank$Balance), col = "#C56A3D", lwd = 2)

plot.new() # Leave the sixth panel blank.
dev.off()

# Fit all five predictors, then remove HomeVal and refit the model.
bank_full <- lm(Balance ~ Wealth + HomeVal + Income + Age + Education, data = bank)
bank_final <- lm(Balance ~ Wealth + Income + Age + Education, data = bank)

cat("\nFull banking model\n")
print(summary(bank_full))
cat("\nReduced banking model (HomeVal removed)\n")
print(summary(bank_final))

# Calculate variance inflation factors (VIFs) to check predictor overlap.
# Each auxiliary regression predicts one variable from the other three.
vif_wealth <- 1 / (1 - summary(lm(Wealth ~ Income + Age + Education, data = bank))$r.squared)
vif_income <- 1 / (1 - summary(lm(Income ~ Wealth + Age + Education, data = bank))$r.squared)
vif_age <- 1 / (1 - summary(lm(Age ~ Wealth + Income + Education, data = bank))$r.squared)
vif_education <- 1 / (1 - summary(lm(Education ~ Wealth + Income + Age, data = bank))$r.squared)

bank_vif <- c(Wealth = vif_wealth, Income = vif_income,
              Age = vif_age, Education = vif_education)
cat("\nVariance inflation factors for reduced banking model\n")
print(round(bank_vif, 2))

# Standard regression diagnostic plots for the reduced model.
png("figures/banking-diagnostics.png", width = 1500, height = 950, res = 150)
par(mfrow = c(2, 2), mar = c(4.3, 4.5, 3, 1))
plot(bank_final, which = 1:4, pch = 19, col = "#2B6F77")
dev.off()

# Cook's distance highlights rows that may have a strong effect on the model.
bank_cooks <- cooks.distance(bank_final)
cat("\nLargest banking Cook's distance:", round(max(bank_cooks), 3),
    "at row", which.max(bank_cooks), "\n")
cat("Rows above the common 4/n screening value:",
    sum(bank_cooks > 4 / nrow(bank)), "\n")

# -----------------------------------------------------------------------------
# 2. Water-oil separation experiment
# -----------------------------------------------------------------------------

water <- read.table("data/WATEROIL.txt", header = TRUE)
cat("\nWater-oil experiment:", nrow(water), " observations\n")

# First fit an additive model, then add interactions and a squared salinity term.
water_additive <- lm(Voltage ~ Volume + Salinity + Surfactant, data = water)
water_model <- lm(Voltage ~ Volume + Salinity + Surfactant +
                    Volume:Salinity + Volume:Surfactant + I(Salinity^2),
                  data = water)

cat("\nAdditive water-oil model\n")
print(summary(water_additive))
cat("\nWater-oil model with interactions and curvature\n")
print(summary(water_model))

# Predict voltage across salinity for four volume/surfactant combinations.
salinity_values <- seq(min(water$Salinity), max(water$Salinity), length.out = 100)

prediction_40_2 <- predict(water_model,
                           newdata = data.frame(Volume = 40, Salinity = salinity_values,
                                                Surfactant = 2))
prediction_40_4 <- predict(water_model,
                           newdata = data.frame(Volume = 40, Salinity = salinity_values,
                                                Surfactant = 4))
prediction_80_2 <- predict(water_model,
                           newdata = data.frame(Volume = 80, Salinity = salinity_values,
                                                Surfactant = 2))
prediction_80_4 <- predict(water_model,
                           newdata = data.frame(Volume = 80, Salinity = salinity_values,
                                                Surfactant = 4))

prediction_range <- range(water$Voltage, prediction_40_2, prediction_40_4,
                          prediction_80_2, prediction_80_4)

png("figures/water-oil-response-surface.png", width = 1200, height = 850, res = 150)
par(mar = c(4.5, 4.7, 3, 1))
plot(range(salinity_values), prediction_range, type = "n",
     xlab = "Salinity (%)", ylab = "Predicted separation voltage (kW/cm)",
     main = "Model estimates at selected factor settings")
lines(salinity_values, prediction_40_2, col = "#2B6F77", lwd = 2)
lines(salinity_values, prediction_40_4, col = "#C56A3D", lwd = 2, lty = 2)
lines(salinity_values, prediction_80_2, col = "#6B5B95", lwd = 2)
lines(salinity_values, prediction_80_4, col = "#4E8B57", lwd = 2, lty = 2)
points(water$Salinity, water$Voltage, pch = 19, col = "#777777")
legend("topright",
       legend = c("Volume 40%, surfactant 2%", "Volume 40%, surfactant 4%",
                  "Volume 80%, surfactant 2%", "Volume 80%, surfactant 4%"),
       col = c("#2B6F77", "#C56A3D", "#6B5B95", "#4E8B57"),
       lty = c(1, 2, 1, 2), lwd = 2, cex = 0.72, bty = "n")
dev.off()

# Plot residuals and Cook's distances to check the selected model.
water_cooks <- cooks.distance(water_model)
png("figures/water-oil-diagnostics.png", width = 1500, height = 750, res = 150)
par(mfrow = c(1, 2), mar = c(4.5, 4.7, 3, 1))
plot(fitted(water_model), resid(water_model),
     xlab = "Fitted voltage (kW/cm)", ylab = "Residual (kW/cm)",
     main = "Water-oil model residuals", pch = 19, col = "#2B6F77")
abline(h = 0, lty = 2, col = "#C56A3D", lwd = 2)

plot(water_cooks, type = "h", xlab = "Observation", ylab = "Cook's distance",
     main = "Water-oil influence screening", col = "#2B6F77", lwd = 2)
abline(h = 4 / nrow(water), lty = 2, col = "#C56A3D", lwd = 2)
dev.off()

cat("\nLargest water-oil Cook's distance:", round(max(water_cooks), 3),
    "at row", which.max(water_cooks), "\n")
cat("Rows above the common 4/n screening value:",
    sum(water_cooks > 4 / nrow(water)), "\n")
