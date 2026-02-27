import 'package:flutter_test/flutter_test.dart';
import 'package:world_of_cricket/feature/matches_scores/data/model/match.dart';

void main() {
  group('MatchModel Tests', () {
    test('should parse match from JSON correctly', () {
      final json = {
        'id': '123',
        'name': 'India vs Australia',
        'matchType': 'ODI',
        'status': 'Completed',
        'teams': ['India', 'Australia'],
        'dateTimeGMT': '2023-10-01T14:00:00Z',
      };

      final match = MatchModel.fromJson(json);

      expect(match.id, '123');
      expect(match.name, 'India vs Australia');
      expect(match.matchType, 'ODI');
      expect(match.status, 'Completed');
      expect(match.teams, ['India', 'Australia']);
      expect(match.dateTimeGMT, '2023-10-01T14:00:00Z');
    });

    test('should handle missing fields gracefully', () {
      final json = {'id': '123'};

      final match = MatchModel.fromJson(json);

      expect(match.id, '123');
      expect(match.name, 'Unknown Match');
      expect(match.matchType, 'Unknown');
      expect(match.status, 'Unknown');
      expect(match.teams, ['Team 1', 'Team 2']);
      expect(match.dateTimeGMT, '');
    });
  });
}
