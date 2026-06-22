# Loading and formatting our data ==============================================

# Importing necessary packages
library(ggplot2)
library(dplyr)
library(forcats)

# 1. Read the csv
watchesdata <- read.csv("data-raw/watchesdata.csv")

# 2. Robust Cleaning (Base R)
# Loop through every column. If it's text, scrub the fake empty values.
for (col in names(watchesdata)) {
  if (is.character(watchesdata[[col]])) {
    
    # Remove accidental spaces (e.g., turning "   " into "")
    watchesdata[[col]] <- trimws(watchesdata[[col]])
    
    # Replace empty strings and the word "NA" with actual R missing values
    watchesdata[[col]][watchesdata[[col]] == ""] <- NA
    watchesdata[[col]][watchesdata[[col]] == "NA"] <- NA
  }
}

# Now that fake nulls are officially NA, we can safely omit them
watchesdata <- na.omit(watchesdata)

# We have some obvious errors in the dial face area, we omit the unrealistically high values
watchesdata <- subset(watchesdata, Face.Area <= 2500)

# 3. Rename columns
names(watchesdata)[names(watchesdata) == "Year.of.production"] <- "Year"
names(watchesdata)[names(watchesdata) == "Face.Area"] <- "DialFaceArea"
names(watchesdata)[names(watchesdata) == "Water.resistance"] <- "WaterResistance"
names(watchesdata)[names(watchesdata) == "Watches.Sold.by.the.Seller"] <- "SellerNumSales"
names(watchesdata)[names(watchesdata) == "Active.listing.of.the.seller"] <- "ActiveListingNumSeller"
names(watchesdata)[names(watchesdata) == "Seller.Reviews"] <- "SellerNumReviews"
names(watchesdata)[names(watchesdata) == "Case.material"] <- "CaseMaterial"
names(watchesdata)[names(watchesdata) == "Bracelet.material"] <- "BraceletMaterial"
names(watchesdata)[names(watchesdata) == "Scope.of.delivery"] <- "DeliveryForm"
names(watchesdata)[names(watchesdata) == "Shape"] <- "CaseShape"
names(watchesdata)[names(watchesdata) == "Bracelet.color"] <- "BraceletColor"
names(watchesdata)[names(watchesdata) == "Fast.Shipper"] <- "FastShipper"
names(watchesdata)[names(watchesdata) == "Trusted.Seller"] <- "TrustedSeller"
names(watchesdata)[names(watchesdata) == "Punctuality"] <- "SellerPunctuality"

# 4. Convert boolean values to logical
watchesdata$FastShipper <- as.logical(watchesdata$FastShipper)
watchesdata$TrustedSeller <- as.logical(watchesdata$TrustedSeller)
watchesdata$SellerPunctuality <- as.logical(watchesdata$SellerPunctuality)

# 5. Factorize categorical variables
# Loop through again and convert any remaining text columns into factors
for (col in names(watchesdata)) {
  if (is.character(watchesdata[[col]])) {
    watchesdata[[col]] <- as.factor(watchesdata[[col]])
  }
}

# Setting the reference categories  for easier economic interpretation
watchesdata$Movement <- relevel(watchesdata$Movement, ref = "Quartz")
watchesdata$Condition <- relevel(watchesdata$Condition, ref = "Used (Very good)")
watchesdata$DeliveryForm <- relevel(watchesdata$DeliveryForm, ref = "No original box, no original papers")
watchesdata$Gender <- relevel(watchesdata$Gender, ref = "Men's watch/Unisex")
watchesdata$Availability <- relevel(watchesdata$Availability, ref = "Item is in stock")
watchesdata$CaseShape <- relevel(watchesdata$CaseShape, ref = "Circular")
watchesdata$Crystal <- relevel(watchesdata$Crystal, ref = "Mineral Glass")
watchesdata$Clasp <- relevel(watchesdata$Clasp, ref = "Buckle")

# Verify our data looks correct
table(watchesdata$Brand)
summary(watchesdata$Price)

# Save the perfectly clean dataset
write.csv(watchesdata, file = "data/nonullswatchdata.csv", row.names = FALSE)

## Visualizing the distribution of Price (Keeping 100% of the data) =============

