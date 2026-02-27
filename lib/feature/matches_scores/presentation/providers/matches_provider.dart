import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/source/data_source.dart';
import '../../data/repository/match_repository_Impl.dart';
import '../../data/model/cricket_api_models.dart';
import '../../domain/repository/match_repository.dart';
import '../../domain/usecase/get_all_matches.dart';
import '../../domain/usecase/get_detailed_live_scores.dart';
import '../../domain/usecase/get_completed_matches.dart';
import '../../domain/usecase/get_match_result.dart';
import '../../domain/entities/match_entity.dart';
import '../../domain/entities/enhanced_match_entities.dart';
import '../../../../core/services/local_cricket_data_service.dart';

// ========================================
// UPDATED TO USE LOCAL CRICKET SERVER
// Data source: cleaned_cricket_data.json via cricket_server.py (localhost:8000)
// ========================================

// Provider for HTTP client
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// Provider for local cricket data service (fallback)
final localCricketDataServiceProvider = Provider<LocalCricketDataService>((
  ref,
) {
  return LocalCricketDataService();
});

// Provider for cricket data source (NOW USES LOCAL SERVER - localhost:8000)
final cricketDataSourceProvider = Provider<MatchRemoteDataSource>((ref) {
  print('🏗️ Provider: Initializing LOCAL cricket server data source');
  return MatchRemoteDataSource(client: ref.watch(httpClientProvider));
});

// Provider for match repository (NOW USES LOCAL SERVER)
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  print('🏗️ Provider: Initializing match repository with LOCAL server');
  return MatchRepositoryImpl(dataSource: ref.watch(cricketDataSourceProvider));
});

// Provider for get all matches use case
final getAllMatchesUseCaseProvider = Provider<GetAllMatches>((ref) {
  return GetAllMatches(ref.watch(matchRepositoryProvider));
});

// Provider for get detailed live scores use case
final getDetailedLiveScoresUseCaseProvider = Provider<GetDetailedLiveScores>((
  ref,
) {
  return GetDetailedLiveScores(ref.watch(matchRepositoryProvider));
});

// Provider for get completed matches use case
final getCompletedMatchesUseCaseProvider = Provider<GetCompletedMatches>((ref) {
  return GetCompletedMatches(ref.watch(matchRepositoryProvider));
});

// Provider for get match result use case
final getMatchResultUseCaseProvider = Provider<GetMatchResult>((ref) {
  return GetMatchResult(ref.watch(matchRepositoryProvider));
});

// ========================================
// HELPER FUNCTIONS
// ========================================

/// Helper function to extract live score from cricket match
String? _extractLiveScore(dynamic cricketMatch) {
  if (cricketMatch.teams != null && cricketMatch.teams.isNotEmpty) {
    final scores = <String>[];
    for (var team in cricketMatch.teams) {
      if (team.score != null && team.score.isNotEmpty) {
        final teamScore = '${team.name}: ${team.score}';
        if (team.overs != null && team.overs.isNotEmpty) {
          scores.add('$teamScore (${team.overs} ov)');
        } else {
          scores.add(teamScore);
        }
      }
    }
    return scores.isNotEmpty ? scores.join(' | ') : null;
  }
  return null;
}

// ========================================
// MAIN PROVIDERS - NOW USING LOCAL SERVER DATA
// Primary: localhost:8000 (cricket_server.py)
// Fallback: LocalCricketDataService (direct JSON file access)
// ========================================

