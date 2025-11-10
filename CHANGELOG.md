# Changelog

All notable changes to Energy Atlas will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-10

### Initial Release

#### Added
- Interactive 3D globe visualization with country-level energy data
- Support for multiple energy metrics:
  - Electric Power Consumption (kWh per capita)
  - Energy Use (kg of oil equivalent per capita)
  - Greenhouse Gas Emissions (Mt CO2e)
- Historical data exploration (2005-2022)
- Quintile-based color coding for data comparison
- Volumetric 3D chart panel for detailed country statistics
- Control panel with year slider and country picker
- Metric carousel for easy switching between data types
- AI-powered analysis panel (visionOS 2.6+)
- Immersive spatial audio experience
- Intro sequence with ambient music
- TipKit integration for user guidance
- Asset preloading system for smooth performance
- Country info panel with detailed statistics

#### Data
- World Bank energy consumption data (2005-2022)
- Country centroid coordinates for globe positioning
- Multi-year energy dataset with 100+ countries

#### Technical
- Built with SwiftUI and RealityKit
- Native visionOS 2.0+ support
- Mixed immersion mode for room-scale visualization
- Organized project structure (Models, Views, Services, Utilities, Entities)
- Comprehensive data store with CSV parsing
- Spatial audio integration
- Performance-optimized asset loading

---

## Future Releases

See [Roadmap](README.md#roadmap) for planned features.
