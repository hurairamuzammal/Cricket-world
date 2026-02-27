import 'package:flutter_test/flutter_test.dart';
import 'package:world_of_cricket/core/services/local_cricket_data_service.dart';

void main() {
  group('Local Cricket Data Service Tests', () {
    late LocalCricketDataService service;

    setUp(() {
      service = LocalCricketDataService();
    });

    test('should load matches successfully', () async {
      // Act
      final response = await service.getAllMatches();

      // Assert
      expect(response.success, isTrue);
      expect(response.data, isNotEmpty);
      expect(response.meta, isNotNull);
      expect(response.meta!.apiVersion, equals('Local-1.0'));

      print('Loaded ${response.data.length} matches');
      for (final match in response.data.take(2)) {
        print('Match: ${match.title} - Status: ${match.liveStatus}');
      }
    });

    test('should filter live matches correctly', () async {
      // Act
      final response = await service.getLiveMatches();

      // Assert
      expect(response.success, isTrue);
      expect(response.meta!.filterType, equals('live'));

      // All returned matches should have live status
      for (final match in response.data) {
        expect(match.liveStatus, equals('live'));
      }

      print('Found ${response.data.length} live matches');
    });

    test('should filter upcoming matches correctly', () async {
      // Act
      final response = await service.getUpcomingMatches();

      // Assert
      expect(response.success, isTrue);
      expect(response.meta!.filterType, equals('upcoming'));

      // All returned matches should have upcoming status
      for (final match in response.data) {
        expect(match.liveStatus, equals('upcoming'));
      }

      print('Found ${response.data.length} upcoming matches');
    });

    test('should get health status', () async {
      // Act
      final health = await service.getHealthStatus();

      // Assert
      expect(health['status'], equals('healthy'));
      expect(health['data_source'], equals('Local JSON File'));
      expect(health.containsKey('file_exists'), isTrue);
      expect(health.containsKey('cached_matches'), isTrue);

      print('Health status: ${health['status']}');
      print('File exists: ${health['file_exists']}');
      print('Cached matches: ${health['cached_matches']}');
    });

    test('should get API statistics', () async {
      // Act
      final stats = await service.getApiStatistics();

      // Assert
      expect(stats.overview.totalMatches, greaterThanOrEqualTo(0));
      expect(stats.features['local_data'], isTrue);
      expect(stats.features['scrapy_integration'], isTrue);
      expect(stats.features['llm_cleaned'], isTrue);

      print('Total matches: ${stats.overview.totalMatches}');
      print('Live matches: ${stats.overview.liveMatches}');
      print('Completed matches: ${stats.overview.completedMatches}');
      print('Upcoming matches: ${stats.overview.upcomingMatches}');
    });

    test('should handle team filtering', () async {
      // Act
      final response = await service.getTeamMatches('India');

      // Assert
      expect(response.success, isTrue);
      expect(response.meta!.filterType, contains('team:'));

      print('Found ${response.data.length} matches for India');
    });

    test('should handle match details retrieval', () async {
      // First get all matches to get a valid ID
      final allMatches = await service.getAllMatches();

      if (allMatches.data.isNotEmpty) {
        final firstMatchId = allMatches.data.first.id;

        // Act
        final match = await service.getMatchDetails(firstMatchId);

        // Assert
        expect(match.id, equals(firstMatchId));
        expect(match.source, equals('ESPNCricinfo Scrapy'));

        print('Retrieved match details for: ${match.title}');
      }
    });

    test('should validate data structure', () async {
      // Act
      final response = await service.getAllMatches();

      // Assert
      expect(response.success, isTrue);

      for (final match in response.data.take(3)) {
        // Validate required fields
        expect(match.id, isNotEmpty);
        expect(match.source, equals('ESPNCricinfo Scrapy'));
        expect(
          match.liveStatus,
          isIn(['live', 'completed', 'upcoming', 'unknown']),
        );

        // Validate teams
        expect(match.teams.length, lessThanOrEqualTo(2));

        print('✓ Match ${match.id} validated');
        print('  Title: ${match.title}');
        print('  Teams: ${match.teams.map((t) => t.name).join(' vs ')}');
        print('  Status: ${match.liveStatus}');
        print('  Series: ${match.series}');
      }
    });
  });
}