### 1. Histogram (Log10 Scale) ----
ggplot(data = watchesdata, aes(x = Price)) + 
  geom_histogram(bins = 60, fill = "steelblue", color = "black") +
  scale_x_log10(labels = scales::comma) + 
  labs(
    title = "Distribution of Watch Prices (Log Scale)",
    subtitle = "Log10 transformation makes the right tail highly visible",
    x = "Price ($)",
    y = "Count"
  ) +
  theme_minimal()

### 2. Boxplot by Condition (Log10 Scale) ----
ggplot(data = watchesdata, aes(x = Condition, y = Price, fill = Condition)) + 
  geom_boxplot() +
  scale_y_log10(labels = scales::comma) +
  labs(
    title = "Price Distribution by Condition",
    subtitle = "Includes all market extremes"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

### 3. Boxplot by Brand (Log10 Scale) ----
ggplot(data = watchesdata, aes(x = reorder(Brand, Price, FUN = median), y = Price)) +
  geom_boxplot(fill = "steelblue", outlier.alpha = 0.3) +
  scale_y_log10(labels = scales::comma) +
  coord_flip() + 
  labs(
    title = "Price Distribution by Brand (Complete Market Data)",
    x = "Brand",
    y = "Price ($)"
  ) +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 5))

#We have a lot of brands which break our white-tests, 
#so we decided to reduce the number of brands by replacing the variable with 
#a country of origin and an exclusivity variable named Tier

unique(watchesdata$Brand)