/// Provider for ALL matches from LOCAL cricket server
/// Primary: Fetches from localhost:8000/api/v1/matches
/// Fallback: Uses local JSON file via LocalCricketDataService
final matchesProvider = FutureProvider<List<MatchEntity>>((ref) async {
  print('🔄 Provider: matchesProvider called - fetching ALL matches');
  
  try {
    // PRIMARY: Try LOCAL server API first
    print('📡 Attempting to fetch from LOCAL server (localhost:8000)...');
    final useCase = ref.watch(getAllMatchesUseCaseProvider);
    final matches = await useCase.call();
    
    if (matches.isNotEmpty) {
      print('✅ Successfully loaded ${matches.length} matches from LOCAL server');
      return matches;
    } else {
      print('⚠️ LOCAL server returned empty results');
    }
  } catch (e) {
    print('❌ LOCAL server failed: $e');
    print('🔄 Falling back to direct JSON file access...');
  }

  // FALLBACK: Use local JSON file service
  try {
    final localService = ref.watch(localCricketDataServiceProvider);
    final response = await localService.getAllMatches();
    
    if (response.success && response.data.isNotEmpty) {
      print('✅ Loaded ${response.data.length} matches from local JSON file');
      return response.data.map((cricketMatch) {
        return MatchEntity(
          id: cricketMatch.id,
          name: cricketMatch.title,
          status: cricketMatch.status,
          dateTimeGMT: cricketMatch.lastUpdated,
          matchType: cricketMatch.matchType,
          teams: cricketMatch.teams.map((team) => team.name).toList(),
          venue: cricketMatch.venue,
          series: cricketMatch.series,
          liveScore: _extractLiveScore(cricketMatch),
        );
      }).toList();
    } else {
      print('⚠️ Local JSON file service failed: ${response.error}');
    }
  } catch (e) {
    print('❌ Fallback local service error: $e');
  }

  print('❌ All data sources failed, returning empty list');
  return [];
});

/// Provider for LIVE matches from LOCAL cricket server
/// Primary: Fetches from localhost:8000/api/v1/matches/live
/// Fallback: Filters local JSON file for live matches
final liveMatchesProvider = FutureProvider<List<MatchEntity>>((ref) async {
  print('🔴 Provider: liveMatchesProvider called - fetching LIVE matches');
  
  try {
    // PRIMARY: Try LOCAL server API first
    print('📡 Attempting to fetch LIVE matches from LOCAL server...');
    final dataSource = ref.watch(cricketDataSourceProvider);
    final models = await dataSource.fetchLiveMatches();
    
    if (models.isNotEmpty) {
      print('✅ Successfully loaded ${models.length} LIVE matches from LOCAL server');
      return models.map((model) => MatchEntity.fromModel(model)).toList();
    } else {
      print('⚠️ LOCAL server returned no LIVE matches');
    }
  } catch (e) {
    print('❌ LOCAL server LIVE matches failed: $e');
    print('🔄 Falling back to local JSON file...');
  }

  // FALLBACK: Use local JSON file service
  try {
    final localService = ref.watch(localCricketDataServiceProvider);
    final response = await localService.getLiveMatchesSafe();
    
    if (response.success && response.data.isNotEmpty) {
      print('✅ Loaded ${response.data.length} LIVE matches from local JSON file');
      return response.data.map((cricketMatch) {
        return MatchEntity(
          id: cricketMatch.id,
          name: cricketMatch.title,
          status: cricketMatch.status,
          dateTimeGMT: cricketMatch.lastUpdated,
          matchType: cricketMatch.matchType,
          teams: cricketMatch.teams.map((team) => team.name).toList(),
          venue: cricketMatch.venue,
          series: cricketMatch.series,
          liveScore: _extractLiveScore(cricketMatch),
        );
      }).toList();
    } else {
      print('⚠️ Local JSON file service returned no LIVE matches');
    }
  } catch (e) {
    print('❌ Fallback local LIVE service error: $e');
  }

  print('❌ No LIVE matches found from any source, returning empty list');
  return [];
});

