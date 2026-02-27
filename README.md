# World of Cricket

A Flutter application that displays live cricket match data using a scrapy automation server.

## Project Structure

### Flutter Application
- **Main App**: `lib/` - Flutter app with Riverpod state management
- **Core Features**: Live matches, upcoming matches, completed matches
- **Data Source**: Local JSON file integration with scrapy server

### Scrapy Automation Server
- **Location**: `scarpy/` directory
- **Purpose**: Scrapes ESPN cricket data using Playwright and cleans with LLM
- **Output**: `cleaned_cricket_data.json`
- **Automation**: `run_automation.bat` and `run_cricket_automation.py`

## Getting Started

### Prerequisites
- Flutter SDK
- Python 3.x (for scrapy server)

### Running the Application
1. **Start the scrapy server** (in `scarpy/` directory):
   ```bash
   python run_cricket_automation.py
   ```

2. **Run the Flutter app**:
   ```bash
   flutter run
   ```

### Data Flow
1. Scrapy server scrapes ESPN cricket data
2. LLM cleans and structures the data
3. Data saved to `cleaned_cricket_data.json`
4. Flutter app reads JSON directly for real-time updates

## Features
- Live cricket matches display
- Upcoming matches with venues and timing
- Completed matches with scores
- Real-time data from ESPN cricket
- AI-enhanced data mapping and cleaning