watchesdata <- watchesdata %>%
  mutate(
    # 1. COUNTRY OF ORIGIN 
    Country = fct_collapse(Brand,
                           Germany = c("Glashütte Original", "A. Lange & Söhne", "Sinn", "NOMOS", "Junghans", 
                                       "Stowa", "Meistersinger", "Tutima", "Laco", "Mühle Glashütte", 
                                       "Zeppelin", "Hanhart", "Union Glashütte", "Moritz Grossmann", 
                                       "Lang & Heyne", "Damasko", "Iron Annie", "Thomas Ninchritz", 
                                       "Erwin Sattler", "Alexander Shorokhoff", "Askania", "Aristo", "Junkers"),
                           Japan = c("Seiko", "Grand Seiko", "Citizen", "Casio", "Orient"),
                           USA = c("Hamilton", "Bulova", "Timex", "Garmin", "Luminox", "Ball", "Shinola", 
                                   "Accutron", "Deep Blue", "Gruen", "Benrus", "Waltham", "Tiffany", "Ralph Lauren"),
                           Italy = c("Panerai", "Bulgari", "Squale", "U-Boat", "Anonimo", "Venezianico", 
                                     "Locman", "Maserati", "Gucci", "Armani", "Sector", "Breil", "Ennebi", 
                                     "Meccaniche Veloci", "Out of Order", "Tonino Lamborghini", "Fendi", 
                                     "Giuliano Mazzuoli", "Lorenz", "Philip Watch", "Officina del Tempo"),
                           France = c("Cartier", "Chanel", "Bell & Ross", "Yema", "Hermès", "Dior", 
                                      "Van Cleef & Arpels", "Michel Herbelin", "Boucheron", "Chaumet", 
                                      "Baltic", "Alain Silberstein", "Pequignet", "S.T. Dupont", "Lip", "B.R.M"),
                           Russia_EasternEurope = c("Vostok", "Poljot", "Raketa", "Konstantin Chaykin"),
                           UK = c("Bremont", "Christopher Ward", "Arnold & Son", "Speake-Marin", "Alfred Dunhill", "M.A.D. Editions"),
                           China = c("Sea-Gull", "Behrens")
    ),
    # Map all remaining unlisted brands to "Switzerland"
    Country = fct_other(Country, 
                        keep = c("Germany", "Japan", "USA", "Italy", "France", "Russia_EasternEurope", "UK", "China"), 
                        other_level = "Switzerland"),
    
    # 2. HOROLOGICAL TIER (EXCLUSIVITY) 
    Tier = fct_collapse(Brand,
                        # Tier 1: Holy Trinity & Ultra-High-End Independents (Prices highly skewed)
                        Haute_Horlogerie = c("Patek Philippe", "Audemars Piguet", "Vacheron Constantin", 
                                             "A. Lange & Söhne", "Breguet", "Richard Mille", "F.P.Journe", 
                                             "Greubel Forsey", "Mb&f", "De Bethune", "Laurent Ferrier", 
                                             "Bovet", "Jaquet-Droz", "Armin Strom", "Christophe Claret", 
                                             "Urwerk", "H.Moser & Cie.", "Lang & Heyne", "Czapek", "Ming", "Romain Jerome"),
                        
                        # Tier 2: Mainstream High-End Luxury (High brand premium, in-house movements)
                        Luxury = c("Rolex", "Omega", "Jaeger-LeCoultre", "Blancpain", "Glashütte Original", 
                                   "Hublot", "Girard Perregaux", "Cartier", "Grand Seiko", "Ulysse Nardin", 
                                   "Zenith", "Chopard", "Piaget", "IWC", "Breitling", "Panerai", "Bulgari", 
                                   "Parmigiani Fleurier", "Franck Muller", "Carl F. Bucherer"),
                        
                        # Tier 3: Mid-Tier & Entry Luxury (Accessible luxury, reliable workhorse movements)
                        Entry_Luxury = c("Tudor", "TAG Heuer", "Longines", "NOMOS", "Oris", "Sinn", 
                                         "Bell & Ross", "Baume & Mercier", "Montblanc", "Frederique Constant", 
                                         "Maurice Lacroix", "Bremont", "Fortis", "Doxa", "Zodiac", "Rado", 
                                         "Mido", "Alpina", "Union Glashütte", "Tutima", "Hanhart", "Meistersinger", 
                                         "Eberhard & Co.", "Norqain", "Formex", "Christopher Ward", "Baltic", 
                                         "Zelos", "Squale", "Yema", "Ebel", "Raymond Weil", "Eterna", "Glycine"),
                        
                        # Tier 4: Fashion & High Jewelry (Priced for brand name on dial, not horological spec)
                        Fashion_Jewelry = c("Gucci", "Armani", "Versace", "Chanel", "Dior", "Hermès", 
                                            "Tiffany", "Boucheron", "Chaumet", "Ralph Lauren", "Fendi", 
                                            "Salvatore Ferragamo", "Pierre Balmain", "Balmain", 
                                            "Tonino Lamborghini", "Porsche Design", "ck Calvin Klein", "Maserati"),
                        
                        # Tier 5: Consumer, Heritage Entry & Mall Watches (High volume, low margins)
                        Consumer_Enthusiast = c("Seiko", "Tissot", "Hamilton", "Certina", "Citizen", "Casio", 
                                                "Orient", "Victorinox Swiss Army", "Luminox", "Bulova", "Timex", 
                                                "Swatch", "Vostok", "Poljot", "Sea-Gull", "Laco", "Steinhart", 
                                                "Zeppelin", "Junkers", "Mondaine", "Invicta", "Festina", "Rotary", 
                                                "Deep Blue", "Spinnaker", "Traser", "Mondia", "Wenger")
    ),
    # Map any obscure niche brands not captured above to a baseline category
    Tier = fct_other(Tier, 
                     keep = c("Haute_Horlogerie", "Luxury", "Entry_Luxury", "Fashion_Jewelry", "Consumer_Enthusiast"), 
                     other_level = "Niche_Independent")
  )
#releveling the Tier variable, as having premiums over mainstream makes interpretation easier
watchesdata$Tier <- relevel(watchesdata$Tier, ref = "Consumer_Enthusiast")


# 1. Collapse BraceletMaterial (24 levels -> 7 levels)
levels(watchesdata$BraceletMaterial) <- list(
  Steel_Titanium = c("Steel", "Titanium"),
  
  Precious_Metal = c("Yellow gold", "Rose gold", "White gold", "Red gold", "Platinum", "Silver"),
  
  Two_Tone_Plated = c("Gold/Steel", "Gold-plated"),
  
  Exotic_Leather = c("Crocodile skin", "Alligator skin", "Lizard skin", "Ostrich skin", "Snake skin", "Shark skin"),
  
  Standard_Leather = c("Leather", "Calf skin", "Satin"),
  
  Rubber_Synthetic = c("Rubber", "Silicon", "Plastic", "Textile"),
  
  Ceramic = "Ceramic"
)

