#!/usr/bin/env python3
"""
Filter energy_data_multi_year.csv to only include countries that have
coordinates in country_centroids.csv
"""

import csv
import sys

def load_centroid_countries(centroids_path):
    """Load the set of country names from the centroids CSV."""
    countries = set()
    with open(centroids_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            country_name = row['COUNTRY']
            countries.add(country_name)
    return countries

def filter_energy_data(energy_path, centroids_path, output_path):
    """Filter energy data to only include countries with centroids."""
    
    print(f"Loading countries from {centroids_path}...")
    centroid_countries = load_centroid_countries(centroids_path)
    print(f"Found {len(centroid_countries)} countries with coordinates")
    
    print(f"\nReading energy data from {energy_path}...")
    with open(energy_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        all_rows = list(reader)
        fieldnames = reader.fieldnames
    
    print(f"Total rows in energy data: {len(all_rows)}")
    
    # Filter rows to only include countries with centroids
    filtered_rows = []
    countries_in_energy = set()
    countries_matched = set()
    countries_unmatched = set()
    
    for row in all_rows:
        country_name = row['Country Name']
        countries_in_energy.add(country_name)
        
        if country_name in centroid_countries:
            filtered_rows.append(row)
            countries_matched.add(country_name)
        else:
            countries_unmatched.add(country_name)
    
    # Write filtered data
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(filtered_rows)
    
    print(f"\n=== FILTERING RESULTS ===")
    print(f"Countries in energy data: {len(countries_in_energy)}")
    print(f"Countries matched with centroids: {len(countries_matched)}")
    print(f"Countries excluded (no centroids): {len(countries_unmatched)}")
    print(f"Rows after filtering: {len(filtered_rows)}")
    print(f"\nSaved to: {output_path}")
    
    # Show which countries were excluded
    if countries_unmatched:
        print(f"\n=== EXCLUDED COUNTRIES (no centroids) ===")
        for country in sorted(countries_unmatched):
            print(f"  - {country}")
    
    # Show year distribution
    print(f"\n=== YEAR DISTRIBUTION ===")
    from collections import defaultdict
    year_counts = defaultdict(int)
    for row in filtered_rows:
        year_counts[int(row['Year'])] += 1
    
    for year in sorted(year_counts.keys()):
        print(f"  {year}: {year_counts[year]} countries")
    
    # Show sample countries that were kept
    print(f"\n=== SAMPLE MATCHED COUNTRIES ===")
    for country in sorted(list(countries_matched)[:10]):
        print(f"  ✓ {country}")
    if len(countries_matched) > 10:
        print(f"  ... and {len(countries_matched) - 10} more")

if __name__ == "__main__":
    centroids_file = "/Users/luisgoicouria/Desktop/Spatial Plot/EnergyVisualizer2/EnergyVisualizer2/country_centroids.csv"
    energy_file = "/Users/luisgoicouria/Desktop/Spatial Plot/EnergyVisualizer2/EnergyVisualizer2/energy_data_multi_year.csv"
    output_file = "/Users/luisgoicouria/Desktop/Spatial Plot/EnergyVisualizer2/EnergyVisualizer2/energy_data_multi_year_filtered.csv"
    
    try:
        filter_energy_data(energy_file, centroids_file, output_file)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
