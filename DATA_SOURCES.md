# Data Sources

This document describes the data sources used in Energy Atlas and their licensing.

## Energy Data

### Primary Dataset: `energy_data_multi_year_filtered.csv`

**Source**: World Bank Open Data  
**Metrics Included**:
- Electric Power Consumption (kWh per capita)
- Energy Use (kg of oil equivalent per capita)
- Greenhouse Gas Emissions (Mt CO2e)

**Time Period**: 2005-2022  
**Coverage**: 100+ countries with complete data

**License**: Creative Commons Attribution 4.0 (CC BY 4.0)  
**Attribution**: World Bank Open Data (https://data.worldbank.org/)

### Country Averages: `country_averages_2005_2022.csv`

Aggregated statistics computed from the primary dataset for quick reference and comparison.

### Historical Dataset: `energy_data_multi_year.csv`

Extended dataset including countries with partial data coverage.

## Geographic Data

### Country Centroids: `country_centroids.csv`

**Source**: Natural Earth Data  
**Content**: Latitude and longitude coordinates for country centroids  
**License**: Public Domain

**Fields**:
- Country Name
- ISO 3166-1 alpha-3 Country Code
- Latitude (decimal degrees)
- Longitude (decimal degrees)

## Data Processing

Data processing scripts are included in the repository:
- `transform_csv.py` - Data transformation and cleaning
- `filter_by_centroids.py` - Geographic data filtering
- `compare_datasets.py` - Dataset validation and comparison

## Data Quality Notes

1. **Missing Data**: Some countries may have incomplete data for certain years or metrics
2. **Data Updates**: Energy data is typically released with a 1-2 year lag
3. **Country Coverage**: Focus on countries with reliable, consistent reporting
4. **Methodology**: Follows World Bank and IEA standard definitions

## Using the Data

All data files are located in `EnergyAtlas/Resources/Data/` and are loaded at runtime by the `EnergyDataStore` service.

### Data Format

CSV files follow this structure:
```csv
Country,CountryCode,Year,Metric1,Metric2,Metric3,Latitude,Longitude
```

### Adding New Data

To add new data sources:
1. Ensure data is publicly available and properly licensed
2. Follow the existing CSV format
3. Update this documentation with source attribution
4. Test data loading in the app

## License Compliance

By using Energy Atlas, you agree to comply with the data source licenses:
- Provide proper attribution when sharing visualizations
- Do not misrepresent the data or its sources
- Follow CC BY 4.0 terms for World Bank data

## Data Updates

To update the datasets:
1. Download latest data from World Bank Open Data
2. Run processing scripts to transform format
3. Validate against existing data structure
4. Test in the application
5. Update this documentation with new date ranges

## Contact

For questions about data sources or to report data issues, please open an issue on GitHub.

---

**Last Updated**: November 2025