/// Provider for UPCOMING matches from LOCAL cricket server
/// Primary: Fetches from localhost:8000/api/v1/matches (filtered)
/// Fallback: Filters local JSON file for upcoming matches
final upcomingMatchesProvider = FutureProvider<List<MatchEntity>>((ref) async {
  print('📅 Provider: upcomingMatchesProvider called - fetching UPCOMING matches');
  
  try {
    // PRIMARY: Try LOCAL server API
    print('📡 Attempting to fetch UPCOMING matches from LOCAL server...');
    final dataSource = ref.watch(cricketDataSourceProvider);
    final models = await dataSource.fetchUpcomingMatches();
    
    if (models.isNotEmpty) {
      print('✅ Successfully loaded ${models.length} UPCOMING matches from LOCAL server');
      return models.map((model) => MatchEntity.fromModel(model)).toList();
    } else {
      print('⚠️ LOCAL server returned no UPCOMING matches');
    }
  } catch (e) {
    print('❌ LOCAL server UPCOMING matches failed: $e');
    print('🔄 Falling back to local JSON file...');
  }

  // FALLBACK: Use local JSON file service
  try {
    final localService = ref.watch(localCricketDataServiceProvider);
    final response = await localService.getUpcomingMatches();
    
    if (response.success && response.data.isNotEmpty) {
      print('✅ Loaded ${response.data.length} UPCOMING matches from local JSON file');
      return response.data.map((cricketMatch) {
        return MatchEntity(
          id: cricketMatch.id,
          name: cricketMatch.title,
          status: cricketMatch.status,
          dateTimeGMT: cricketMatch.lastUpdated,
          matchType: cricketMatch.matchType,
          teams: cricketMatch.teams.map((team) => team.name).toList(),
          venue: cricketMatch.venue,
          series: cricketMatch.series,
          liveScore: _extractLiveScore(cricketMatch),
        );
      }).toList();
    }
  } catch (e) {
    print('❌ Fallback UPCOMING service error: $e');
  }

  print('⚠️ No UPCOMING matches found, returning empty list');
  return [];
});

/// Provider for ENHANCED matches (all matches with full details) from LOCAL cricket server
/// Primary: Fetches from localhost:8000/api/v1/matches
/// Fallback: Uses local JSON file via LocalCricketDataService
final enhancedMatchesProvider = FutureProvider<List<MatchEntity>>((ref) async {
  print('🔄 Provider: enhancedMatchesProvider called - fetching ENHANCED matches');

  try {
    // PRIMARY: Try LOCAL server API
    print('📡 Attempting to fetch ENHANCED matches from LOCAL server...');
    final dataSource = ref.watch(cricketDataSourceProvider);
    final models = await dataSource.fetchMatches();
    
    if (models.isNotEmpty) {
      print('✅ Successfully loaded ${models.length} ENHANCED matches from LOCAL server');
      return models.map((model) => MatchEntity.fromModel(model)).toList();
    } else {
      print('⚠️ LOCAL server returned empty results');
    }
  } catch (e) {
    print('❌ LOCAL server ENHANCED matches failed: $e');
    print('🔄 Falling back to local JSON file...');
  }

  // FALLBACK: Use local service
  try {
    final localService = ref.watch(localCricketDataServiceProvider);
    final response = await localService.getAllMatches();

    if (response.success && response.data.isNotEmpty) {
      print('✅ Loaded ${response.data.length} ENHANCED matches from local JSON file');
      return response.data.map((cricketMatch) {
        return MatchEntity(
          id: cricketMatch.id,
          name: cricketMatch.title,
          status: cricketMatch.status,
          dateTimeGMT: cricketMatch.lastUpdated,
          matchType: cricketMatch.matchType,
          teams: cricketMatch.teams.map((team) => team.name).toList(),
          venue: cricketMatch.venue,
          series: cricketMatch.series,
          liveScore: _extractLiveScore(cricketMatch),
        );
      }).toList();
    } else {
      print('⚠️ Local JSON file service failed: ${response.error}');
    }
  } catch (e) {
    print('❌ Fallback ENHANCED service error: $e');
  }

  // Final fallback - return empty list
  print('❌ All ENHANCED data sources failed, returning empty list');
  return [];
});

/// Provider for DETAILED LIVE SCORES from LOCAL cricket server
final detailedLiveScoresProvider =
    FutureProvider<List<DetailedLiveScoreEntity>>((ref) async {
      print('📊 Provider: detailedLiveScoresProvider called');
      try {
        final useCase = ref.watch(getDetailedLiveScoresUseCaseProvider);
        return await useCase.call();
      } catch (e) {
        print('❌ Error getting detailed live scores: $e');
        return [];
      }
    });