# 2. Collapse Dial (22 levels -> 4 levels)
levels(watchesdata$Dial) <- list(
  # Standard neutral colors do not carry a price premium
  Neutral_Color = c("Black", "White", "Silver", "Grey"),
  
  # Vibrant colors (often trend-driven, but generally priced similar to neutrals)
  Vibrant_Color = c("Blue", "Green", "Brown", "Champagne", "Bordeaux", "Red", "Yellow", 
                    "Orange", "Turquoise", "Purple", "Pink"),
  
  # Materials that require significant sourcing or precious metal premiums
  Exotic_Precious = c("Meteorite", "Mother of pearl", "Gold (solid)", "Silver (solid)", 
                      "Bronze", "Gold"),
  
  # A manufacturing technique denoting high horology (exposes the movement)
  Skeletonized = "Skeletonized"
)



# 3. Drop BraceletColor entirely to prevent Multicollinearity
watchesdata <- watchesdata[, !(names(watchesdata) %in% "BraceletColor")]

# 4. Collapse CaseMaterial
levels(watchesdata$CaseMaterial) <- list(
  
  # 1. The standard machined utility metals
  Standard_Alloys = c("Steel", "Titanium"),
  
  # 2. Traditional intrinsic-value metals
  Precious_Metals = c("Yellow gold", "White gold", "Rose gold", "Red gold", "Platinum"),
  
  # 3. Aspirational luxury (mixed or layered)
  Two_Tone_Plated = c("Gold/Steel", "Gold-plated"),
  
  # 4. Cutting-edge R&D and high-machining-cost materials
  Advanced_Tech = c("Ceramic", "Carbon", "Sapphire crystal"),
  
  # 5. Other
  Other = c("Bronze", "Silver", "Plastic", "Aluminum")
)



unique(watchesdata$BraceletMaterial)
unique(watchesdata$BraceletColor)
unique(watchesdata$Dial)
unique(watchesdata$CaseMaterial)

# Turning the Year column into a ModelAge column to have a true numeric variable,
# that does is more meaningful in out usecase
max(watchesdata$Year)

# Create the new numeric Age column anchored to the dataset's vintage (2024)
watchesdata$ModelAge <- 2024 - watchesdata$Year

# Drop the old Year column to prevent multicollinearity
watchesdata <- watchesdata[, !(names(watchesdata) %in% "Year")]

unique(watchesdata$SellerPunctuality) # only TRUE
# variable not useful --> not included in our model


# Train / Test Split (80/20) ===================================================

set.seed(123)
sample_size <- floor(0.80 * nrow(watchesdata))
train_indices <- sample(seq_len(nrow(watchesdata)), size = sample_size)

train_data <- watchesdata[train_indices, ]
test_data  <- watchesdata[-train_indices, ]


# Testing for HETEROSKEDASTICITY ===============================================

# determine variables needed in the final model
first_model <- lm(Price ~ Movement + CaseMaterial + BraceletMaterial + ModelAge + Condition + DeliveryForm +
                    Gender + Availability + CaseShape + DialFaceArea + WaterResistance + Crystal +
                    Dial + Clasp + SellerNumSales + ActiveListingNumSeller + FastShipper +
                    TrustedSeller + SellerNumReviews + 
                    Country + Tier, data = train_data)
summary(first_model)
train_data$errorFirst <- first_model$residuals

## 0) Plot ----
ggplot(train_data, aes(x=Price, y=errorFirst^2)) + geom_point()
# in higher Y values we can see, that the model predicts log-prices with more 
# distributions in predictors is long right-tailed, log transformation is needed
# errors -> most likely Heteroskedasticity is present in the model

first_model_log <- lm(log(Price) ~ Movement + CaseMaterial + BraceletMaterial + log(ModelAge+1) + Condition + DeliveryForm +
                        Gender + Availability + CaseShape + DialFaceArea + WaterResistance + Crystal +
                        Dial + Clasp + log(SellerNumSales+1) + log(ActiveListingNumSeller+1) + FastShipper +
                        TrustedSeller + log(SellerNumReviews+1) + 
                        Country + Tier, data = train_data)
