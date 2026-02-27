// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:world_of_cricket/feature/matches_scores/domain/entities/match_entity.dart';
import 'package:world_of_cricket/feature/matches_scores/domain/usecase/get_all_matches.dart';

class MatchProvider extends ChangeNotifier {
  bool isLoading = false;
  final GetAllMatches getAllMatches;
  List<MatchEntity> matches = [];
  MatchProvider({required this.getAllMatches});

  Future<void> fetchMatches() async {
    isLoading = true;
    notifyListeners();

    matches = await getAllMatches();
    isLoading = false;
    notifyListeners();
  }
}
