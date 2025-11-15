# Energy Atlas

An immersive visionOS application for visualizing and exploring global energy consumption data in 3D space. Available on the App Store [here](https://apps.apple.com/us/app/energy-atlas/id6754099363).

![visionOS](https://img.shields.io/badge/visionOS-2.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Overview

Energy Atlas transforms complex global energy data into an intuitive, spatial computing experience. Explore energy consumption patterns, greenhouse gas emissions, and power usage across countries and years through an interactive 3D globe visualization.

## Features

- 🌍 **Interactive 3D Globe** - Visualize country-level energy data on a realistic Earth model
- 📊 **Multiple Metrics** - Track electric power consumption, energy use, and GHG emissions
- 📅 **Historical Data** - Explore trends from 2005 to 2022
- 🎯 **Spatial UI** - Native visionOS interface with volumetric windows
- 🤖 **AI Analysis** - Get insights powered by Apple Intelligence (visionOS 2.6+)
- 🎨 **Quintile Visualization** - Color-coded data representation for easy comparison
- 🔊 **Spatial Audio** - Immersive ambient soundscape

## Requirements

- **Device**: Apple Vision Pro
- **OS**: visionOS 2.0 or later
- **Xcode**: 16.0 or later
- **Swift**: 5.9 or later

## Installation

### Clone the Repository

```bash
git clone https://github.com/SkyPorch/Energy-Atlas.git
cd EnergyAtlas
```

### Open in Xcode

```bash
open EnergyAtlas.xcodeproj
```

### Build and Run

1. Select your target device (Vision Pro or visionOS Simulator)
2. Press `Cmd + R` to build and run
3. Grant necessary permissions when prompted

## Project Structure

```
EnergyAtlas/
├── EnergyAtlas/
│   ├── Models/              # Data models
│   ├── Views/               # SwiftUI views
│   ├── Services/            # Data services and AI integration
│   ├── Utilities/           # Helper utilities
│   ├── Entities/            # RealityKit entities
│   ├── Resources/           # Data files and audio assets
│   └── EnergyAtlasApp.swift # Main app entry point
├── Packages/
│   └── RealityKitContent/   # 3D assets and Reality Composer content
└── EnergyAtlasTests/        # Unit tests
```

## Data Sources

Energy data is sourced from publicly available datasets including:
- World Bank Open Data
- International Energy Agency (IEA)
- Country centroid coordinates

All data files are located in `EnergyAtlas/Resources/Data/`.

## Usage

### Basic Navigation

1. **Launch the app** - Start with the intro experience
2. **Enter immersive mode** - Tap "Enter Energy Atlas" to view the 3D globe
3. **Select metrics** - Use the carousel to switch between energy metrics
4. **Choose year** - Adjust the slider to explore different time periods
5. **Select countries** - Tap countries on the globe or use the picker
6. **View charts** - Toggle the 3D chart panel for detailed visualizations

### AI Analysis (visionOS 2.6+)

The AI panel provides intelligent insights about energy trends:
- Compare countries
- Identify patterns
- Get contextual explanations
- Explore correlations

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Known Issues

- AI Analysis requires visionOS 2.6 or later
- Large audio files may increase initial download size
- Some countries may have incomplete data for certain years

## Roadmap

- [ ] Additional data sources and metrics
- [ ] Export and sharing capabilities
- [ ] Multi-user collaboration features
- [ ] Enhanced data filtering options
- [ ] Performance optimizations for larger datasets

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Energy data providers and open data initiatives
- Apple's visionOS development team
- RealityKit and SwiftUI frameworks
- The open-source community

## Support

For questions, issues, or feature requests:
- Open an issue on GitHub
- Check existing documentation in `/docs`

---

**Built with ❤️ for Apple Vision Pro**