summary(first_model_log)
train_data$errorFirstLog <- first_model_log$residuals

## 0) Plot ----
ggplot(train_data, aes(x=log(Price), y=errorFirstLog^2)) + geom_point()



## 1) Hypothesis testing ----

# Auxilary regression = error^2 ~ Brand

# H0: Homoskedastic   (R^2_Aux = 0)
# H1: Heteroskedastic (R^2_Aux > 0)

# Since sample size is over 600, we will conduct an White-Test

skedastic::white(first_model_log, interactions = TRUE)
# p-value = 2.65e-40 --> H1


## 2) Tackling Heteroskedasticity ----

# We've decided to take on the issue with GLS

auxFirst <- lm(log(I(errorFirst^2)) ~ Movement + CaseMaterial + BraceletMaterial + log(ModelAge+1) + Condition + DeliveryForm + 
                 Gender + Availability + CaseShape + DialFaceArea + WaterResistance + Crystal +
                 Dial + Clasp + log(SellerNumSales+1) + log(ActiveListingNumSeller+1) + FastShipper +
                 TrustedSeller + log(SellerNumReviews+1) + Country + Tier, 
               data = train_data)

train_data$FirstPredSqError <- exp(auxFirst$fitted.values)

glsFirst <- lm(log(Price) ~ Movement + CaseMaterial + BraceletMaterial + log(ModelAge+1) + Condition + DeliveryForm + 
                 Gender + Availability + CaseShape + DialFaceArea + WaterResistance + Crystal +
                 Dial + Clasp + log(SellerNumSales+1) + log(ActiveListingNumSeller+1) + FastShipper +
                 TrustedSeller + log(SellerNumReviews+1) + Country + Tier, 
               data = train_data, weights = 1/FirstPredSqError)

train_data$errorGLSWeighted <- glsFirst$residuals
ggplot(train_data, aes(x=log(Price), y=errorGLSWeighted^2)) + geom_point()

summary(glsFirst)
summary(first_model_log)

lmtest::bptest(glsFirst, studentize = TRUE)

# Multicollinearity ============================================================


summary(glsFirst)
car::vif(glsFirst)
# we can see that SellerNumSales and SellerNumReviews variables have a GVIF^(1/2*Df) > 10
# we drop one to fix multicollinearity in the model (we dropped SellerNumSales)

glsFirst_no_multicoll <- lm(log(Price) ~ Movement + CaseMaterial + BraceletMaterial + log(ModelAge+1) + Condition + DeliveryForm +
                              Gender + Availability + CaseShape + DialFaceArea + WaterResistance + Crystal +
                              Dial + Clasp + log(ActiveListingNumSeller+1) + FastShipper + 
                              TrustedSeller + log(SellerNumReviews+1) + Country + Tier,
                            data = train_data, weights = 1/FirstPredSqError)
summary(glsFirst_no_multicoll)
car::vif(glsFirst_no_multicoll)

# Model selection ==============================================================

# 1. Stepwise Selection using AIC
# We first test a backward stepwise selection process based on the AIC.
# The algorithm iteratively removes variables that do not provide sufficient explanatory power.
# The default step() function uses k = 2, which corresponds to AIC.
final_model_aic <- step(glsFirst_no_multicoll, direction = "backward")
summary(final_model_aic)

# 2. Stepwise Selection using BIC
# Because AIC can overfit large datasets by keeping too many marginal variables,
# we run a second selection based on the BIC. BIC applies a stricter mathematical 
# penalty for complexity (k = log(n)), isolating only the most robust predictors.
n <- nrow(watchesdata)
final_model_bic <- step(glsFirst_no_multicoll, direction = "backward", k = log(n))
summary(final_model_bic)

# 3. Comparing the Dropped Variables
attr(terms(glsFirst_no_multicoll), "term.labels") # Original full model variables
attr(terms(final_model_aic), "term.labels")       # Variables kept by AIC
attr(terms(final_model_bic), "term.labels")       # Variables kept by BIC

# Dropped variables with AIC: 3 - Availability, WaterResistance, FastShipper
# Dropped variables with BIC: 7 - ModelAge, DeliveryForm, Availability, WaterResistance, FastShipper, Dial, TrustedSeller

