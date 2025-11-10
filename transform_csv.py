#!/usr/bin/env python3
"""
Transform World Bank CSV from long format (3 rows per country) to wide format
(1 row per country per year) matching the EnergyVisualizer2 format.

Input: 7874c0cb-c71e-4ae9-90c8-a384cb42c518_Data.csv (World Bank format)
Output: energy_data_multi_year.csv (EnergyVisualizer2 format with Year column)
"""

import csv
import sys
from collections import defaultdict

def transform_world_bank_csv(input_path, output_path):
    """Transform World Bank CSV to EnergyVisualizer2 multi-year format."""
    
    print(f"Reading {input_path}...")
    
    # Define the three metrics we need
    METRICS = {
        'Electric power consumption (kWh per capita)': 'Electric Power Consumption (kWh per capita)',
        'Energy use (kg of oil equivalent per capita)': 'Energy Use (kg oil equivalent per capita)',
        'Total greenhouse gas emissions including LULUCF (Mt CO2e)': 'Greenhouse Gas Emissions (Mt CO2e)'
    }
    
    # Read the CSV
    with open(input_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        headers = reader.fieldnames
    
    # Extract year columns (format: "2005 [YR2005]", "2006 [YR2006]", etc.)
    year_columns = [col for col in headers if col.startswith('20') and '[YR' in col]
    years = [int(col.split()[0]) for col in year_columns]
    
    print(f"Found {len(years)} years: {min(years)} to {max(years)}")
    
    # Group rows by country
    country_data = defaultdict(list)
    for row in rows:
        country_name = row['Country Name']
        country_data[country_name].append(row)
    
    print(f"Found {len(country_data)} countries")
    
    # Build output rows
    output_rows = []
    countries_with_data = 0
    
    for country_name, country_rows in sorted(country_data.items()):
        # Get the three metric rows for this country
        metric_rows = {}
        country_code = None
        
        for row in country_rows:
            series_name = row['Series Name']
            if series_name in METRICS:
                metric_rows[series_name] = row
                if country_code is None:
                    country_code = row['Country Code']
        
        # Skip countries that don't have all three metrics
        if len(metric_rows) != 3:
            continue
        
        # For each year, create a row if all three metrics have valid data
        country_has_any_data = False
        for year_col, year in zip(year_columns, years):
            # Extract values for each metric
            power_val = metric_rows['Electric power consumption (kWh per capita)'][year_col]
            energy_val = metric_rows['Energy use (kg of oil equivalent per capita)'][year_col]
            ghg_val = metric_rows['Total greenhouse gas emissions including LULUCF (Mt CO2e)'][year_col]
            
            # Skip if any value is missing (represented as '..')
            if power_val == '..' or energy_val == '..' or ghg_val == '..':
                continue
            
            # Try to convert to float, skip if conversion fails
            try:
                power_float = float(power_val)
                energy_float = float(energy_val)
                ghg_float = float(ghg_val)
            except (ValueError, TypeError):
                continue
            
            # Create output row
            output_rows.append({
                'Country Name': country_name,
                'Country Code': country_code,
                'Year': year,
                'Electric Power Consumption (kWh per capita)': power_float,
                'Energy Use (kg oil equivalent per capita)': energy_float,
                'Greenhouse Gas Emissions (Mt CO2e)': ghg_float
            })
            country_has_any_data = True
        
        if country_has_any_data:
            countries_with_data += 1
    
    print(f"\nTransformation complete:")
    print(f"  - Countries with data: {countries_with_data}")
    print(f"  - Total rows: {len(output_rows)}")
    if output_rows:
        all_years = [row['Year'] for row in output_rows]
        print(f"  - Years covered: {min(all_years)} to {max(all_years)}")
    
    # Show sample of data
    print(f"\nSample data (first 10 rows):")
    for i, row in enumerate(output_rows[:10]):
        if i == 0:
            print(f"  {row['Country Name']}, {row['Year']}: Power={row['Electric Power Consumption (kWh per capita)']:.2f}")
        else:
            print(f"  {row['Country Name']}, {row['Year']}: Power={row['Electric Power Consumption (kWh per capita)']:.2f}")
    
    # Save to CSV
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['Country Name', 'Country Code', 'Year', 
                     'Electric Power Consumption (kWh per capita)',
                     'Energy Use (kg oil equivalent per capita)',
                     'Greenhouse Gas Emissions (Mt CO2e)']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output_rows)
    
    print(f"\nSaved to: {output_path}")
    
    # Show statistics per year
    print(f"\nCountries per year:")
    year_counts = defaultdict(int)
    for row in output_rows:
        year_counts[row['Year']] += 1
    
    for year in sorted(year_counts.keys()):
        print(f"  {year}: {year_counts[year]} countries")

if __name__ == "__main__":
    input_file = "/Users/luisgoicouria/Downloads/P_Data_Extract_From_World_Development_Indicators-2/7874c0cb-c71e-4ae9-90c8-a384cb42c518_Data.csv"
    output_file = "/Users/luisgoicouria/Desktop/Spatial Plot/EnergyVisualizer2/EnergyVisualizer2/energy_data_multi_year.csv"
    
    try:
        transform_world_bank_csv(input_file, output_file)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
