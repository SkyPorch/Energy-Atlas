#!/usr/bin/env python3
"""
Compare the original 2020 dataset with the filtered multi-year dataset
to see which countries differ.
"""

import csv

def get_countries_from_csv(filepath, country_column='Country Name', year_filter=None):
    """Extract set of country names from a CSV file."""
    countries = set()
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if year_filter is None or row.get('Year') == str(year_filter):
                countries.add(row[country_column])
    return countries

# Load countries from both datasets
original_countries = get_countries_from_csv(
    '/Users/luisgoicouria/Desktop/Spatial Plot/EnergyVisualizer2/EnergyVisualizer2/energy_data_reorganized_2020_complete_only.csv'
)

filtered_2020_countries = get_countries_from_csv(
    '/Users/luisgoicouria/Desktop/Spatial Plot/EnergyVisualizer2/EnergyVisualizer2/energy_data_multi_year_filtered.csv',
    year_filter=2020
)

print(f"Countries in original 2020 dataset: {len(original_countries)}")
print(f"Countries in filtered 2020 dataset: {len(filtered_2020_countries)}")

# Find differences
in_original_not_filtered = original_countries - filtered_2020_countries
in_filtered_not_original = filtered_2020_countries - original_countries

if in_original_not_filtered:
    print(f"\n=== Countries in ORIGINAL but NOT in FILTERED ({len(in_original_not_filtered)}) ===")
    for country in sorted(in_original_not_filtered):
        print(f"  - {country}")

if in_filtered_not_original:
    print(f"\n=== Countries in FILTERED but NOT in ORIGINAL ({len(in_filtered_not_original)}) ===")
    for country in sorted(in_filtered_not_original):
        print(f"  + {country}")

if not in_original_not_filtered and not in_filtered_not_original:
    print("\n✓ Both datasets have exactly the same countries!")
else:
    print(f"\n=== SUMMARY ===")
    print(f"Common countries: {len(original_countries & filtered_2020_countries)}")
    print(f"Only in original: {len(in_original_not_filtered)}")
    print(f"Only in filtered: {len(in_filtered_not_original)}")