# We proceed with the BIC model as it more successfully eliminates noise and overfitting 
# for our specific use case, resulting in a more generalizable model.
final_model <- final_model_bic


# We also checked the PCA but we decided to proceed with the VIF
# also PCA only works for numeric variables
summary(prcomp(train_data[,c(11,12,16,17,21,24)], center = TRUE, scale.=TRUE))
pca = prcomp(train_data[,c(11,12,16,17,21,24)], center = TRUE, scale.=TRUE)
train_data = cbind(train_data, pca$x[,1:3])

# here we observed that by dropping SellerNumSales to fix multicollinearity in the previous step
# we indirectly transferred its effect to
# ActiveListingNumSeller, SellerNumReviews variables.
corrplot::corrplot(cor(train_data[,c(11,12,16,17,21,24,28,29,30)]))


# Model specification ==========================================================
# Ramsey-RESET test:
lmtest::resettest(final_model)
# p-value = 1.833e-10 --> non-linear terms needed
summary(final_model)

# removing the unnecessary vars (based on final_model_bic) and adding non linear terms
# do note that neither retained column contain a seller with no reviews or no active number of listings,


final_model_v2 <- lm(log(Price) ~ Movement + CaseMaterial + BraceletMaterial + 
                       Condition + Gender + CaseShape + 
                       DialFaceArea + Crystal + Clasp + 
                       log(ActiveListingNumSeller+1) + log(SellerNumReviews+1) + 
                       Country + Tier + 
                       Tier * CaseMaterial + I(DialFaceArea^2),
                     data = train_data, weights = 1/FirstPredSqError)
lmtest::resettest(final_model_v2)
summary(final_model_v2)
# adding the following terms: Tier * CaseMaterial, DialFaceArea^2
# the p-value now is up to 1.809e-05


# The marginal effect of dialFaceArea
6.765e-04 - 7.766e-08 * 2 * 800 # = 0.000552244


# however, we need to check whether it is overfit or not
table(train_data$Tier, train_data$CaseMaterial)
# here we observed that the frequency in 1 pair of the two variables is 0.
# also in many cases the frequency for a given combination is too small
# as a result of this, we decided to remove the non-linear term from the model,
# this way we can be sure that there is no overfit




# Reweighting the final models errors with GLS =================================

final_model_no_weights <- lm(log(Price) ~ Movement + CaseMaterial + BraceletMaterial + 
                               Condition + Gender + CaseShape + 
                               DialFaceArea + Crystal + Clasp + 
                               log(ActiveListingNumSeller+1) + log(SellerNumReviews+1) + 
                               Country + Tier,
                             data = train_data)
summary(final_model_no_weights)

train_data$errorFinal <- final_model_no_weights$residuals

## Plot ----
ggplot(train_data, aes(x=log(Price), y=errorFinal^2)) + geom_point()

## Tackling ----
auxFinal <- lm(log(I(errorFinal^2)) ~ Movement + CaseMaterial + BraceletMaterial + 
                 Condition + Gender + CaseShape + 
                 DialFaceArea + Crystal + Clasp + 
                 log(ActiveListingNumSeller+1) + log(SellerNumReviews+1) + 
                 Country + Tier,
               data = train_data)

train_data$FinalPredSqError <- exp(auxFinal$fitted.values)

glsFinal <- lm(log(Price) ~ Movement + CaseMaterial + BraceletMaterial + 
                 Condition + Gender + CaseShape + 
                 DialFaceArea + Crystal + Clasp + 
                 log(ActiveListingNumSeller+1) + log(SellerNumReviews+1) + 
                 Country + Tier,
               data = train_data, weights = 1/FinalPredSqError)

summary(final_model_v2)
summary(glsFinal)

# Evaluation - Actual Price Scale R-Squared=====================================

k <- length(coef(glsFinal)) - 1  

n_train <- nrow(train_data)
n_test <- nrow(test_data)


# Training Data (In-Sample) R-Squared on Actual Price
# Get predictions for the training data
train_data$Predicted_Log_Price <- predict(glsFinal, newdata = train_data)
train_data$Predicted_Price <- exp(train_data$Predicted_Log_Price)

