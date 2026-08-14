# Examining the Secondary Luxury Watch Market: What Defines the Market Price of a Watch?

## Project Overview
This project investigates the decentralized pricing mechanisms of the online secondary watch marketplace. [cite_start]By deploying a multivariate log-linear econometric model, the analysis isolates how brand equity, structural watch specifications, and seller reputation influence final listing valuations[cite: 2, 35]. 

[cite_start]The research utilizes cross-sectional market data from Chrono24 harvested in 2024 via Kaggle[cite: 53]. [cite_start]While the raw dataset spanned over 45,000 unique listings, a rigorous data cleaning pipeline trimmed the framework down to a high-fidelity sample size of **7,416 records** via listwise deletion to ensure robust statistical inference[cite: 53, 57, 58].

---

## Core Hypotheses
* [cite_start]**Brand Prestige & Exclusivity ($H_1$):** Brand prestige and exclusivity command significant, exponential price premiums over mainstream and consumer-level tiers under the *ceteris paribus* assumption[cite: 36].
* **Technical Specifications ($H_2$):** A watch's intrinsic structural specifications, which serve as direct indicators of quality and micromechanical craftsmanship, exert a positive, statistically significant impact on the listing price[cite: 37, 44, 46].
* **Seller Information Asymmetry ($H_3$):** In secondary digital spaces plagued by a lack of universal authentication, signals of dealer trust (e.g., high review counts and massive listing exposure) act as critical trust substitutes and command a measurable price premium[cite: 38, 48, 49].

---

## Data Pipeline & Feature Engineering
[cite_start]The model incorporates a mix of 3 numerical and 11 categorical predictors extracted from an initial set of 24 variables[cite: 54, 242]. The following processing steps were executed programmatically within the R environment:

* [cite_start]**Missing Data Normalization:** Trailing white spaces were stripped, and empty strings (`""`) or pseudo-null text placeholders (`"NA"`) were systematically mapped to official R missing values (`NA`) before applying complete-case operations[cite: 57].
* **Outlier Mitigation:** Extreme data points within the dial surface metric were tightly capped at a maximum of $2500 \text{ mm}^2$ to filter out unrepresentative, unrealistically large anomalies[cite: 83, 84].
* [cite_start]**High-Cardinality Consolidation (Brands):** The raw dataset spanned approximately 300 unique watch brands, rendering standard dummy variable estimation computationally unfeasible and prone to extreme overfitting[cite: 66, 67]. [cite_start]To resolve this, brands were mapped into two newly engineered factors[cite: 68]:
  * **Tier:** A 6-level categorical segment reflecting luxury tier position (*Haute Horlogerie, Luxury, Entry Luxury, Fashion Jewelry, Consumer Enthusiast, and Niche Independent*)[cite: 69].
  * [cite_start]**Country:** A 9-level factor grouping brands by historical geographic manufacturing hubs[cite: 68, 77].
* [cite_start]**Material & Dial Factoring:** High-cardinality nominal variables were collapsed to elevate structural robustness[cite: 238]. [cite_start]`BraceletMaterial` was consolidated from 24 levels down to 7 groups, `Dial` was compressed from 22 levels down to 4 groups, and `CaseMaterial` was condensed into standardized classifications[cite: 77].
* [cite_start]**Logarithmic Transformations:** To stabilize heavily right-skewed economic distributions, a natural log transformation was applied to the dependent variable `Price`[cite: 62, 64]. [cite_start]Skewed numerical predictors—namely `SellerNumReviews`, `SellerNumSales`, `ActiveListingNumSeller`, and `ModelAge`—were similarly log-transformed to mitigate skewness distortion[cite: 81].
* [cite_start]**Age Calculation:** The numeric column `ModelAge` was engineered by anchoring the manufacturing vintage year against the dataset's baseline era of 2024 ($ModelAge = 2024 - Year$) to make the regression intercept directly interpretable[cite: 77].
* **Invariant Variable Removal:** The variable `SellerPunctuality` was omitted entirely from the modeling layout because it only contained a single invariant logic state (`TRUE`).

---

## Econometric Methodology

### 1. Heteroskedasticity Correction via Generalized Least Squares (GLS)
Initial Ordinary Least Squares (OLS) testing revealed severe heteroskedasticity[cite: 90, 92]. As watch values scaled upward into high-horology thresholds, thin data density caused model residuals to expand drastically[cite: 93, 94]. This directly violated the homoskedasticity Gauss-Markov assumption, making OLS standard errors untrustworthy and rendering raw p-values unreliable for significance testing[cite: 95, 96]. 

