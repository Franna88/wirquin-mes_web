# Wirquin CMMS

A Flutter web application for OEE (Overall Equipment Effectiveness) tracking and CMMS (Computerized Maintenance Management System).

## Features

- **Dashboard**: Track and visualize Overall Equipment Effectiveness metrics (Availability, Performance, Quality)
- **Maintenance Management**: Schedule and track maintenance activities
- **Excel Import/Export**: Import data from Excel files and export reports
- **Responsive Web Interface**: Works on desktop and mobile browsers

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Web browser (Chrome recommended for development)

### Installation

1. Clone this repository
2. Navigate to the project folder
3. Run the following commands:

```bash
flutter pub get
flutter run -d chrome
```

## Usage

### Importing Excel Data

The system supports importing maintenance and OEE data from Excel files. Your Excel file should follow this format:

#### Maintenance Sheet:
- Equipment ID
- Description
- Location
- Status
- Last Maintenance Date
- Next Maintenance Date
- Maintenance Type
- Responsible
- Notes

#### OEE Sheet:
- Date
- Equipment ID
- Availability (%)
- Performance (%)
- Quality (%)
- OEE (%) (Optional - will be calculated if not provided)
- Notes

## Development

### Project Structure

- `lib/`: Main source code directory
  - `main.dart`: Application entry point
  - `screens/`: UI screens
  - `providers/`: State management
  - `utils/`: Utility functions and helpers
- `assets/`: Static assets (images, fonts, etc.)
- `web/`: Web-specific files

### Adding New Features

1. Create new providers in the `providers/` directory for state management
2. Add UI components in the `screens/` or `widgets/` directories
3. Update routes in `main.dart` if adding new screens

## License

This project is proprietary and confidential.

## Contact

For support or inquiries, please contact:
[Your Contact Information]