/// Provider for COMPLETED matches from LOCAL cricket server
/// Primary: Fetches from localhost:8000/api/v1/matches (filtered for completed)
/// Fallback: Filters local JSON file for completed matches
final completedMatchesProvider = FutureProvider<List<CompletedMatchEntity>>((
  ref,
) async {
  print('✔️ Provider: completedMatchesProvider called - fetching COMPLETED matches');
  
  try {
    // PRIMARY: Try LOCAL server API
    print('📡 Attempting to fetch COMPLETED matches from LOCAL server...');
    final dataSource = ref.watch(cricketDataSourceProvider);
    final models = await dataSource.fetchCompletedMatches();
    
    if (models.isNotEmpty) {
      print('✅ Successfully loaded ${models.length} COMPLETED matches from LOCAL server');
      return models.map((model) => CompletedMatchEntity.fromModel(model)).toList();
    } else {
      print('⚠️ LOCAL server returned no COMPLETED matches');
    }
  } catch (e) {
    print('❌ LOCAL server COMPLETED matches failed: $e');
    print('🔄 Falling back to local JSON file...');
  }

  // FALLBACK: Use local JSON file service
  try {
    final localService = ref.watch(localCricketDataServiceProvider);
    final response = await localService.getRecentMatches();
    
    if (response.success && response.data.isNotEmpty) {
      print('✅ Loaded ${response.data.length} COMPLETED matches from local JSON file');
      
      // Convert CricketMatch to CompletedMatchEntity
      return response.data.map((cricketMatch) {
        return CompletedMatchEntity(
          id: cricketMatch.id,
          name: cricketMatch.title,
          matchType: cricketMatch.matchType,
          teams: cricketMatch.teams.map((t) => t.name).toList(),
          status: cricketMatch.status,
          dateTimeGMT: cricketMatch.lastUpdated,
          result: cricketMatch.enhancedInfo?.result ?? cricketMatch.status,
          date: cricketMatch.enhancedInfo?.matchDate ?? '',
          scores: cricketMatch.teams.map((t) => t.score).toList(),
          url: cricketMatch.url,
          isCompleted: true,
          venue: cricketMatch.venue,
          series: cricketMatch.series,
        );
      }).toList();
    }
  } catch (e) {
    print('❌ Fallback COMPLETED service error: $e');
  }

  print('⚠️ No COMPLETED matches found, returning empty list');
  return [];
});

/// Provider for specific MATCH RESULT by ID from LOCAL cricket server
/// Uses: localhost:8000/api/v1/matches/{match_id}
final matchResultProvider = FutureProvider.family<MatchResultEntity, String>((
  ref,
  matchId,
) async {
  print('🏆 Provider: matchResultProvider called for match ID: $matchId');
  
  try {
    final dataSource = ref.watch(cricketDataSourceProvider);
    final response = await dataSource.fetchMatchScore(matchId);
    final model = MatchResultModel.fromJson(response);
    print('✅ Successfully loaded match result for $matchId');
    return MatchResultEntity.fromModel(model);
  } catch (e) {
    print('❌ Error getting match result for $matchId: $e');
    rethrow;
  }
});

/// Provider for API CONNECTION TEST to LOCAL cricket server
/// Tests connectivity to localhost:8000
final apiConnectionTestProvider = FutureProvider<bool>((ref) async {
  print('🔌 Provider: Testing LOCAL cricket server connection...');
  
  try {
    final dataSource = ref.watch(cricketDataSourceProvider);
    final isConnected = await dataSource.testConnection();
    
    if (isConnected) {
      print('✅ LOCAL cricket server is ONLINE (localhost:8000)');
    } else {
      print('❌ LOCAL cricket server is OFFLINE or not responding');
    }
    
    return isConnected;
  } catch (e) {
    print('❌ Error testing LOCAL cricket server connection: $e');
    return false;
  }
});