An Interaction White Test firmly rejected the homoskedastic null hypothesis ($p\text{-value} = 2.65 \times 10^{-40}$)[cite: 106, 110]. To resolve this, **Generalized Least Squares (GLS)** was implemented[cite: 111]. An auxiliary regression mapped log-squared residuals against all predictors, and the main model was reweighted by the inverse of the predicted squared errors ($1/\text{FirstPredSqError}$)[cite: 111]. A subsequent Breusch-Pagan test with Koenker correction yielded a p-value of 1.0, confirming complete stabilization of error variance[cite: 117].

### 2. Multicollinearity Assessment
Calculating the Variance Inflation Factor (VIF) on the baseline model revealed strict collinearity exceeding the predefined threshold of 10 for $\log(SellerNumSales + 1)$ and $\log(SellerNumReviews + 1)$[cite: 121]. To resolve this over-specification, $\log(SellerNumSales + 1)$ was removed from the model[cite: 122]. Correlation tracking confirmed that its underlying proxy variance was cleanly transferred to the highly correlated remaining predictors, `ActiveListingNumSeller` and `SellerNumReviews`, preserving the transactional information layer[cite: 138, 139].

### 3. Stepwise Model Selection
[cite_start]To safeguard against large-sample $p$-value hypersensitivity, two information criteria optimization loops were evaluated[cite: 168]. [cite_start]While backward Akaike Information Criterion (AIC) selection dropped only 3 marginal variables [cite: 128, 129][cite_start], the **Bayesian Information Criterion (BIC)** applied a stricter mathematical penalty for complexity based on sample size[cite: 130]. BIC successfully dropped 7 variables (`ModelAge`, `DeliveryForm`, `Availability`, `WaterResistance`, `FastShipper`, `Dial`, `TrustedSeller`), isolating a clean 13-variable layout that minimizes overfitting and ensures generalized stability[cite: 131, 132].

### 4. Specification Testing
A Ramsey RESET test rejected a purely linear specification ($p\text{-value} = 1.83 \times 10^{-10}$), indicating missing non-linear terms[cite: 144]. Introducing cross-product interaction layers ($Tier \times CaseMaterial$) and a quadratic curve ($\text{DialFaceArea}^2$) raised the RESET test p-value to $1.81 \times 10^{-5}$[cite: 145]. 

However, cross-tabulation exposed several zero-frequency cells and sparse observation pairs across the interaction grid matrix[cite: 149]. Consequently, these non-linear structures were deliberately excluded from the final production pipeline to prioritize model generalizability over localized in-sample fit[cite: 148].

---

## Model Performance & Evaluation
Before fitting the final estimators, the dataset was partitioned into an 80% training set and a 20% validation test set to measure out-of-sample performance[cite: 154].

* [cite_start]**Predictive Capability:** On the actual unlogged price scale, the generalized final model yields an adjusted $R^2$ ranging stably between **35% and 50%**[cite: 160]. [cite_start]Out-of-sample metrics generally tracked within 5% of in-sample statistics, demonstrating strong predictive stability on unseen data[cite: 160].
* **Model Limits:** Performance degradation and extreme variance occur gauges around rare vintage assets, ultra-niche independent manufacturers, and museum-grade collector pieces whose values transcend standardized physical dimensions[cite: 157].
* [cite_start]**Factor Retention Strategy:** Structurally insignificant factor sub-dummies (e.g., `Smartwatch` under the movement variable) were explicitly retained to prevent information loss and preserve the mathematical integrity of sister levels within that categorical group[cite: 162, 164].

---

## Empirical Findings & Interpretations
[cite_start]Holding all other marketplace and material characteristics constant (*ceteris paribus*), back-transforming the log-linear coefficients yields the following insights[cite: 175, 178]:

### The Brand Prestige Premium (Ref: Consumer Enthusiast)
* **Haute Horlogerie:** Captures an astronomical **+2,031.73%** price premium, verifying that the top echelon of watchmaking operates as an elite status symbol[cite: 179].
* [cite_start]**Luxury:** Commands an expected price expansion of **+716.09%**[cite: 182].
* [cite_start]**Fashion & High Jewelry:** Displays a **+193.83%** expected price increase, capturing brand-name markup over raw horological metrics[cite: 181].
* **Entry Luxury & Niche Independents:** Experience almost parallel validation from the secondary market, climbing **+162.65%** and **+163.80%** respectively, indicating that consumers value their brand equity equally[cite: 180].

