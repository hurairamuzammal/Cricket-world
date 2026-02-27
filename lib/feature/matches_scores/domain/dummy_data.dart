import 'package:world_of_cricket/feature/matches_scores/domain/entities/match_entity.dart';

List<MatchEntity> dummyMatches = [
  // MatchEntity(
  //   id: '', name: '', matchType: '', teams: [], status: '', dateTimeGMT: ''),
  MatchEntity(
    id: '1',
    name: 'India vs Australia',
    matchType: 'ODI',
    teams: ['India', 'Australia'],
    status: 'Completed',
    dateTimeGMT: '2023-10-01T14:00:00Z',
  ),
  MatchEntity(
    id: '2',
    name: 'Pakistan vs England',
    matchType: 'T20',
    teams: ['Pakistan', 'England'],
    status: 'Upcoming',
    dateTimeGMT: '2023-10-05T16:00:00Z',
  ),
  MatchEntity(
    id: '3',
    name: 'South Africa vs New Zealand',
    matchType: 'Test',
    teams: ['South Africa', 'New Zealand'],
    status: 'In Progress',
    dateTimeGMT: '2023-10-03T10:00:00Z',
  ),
  MatchEntity(
    id: '4',
    name: 'West Indies vs Sri Lanka',
    matchType: 'ODI',
    teams: ['West Indies', 'Sri Lanka'],
    status: 'Completed',
    dateTimeGMT: '2023-10-02T18:00:00Z',
  ),
  MatchEntity(
    id: '5',
    name: 'Bangladesh vs Afghanistan',
    matchType: 'T20',
    teams: ['Bangladesh', 'Afghanistan'],
    status: 'Upcoming',
    dateTimeGMT: '2023-10-06T12:00:00Z',
  ),
  MatchEntity(
    id: '6',
    name: 'India vs Pakistan',
    matchType: 'ODI',
    teams: ['India', 'Pakistan'],
    status: 'Completed',
    dateTimeGMT: '2023-10-04T14:00:00Z',
  ),
  MatchEntity(
    id: '7',
    name: 'Australia vs South Africa',
    matchType: 'Test',
    teams: ['Australia', 'South Africa'],
    status: 'In Progress',
    dateTimeGMT: '2023-10-07T10:00:00Z',
  ),
];



// enum and flags
// 🇵🇰 Pakistan
// 🇮🇳 India 
// 🇦🇺 Australia