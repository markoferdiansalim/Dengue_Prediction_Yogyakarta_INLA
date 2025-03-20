# Dengue_Prediction_Yogyakarta_INLA
The dataset consists of monthly dengue case counts and associated environmental, climatic, and sociodemographic covariates for 78 districts in Yogyakarta, Indonesia, from 2017 to 2022.

This repository contains the dataset and supporting materials for the research paper:
"Predicting Spatio-Temporal Dynamics of Dengue Using INLA (Integrated Nested Laplace Approximation) in Yogyakarta, Indonesia".

# Dataset Description
The dataset consists of the following files:
1. Data Files: Dengue_Yogyakarta_INLA.csv - Monthly dengue cases and covariates for 78 districts (2017-2022).
2. shapefiles/ - Spatial boundary files (shapefiles) for the study area.

# Data Availability
The dataset used in this study is not publicly available due to data confidentiality agreements. However, researchers can request access to the full dataset for academic and research purposes. Requests should be directed to the corresponding author with appropriate ethical and institutional approvals.

# Data Variables
The dataset includes the following key variables:
1.	Dengue Incidence (Dependent Variable): The total number of monthly dengue cases per sub-district. Data Source: Surveillance records from Puskesmas and the Health Office of the Special Region of Yogyakarta.
2.	Explanatory Variables (Independent Variables)
2.1. Climatic Variables (Source: NASA POWER)
a.	Rainfall (mm) – Total monthly rainfall.
b.	Rainfall Lag (1, 2, 3 months) – Rainfall in preceding months to account for delayed impacts on mosquito breeding cycles.
c.	Temperature (°C) – Monthly average temperature.
d.	Relative Humidity (%) – Monthly average relative humidity.
e.	Wind Speed (knots) – Monthly average wind speed.
f.	Atmospheric Pressure (hPa) – Monthly average atmospheric pressure.
2.2. Sociodemographic Factors (Source: BPS-Statistics Indonesia)
a.	Population Density (persons/km²) – The total number of residents per square kilometer.
2.3. Environmental Variables (Source: Sentinel-2 Land Cover Explorer)
a.	Built Area (Ha) – The total area covered by human-made structures (urban development).
b.	Crops Area (Ha) – Land designated for agricultural activities.
c.	Trees Area (Ha) – Land dominated by tree cover and forested regions.
d.	Water Area (Ha) – Areas covered by water bodies, including rivers and lakes.
e.	Flooded Vegetation Area (Ha) – Wetlands and periodically inundated landscapes.

# Contact
For questions or collaborations, please contact:
📧 Email: markoferdiansalim@ugm.ac.id