### Technical Specification Premiums
* [cite_start]**Movement Architecture:** Highlighting mechanical prestige, an **Automatic** movement yields an expected **+89.08%** price premium over standard utility Quartz setups, while **Manual Winding** configurations achieve a **+131.78%** expansion[cite: 186, 205].
* [cite_start]**Material Specification:** Upgrading from standard Mineral Glass to scratch-resistant **Sapphire Crystal** triggers an expected valuation increase of **+80.84%**[cite: 188].

### Marketplace Trust Dynamics
* **Listing Volume Exposure:** A 10% expansion in a dealer's active marketplace listing portfolio is associated with an expected **+0.85%** pricing premium, serving as a proxy signal for verified commercial institutional depth[cite: 192].
* [cite_start]**Review Volume Dispersion:** Conversely, a 10% increase in a seller's raw review volume shifts expected prices downward by **-0.95%**[cite: 193]. [cite_start]This indicates that high review counts map to high-volume, lower-margin commoditized operations rather than elite, low-frequency boutique dealers[cite: 194].

---

## Final Structural Pricing Equation
[cite_start]The log-linear coefficients back-transform into the following multiplicative asset pricing structure[cite: 205]:

$$\widehat{\text{Price}} = \$205.66 \times (1 + 89.08\%)^{\text{MovementAutomatic}} \times (1 + 131.78\%)^{\text{MovementManual winding}} \times (1 - 0.89\%)^{\text{MovementSmartwatch}} \times (1 + 32.17\%)^{\text{MovementSolar}}$$
$$\dots \times (1 + 150.90\%)^{\text{CaseMaterialPrecious\_Metals}} \times (1 + 36.04\%)^{\text{CaseMaterialTwo\_Tone\_Plated}} \times (1 + 34.31\%)^{\text{CaseMaterialAdvanced\_Tech}} \times (1 + 11.77\%)^{\text{CaseMaterialOther}}$$
$$\dots \times (1 + 105.73\%)^{\text{BraceletMaterialPrecious\_Metal}} \times (1 + 6.06\%)^{\text{BraceletMaterialTwo\_Tone\_Plated}} \times (1 + 28.05\%)^{\text{BraceletMaterialExotic\_Leather}}$$
$$\dots \times (1 + 5.00\%)^{\text{BraceletMaterialStandard\_Leather}} \times (1 + 19.68\%)^{\text{BraceletMaterialRubber\_Synthetic}} \times (1 + 23.56\%)^{\text{BraceletMaterialCeramic}}$$
$$\dots \times (1 + 11.77\%)^{\text{ConditionLike new and unworn}} \times (1 - 14.61\%)^{\text{ConditionNew}} \times (1 - 25.77\%)^{\text{ConditionUsed (Fair)}} \times (1 - 16.85\%)^{\text{ConditionUsed (Good)}}$$
$$\dots \times (1 + 9.41\%)^{\text{GenderWomen's watch}} \times (1 - 37.86\%)^{\text{CaseShapeRectangular}} \times (1 + 0.04\%)^{\text{DialFaceArea}}$$
$$\dots \times (1 - 47.32\%)^{\text{CrystalGlass}} \times (1 + 55.06\%)^{\text{CrystalPlastic}} \times (1 + 51.42\%)^{\text{CrystalPlexiglass}} \times (1 + 80.84\%)^{\text{CrystalSapphire crystal}}$$
$$\dots \times (1 + 28.20\%)^{\text{ClaspDouble-fold clasp}} \times (1 + 21.89\%)^{\text{ClaspFold clasp}} \times (1 + 15.53\%)^{\text{ClaspFold clasp, hidden}} \times (1 + 65.31\%)^{\text{ClaspJewelry clasp}}$$
$$\dots \times (1 + 129.29\%)^{\text{ClaspNo clasp}} \times (\text{ActiveListingNumSeller} + 1)^{0.085} \times (\text{SellerNumReviews} + 1)^{-0.095}$$
$$\dots \times (1 + 1.63\%)^{\text{CountryUSA}} \times (1 + 14.08\%)^{\text{CountryFrance}} \times (1 + 57.80\%)^{\text{CountryUK}} \times (1 - 34.85\%)^{\text{CountryItaly}} \times (1 - 15.57\%)^{\text{CountryJapan}}$$
$$\dots \times (1 - 19.50\%)^{\text{CountryRussia\_EasternEurope}} \times (1 - 62.18\%)^{\text{CountryChina}} \times (1 - 4.04\%)^{\text{CountrySwitzerland}}$$
$$\dots \times (1 + 2031.73\%)^{\text{TierHaute\_Horlogerie}} \times (1 + 162.65\%)^{\text{TierEntry\_Luxury}} \times (1 + 193.83\%)^{\text{TierFashion\_Jewelry}} \times (1 + 716.09\%)^{\text{TierLuxury}} \times (1 + 163.80\%)^{\text{TierNiche\_Independent}}$$

---

## [cite_start]Final Regression Coefficients Table [cite: 207]

| Variable | Estimate | Std. Error | t value | Pr(>\|t\|) | Significance |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **(Intercept)** | 5.326e+00 | 7.104e-02 | 74.980 | < 2e-16 | \*\*\* |
| **MovementAutomatic** | 6.370e-01 | 2.543e-02 | 25.053 | < 2e-16 | \*\*\* |
| **MovementManual winding** | 8.406e-01 | 3.696e-02 | 22.742 | < 2e-16 | \*\*\* |
| **MovementSmartwatch** | -8.916e-03 | 6.021e-02 | -0.148 | 0.882287 | |
| **MovementSolar** | 2.789e-01 | 1.362e-01 | 2.047 | 0.040702 | \* |
| **CaseMaterialPrecious\_Metals** | 9.199e-01 | 4.185e-02 | 21.982 | < 2e-16 | \*\*\* |
| **CaseMaterialTwo\_Tone\_Plated** | 3.078e-01 | 8.212e-02 | 3.748 | 0.000180 | \*\*\* |
| **CaseMaterialAdvanced\_Tech** | 2.950e-01 | 4.613e-02 | 6.395 | 1.73e-10 | \*\*\* |
| **CaseMaterialOther** | 1.113e-01 | 7.627e-02 | 1.459 | 0.144491 | |
| **BraceletMaterialPrecious\_Metal** | 7.214e-01 | 7.799e-02 | 9.249 | < 2e-16 | \*\*\* |
| **BraceletMaterialTwo\_Tone\_Plated** | 5.883e-02 | 9.974e-02 | 0.590 | 0.555309 | |
| **BraceletMaterialExotic\_Leather** | 2.473e-01 | 4.196e-02 | 5.893 | 4.01e-09 | \*\*\* |
| **BraceletMaterialStandard\_Leather** | 4.883e-02 | 2.452e-02 | 1.991 | 0.046476 | \* |
| **BraceletMaterialRubber\_Synthetic** | 1.797e-01 | 2.607e-02 | 6.891 | 6.12e-12 | \*\*\* |
| **BraceletMaterialCeramic** | 2.116e-01 | 9.347e-02 | 2.264 | 0.023623 | \* |
| **ConditionLike new & unworn** | 1.113e-01 | 3.164e-02 | 3.517 | 0.000440 | \*\*\* |
| **ConditionNew** | -1.579e-01 | 2.263e-02 | -6.978 | 3.33e-12 | \*\*\* |
| **ConditionUsed (Fair)** | -2.980e-01 | 1.305e-01 | -2.284 | 0.022392 | \* |
| **ConditionUsed (Good)** | -1.845e-01 | 3.995e-02 | -4.618 | 3.96e-06 | \*\*\* |
| **GenderWomen's watch** | 8.993e-02 | 3.702e-02 | 2.429 | 0.015175 | \* |
| **CaseShapeRectangular** | -4.757e-01 | 3.553e-02 | -13.388 | < 2e-16 | \*\*\* |
| **DialFaceArea** | 3.653e-04 | 3.383e-05 | 10.798 | < 2e-16 | \*\*\* |
| **CrystalGlass** | -6.409e-01 | 1.217e-01 | -5.267 | 1.44e-07 | \*\*\* |
| **CrystalPlastic** | 4.387e-01 | 2.440e-01 | 1.798 | 0.072224 | . |
| **CrystalPlexiglass** | 4.149e-01 | 6.607e-02 | 6.279 | 3.64e-10 | \*\*\* |
| **CrystalSapphire crystal** | 5.925e-01 | 3.728e-02 | 15.891 | < 2e-16 | \*\*\* |
| **ClaspDouble-fold clasp** | 2.484e-01 | 3.438e-02 | 7.225 | 5.65e-13 | \*\*\* |
| **ClaspFold clasp** | 1.980e-01 | 2.209e-02 | 8.963 | < 2e-16 | \*\*\* |
| **ClaspFold clasp, hidden** | 1.444e-01 | 6.308e-02 | 2.289 | 0.022129 | \* |
| **ClaspJewelry clasp** | 5.026e-01 | 2.153e-01 | 2.335 | 0.019585 | \* |
| **ClaspNo clasp** | 8.298e-01 | 3.873e-01 | 2.143 | 0.032179 | \* |
| **log(ActiveListingNumSeller + 1)** | 8.456e-02 | 7.892e-03 | 10.714 | < 2e-16 | \*\*\* |
| **log(SellerNumReviews + 1)** | -9.454e-02 | 7.547e-03 | -12.527 | < 2e-16 | \*\*\* |
| **CountryUSA** | 1.617e-02 | 4.440e-02 | 0.364 | 0.715649 | |
| **CountryFrance** | 1.317e-01 | 4.532e-02 | 2.907 | 0.003660 | \*\* |
| **CountryUK** | 4.562e-01 | 1.268e-01 | 3.597 | 0.000324 | \*\*\* |
| **CountryItaly** | -4.284e-01 | 3.454e-02 | -12.403 | < 2e-16 | \*\*\* |
| **CountryJapan** | -1.692e-01 | 4.591e-02 | -3.686 | 0.000230 | \*\*\* |
| **CountryRussia\_EasternEurope** | -2.169e-01 | 7.918e-02 | -2.739 | 0.006184 | \*\* |
| **CountryChina** | -9.724e-01 | 7.440e-02 | -13.069 | < 2e-16 | \*\*\* |
| **CountrySwitzerland** | -4.122e-02 | 2.371e-02 | -1.738 | 0.082234 | . |
| **TierHaute\_Horlogerie** | 3.060e+00 | 5.181e-02 | 59.054 | < 2e-16 | \*\*\* |
| **TierEntry\_Luxury** | 9.656e-01 | 2.843e-02 | 33.970 | < 2e-16 | \*\*\* |
| **TierFashion\_Jewelry** | 1.078e+00 | 6.693e-02 | 16.104 | < 2e-16 | \*\*\* |
| **TierLuxury** | 2.099e+00 | 3.413e-02 | 61.519 | < 2e-16 | \*\*\* |
| **TierNiche\_Independent** | 9.700e-01 | 2.945e-02 | 32.937 | < 2e-16 | \*\*\* |


## References
* Raffaelli, R. (2019). *Technology Reemergence: Creating New Value for Old Technologies in Swiss Mechanical Watchmaking, 1970-2008*. Administrative Science Quarterly, Vol. [cite_start]64(3), 576-618. https://journals.sagepub.com/doi/full/10.1177/0001839218778505 [cite: 245, 246, 247]
* Steele, D. (2026). *Luxury Watches as a Frontier Asset Market: Institutional Depth, Trust Infrastructure, and the Economics of Secondary Exchange*. [cite_start]Watch Schools Working Paper Series (Working Paper No. 1). https://papers.ssrn.com/sol3/papers.cfm?abstract_id=6328658 [cite: 248, 249, 250]

---

## Legal Disclaimer

### 1. Scope, Purpose, and Non-Commerciality
This repository, including all source code, documentation, and attached data files, is intended strictly for educational, research, and personal data science demonstration purposes. This project is entirely non-commercial. It is not designed, intended, or authorized to be used for commercial profit, arbitrage, or to compete with any existing marketplace.

### 2. Fair Use and Limitations on Liability
The analytical scripts and data are provided "as is" without warranty of any kind, either express or implied, including but not limited to the implied warranties of merchantability or fitness for a particular purpose. In no event shall the author(s) or copyright holder(s) be liable for any claim, damages, or other liability arising from, out of, or in connection with the software or the use of the hosted data files.

### 3. Trademark, Ownership, and Non-Affiliation Acknowledgment
All product names, logos, brand names, market prices, and structural data associated with "Chrono24" are trademarks, registered trademarks, or intellectual property of Chrono24 GmbH and its respective partners, manufacturers, or sellers. 
* This repository is a completely independent, third-party project.
* It is **not** sponsored, endorsed, authorized, affiliated, or associated with Chrono24 GmbH in any capacity.

### 4. Data Provenance and System Integrity
The dataset included in this repository was obtained from a publicly accessible, historical archive hosted by a third party on Kaggle. 
* This software does **not** perform live web scraping, automated extraction, or API queries against Chrono24’s infrastructure.
* This project causes zero network traffic or server load to Chrono24’s official website and operates strictly offline.
* No personal identifiable information (PII), private user transaction data, or proprietary source code has been collected, stored, or distributed.

### 5. Intellectual Property Rights and Take-Down Policy (DMCA)
The historical dataset is included in this repository in good faith to ensure reproducibility of the analytical data models. The author does not assert any ownership over the underlying data records. If you are a legal representative of Chrono24 GmbH and object to the hosting of this static copy of historical data, please open an Issue or contact the repository owner directly. The specified files and references will be modified or permanently expunged immediately.
