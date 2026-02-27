import 'package:flutter_test/flutter_test.dart';
import 'package:world_of_cricket/core/models/cricket_models.dart';

void main() {
  test('CricketMatch.fromCricketDataOrg handles NA status correctly', () {
    final json = {
      'id': '123',
      'name': 'Test Match',
      'status': 'NA',
      'teams': ['Team A', 'Team B'],
      'dateTimeGMT': '2023-10-27T10:00:00',
    };

    final match = CricketMatch.fromCricketDataOrg(json);

    print('Status: ${match.status}');
    print('Live Status: ${match.liveStatus}');

    expect(match.status, 'NA');
    expect(match.liveStatus, 'unknown'); // Should now be unknown, not live
  });

  test('CricketDataOrgResponse filters out NA matches', () {
    final matchJson1 = {
      'id': '123',
      'name': 'Valid Match',
      'status': 'Live',
      'teams': ['Team A', 'Team B'],
    };
    final matchJson2 = {
      'id': '124',
      'name': 'Invalid Match',
      'status': 'NA',
      'teams': ['Team C', 'Team D'],
    };

    final responseJson = {
      'apikey': 'test-key',
      'data': [matchJson1, matchJson2],
      'status': 'success',
    };

    final response = CricketDataOrgResponse.fromJson(responseJson);
    final apiResponse = response.toCricketApiResponse();

    print('Total matches: ${response.data.length}');
    print('Filtered matches: ${apiResponse.data.length}');

    expect(response.data.length, 2); // Initial parsing includes all
    expect(apiResponse.data.length, 1); // Conversion filters out NA
    expect(apiResponse.data.first.title, 'Valid Match');
  });
}
