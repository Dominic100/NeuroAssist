import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PomodoroLeaderboardScreen extends StatefulWidget {
  const PomodoroLeaderboardScreen({Key? key}) : super(key: key);

  @override
  _PomodoroLeaderboardScreenState createState() => _PomodoroLeaderboardScreenState();
}

class _PomodoroLeaderboardScreenState extends State<PomodoroLeaderboardScreen> {
  bool isLoading = true;
  List<UserStats> leaderboardData = [];
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchLeaderboardData();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserEmail = user.email;
      });
    }
  }

  Future<void> _fetchLeaderboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get all pomodoro sessions from Firestore
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('pomodoro')
          .get();

      // Process the data to aggregate by user
      Map<String, UserStats> userStatsMap = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userEmail = data['userEmail'] as String? ?? 'Unknown User';
        final completed = data['completed'] as bool? ?? false;
        final sessionsCompleted = data['sessionsCompleted'] as int? ?? 0;
        final totalWorkMinutes = data['totalWorkMinutes'] as int? ?? 0;

        // Determine session type and extract planned sessions count
        int plannedSessions = 0;
        if (data['sessionType'] == 'standard' && data['standardConfig'] != null) {
          final standardConfig = data['standardConfig'] as Map<String, dynamic>;
          plannedSessions = standardConfig['sessionsPlanned'] as int? ?? 0;
        } else if (data['sessionType'] == 'custom' && data['customConfig'] != null) {
          final customConfig = data['customConfig'] as Map<String, dynamic>;
          final workDurations = customConfig['workDurations'] as List<dynamic>? ?? [];
          plannedSessions = workDurations.length;
        }

        // Update or create the user stats
        if (!userStatsMap.containsKey(userEmail)) {
          userStatsMap[userEmail] = UserStats(
            email: userEmail,
            totalSessionsCompleted: 0,
            totalSessionsPlanned: 0,
            totalWorkMinutes: 0,
            completedSessions: 0,
          );
        }

        userStatsMap[userEmail]!.totalSessionsCompleted += sessionsCompleted;
        userStatsMap[userEmail]!.totalSessionsPlanned += plannedSessions;
        userStatsMap[userEmail]!.totalWorkMinutes += totalWorkMinutes;
        if (completed) {
          userStatsMap[userEmail]!.completedSessions += 1;
        }
      }

      // Convert to list and calculate completion ratio
      List<UserStats> userStatsList = userStatsMap.values.toList();
      
      // Calculate the completion ratio for each user
      for (var stats in userStatsList) {
        if (stats.totalSessionsPlanned > 0) {
          stats.completionRatio = stats.totalSessionsCompleted / stats.totalSessionsPlanned;
        }
      }

      // Sort by completion ratio (highest first)
      userStatsList.sort((a, b) => b.completionRatio.compareTo(a.completionRatio));

      setState(() {
        leaderboardData = userStatsList;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching leaderboard data: $e');
      setState(() {
        isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load leaderboard data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Pomodoro Leaderboard',
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.greenAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.greenAccent),
            onPressed: _fetchLeaderboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : leaderboardData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined, 
                        color: Colors.greenAccent,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Pomodoro data yet!',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete some sessions to see the leaderboard.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Rank',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'User',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Success Rate',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Work Minutes',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.greenAccent.withOpacity(0.3)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: leaderboardData.length,
                        itemBuilder: (context, index) {
                          final userStats = leaderboardData[index];
                          final isCurrentUser = userStats.email == currentUserEmail;
                          
                          return Container(
                            color: isCurrentUser ? Colors.greenAccent.withOpacity(0.1) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 16.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: _getRankColor(index),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      userStats.email,
                                      style: TextStyle(
                                        color: isCurrentUser ? Colors.greenAccent : Colors.white,
                                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${(userStats.completionRatio * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${userStats.totalWorkMinutes}',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 0) return Colors.yellow; // Gold
    if (rank == 1) return Colors.grey.shade300; // Silver
    if (rank == 2) return Colors.orange.shade700; // Bronze
    return Colors.white; // Other ranks
  }
}

class UserStats {
  final String email;
  int totalSessionsCompleted;
  int totalSessionsPlanned;
  int totalWorkMinutes;
  int completedSessions;
  double completionRatio = 0.0;

  UserStats({
    required this.email,
    required this.totalSessionsCompleted,
    required this.totalSessionsPlanned,
    required this.totalWorkMinutes,
    required this.completedSessions,
  });
}