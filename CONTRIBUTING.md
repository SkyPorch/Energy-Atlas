# Contributing to Energy Atlas

Thank you for your interest in contributing to Energy Atlas! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs. actual behavior
- visionOS version and device information
- Screenshots or screen recordings if applicable

### Suggesting Features

Feature suggestions are welcome! Please create an issue with:
- A clear description of the feature
- Use cases and benefits
- Any relevant mockups or examples

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the project structure** - place files in appropriate directories
3. **Write clear commit messages** - use conventional commit format
4. **Test your changes** - ensure the app builds and runs correctly
5. **Update documentation** - if you change functionality
6. **Submit a pull request** with a clear description

## Development Guidelines

### Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and concise
- Use SwiftUI best practices

### Project Organization

```
Models/      - Data structures and business logic
Views/       - SwiftUI views and UI components
Services/    - Data services, networking, AI integration
Utilities/   - Helper functions and extensions
Entities/    - RealityKit entities and 3D objects
Resources/   - Data files, audio, and assets
```

### Commit Message Format

Use conventional commits:
```
feat: Add new metric visualization
fix: Correct data loading issue
docs: Update README with new features
style: Format code according to guidelines
refactor: Restructure data store
test: Add unit tests for globe entity
```

### Testing

- Write unit tests for new functionality
- Test on both Vision Pro device and simulator
- Verify performance with large datasets
- Check memory usage and optimize if needed

## Data Contributions

### Adding New Data Sources

1. Ensure data is publicly available and properly licensed
2. Document the source and license in the data file
3. Follow the existing CSV format
4. Update the README with data attribution

### Data Format

CSV files should follow this structure:
- Clear column headers
- Consistent country codes (ISO 3166-1 alpha-3)
- Proper handling of missing values
- Include metadata comments at the top

## Building and Testing

### Prerequisites

```bash
# Ensure you have:
- Xcode 16.0+
- visionOS SDK 2.0+
- Apple Vision Pro or visionOS Simulator
```

### Build Steps

```bash
# Clone your fork
git clone https://github.com/yourusername/EnergyAtlas.git
cd EnergyAtlas

# Open in Xcode
open EnergyAtlas.xcodeproj

# Build and run (Cmd + R)
```

### Running Tests

```bash
# In Xcode: Cmd + U
# Or use xcodebuild
xcodebuild test -scheme EnergyAtlas -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```

## Documentation

- Update README.md for user-facing changes
- Add inline documentation for public APIs
- Update CHANGELOG.md with your changes
- Include code comments for complex logic

## Questions?

If you have questions about contributing:
- Check existing issues and discussions
- Review the documentation in `/docs`
- Open a new issue with the "question" label

## License

By contributing to Energy Atlas, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make Energy Atlas better! 🌍