# Calculate standard In-Sample R^2
sse_train <- sum((train_data$Price - train_data$Predicted_Price)^2, na.rm = TRUE)
sst_train <- sum((train_data$Price - mean(train_data$Price, na.rm = TRUE))^2, na.rm = TRUE)
insample_r_squared <- 1 - (sse_train / sst_train)

# Calculate Adjusted In-Sample R^2
adj_insample_r_squared <- 1 - ((1 - insample_r_squared) * (n_train - 1) / (n_train - k - 1))


# Test Data (Out-of-Sample) R-Squared on Actual Price
# Generate predictions on the unseen test data
test_data$Predicted_Log_Price <- predict(glsFinal, newdata = test_data)
test_data$Predicted_Price <- exp(test_data$Predicted_Log_Price)

# Calculate standard Out-of-Sample R^2
sse_test <- sum((test_data$Price - test_data$Predicted_Price)^2, na.rm = TRUE)
sst_test <- sum((test_data$Price - mean(train_data$Price, na.rm = TRUE))^2, na.rm = TRUE)
oos_r_squared <- 1 - (sse_test / sst_test)

# Calculate Adjusted Out-of-Sample R^2
adj_oos_r_squared <- 1 - ((1 - oos_r_squared) * (n_test - 1) / (n_test - k - 1))


# Print Results

print("--- MODEL PERFORMANCE (ACTUAL SCALE) ---")
print(paste("In-Sample R-squared:         ", round(insample_r_squared, 4)))
print(paste("Adjusted In-Sample R-squared:", round(adj_insample_r_squared, 4)))
print("-----------------------------------------------")
print(paste("Out-of-Sample R-squared:         ", round(oos_r_squared, 4)))
print(paste("Adjusted Out-of-Sample R-squared:", round(adj_oos_r_squared, 4)))

# The final equation============================================================

print_percentage_equation <- function(model, default_decimals = 2) {
  coeffs <- na.omit(coef(model))
  
  baseline_price <- exp(coeffs[1])
  equation <- paste0("Price = $", format(round(baseline_price, 2), nsmall = 2, big.mark = ","))
  
  for (i in 2:length(coeffs)) {
    term_name <- names(coeffs)[i]
    raw_coeff <- coeffs[i]
    
    if (grepl("(?i)^log", term_name)) {
      clean_name <- gsub("(?i)(^log_?|\\(|\\)|\\+ ?1)", "", term_name)
      clean_name <- trimws(clean_name)
      
      formatted_coeff <- format(round(raw_coeff, default_decimals + 1), nsmall = default_decimals + 1, scientific = FALSE)
      
      equation <- paste0(equation, "\n        * (", clean_name, " + 1) ^ ", formatted_coeff)
      
    } else {
      pct_change <- (exp(raw_coeff) - 1) * 100
      
      if (round(abs(pct_change), default_decimals) == 0 && abs(pct_change) > 0) {
        val_formatted <- format(signif(abs(pct_change), 2), scientific = FALSE)
      } else {
        val_formatted <- format(round(abs(pct_change), default_decimals), nsmall = default_decimals, scientific = FALSE)
      }
      
      if (pct_change >= 0) {
        pct_string <- paste0("+ ", val_formatted, "%")
      } else {
        pct_string <- paste0("- ", val_formatted, "%")
      }
      
      equation <- paste0(equation, "\n        * (1 ", pct_string, ") ^ ", term_name)
    }
  }
  
  cat("================ Final Equation ================\n\n")
  cat(equation, "\n\n")
  cat("====================================================================\n")
}

print_percentage_equation(glsFinal)

# Watches where the model performed the worst===================================

test_data$Predicted_Price_Dollar <- exp(test_data$Predicted_Log_Price)
test_data$SquaredError_Log <- (log(test_data$Price) - test_data$Predicted_Log_Price)^2
test_data$Dollar_Miss <- test_data$Price - test_data$Predicted_Price_Dollar
worst_predictions <- test_data[order(-test_data$SquaredError_Log), ]

head(worst_predictions[, c("Brand", "Price", "Predicted_Price_Dollar", "Dollar_Miss", "SquaredError_Log", "DialFaceArea", "SellerNumReviews")], 10)

