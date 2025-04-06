import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuroassist/services/pomodoro_service.dart';

class MyTimer extends StatefulWidget {
  final String breakTime;
  final String workTime;
  final String workSessions;
  final bool customMode;
  final List<int> customSessionMinutes;
  final List<int> customBreakMinutes;
  final String sessionId; // Add Firestore session ID parameter

  const MyTimer({
    Key? key, 
    required this.breakTime, 
    required this.workTime, 
    required this.workSessions,
    this.customMode = false,
    this.customSessionMinutes = const [],
    this.customBreakMinutes = const [],
    this.sessionId = '', // Default empty string
  }) : super(key: key);

  @override
  _TimerState createState() => _TimerState();
}

class _TimerState extends State<MyTimer> with WidgetsBindingObserver {
  bool _isRunning = false;
  Duration _time = const Duration(minutes: 60);
  Duration _break = const Duration(minutes: 10);
  int _timeInt = 60;
  int _counter = 1;
  int _sessionCount = 4;
  int _timerCount = 0;
  int _currMax = 60;
  Timer? _timer;
  DateTime? _pausedAt;
  DateTime? _timerEndTime;
  SharedPreferences? _prefs;
  
  // Custom mode variables
  bool _isCustomMode = false;
  List<int> _customSessionMinutes = [];
  List<int> _customBreakMinutes = [];
  int _currentSegmentIndex = 0; // Track which session or break we're on
  bool _isBreakTime = false; // Whether we're in a break or work session
  int _totalSegments = 0; // Total sessions + breaks
  String _currentSegmentName = "Session 1";
  
  // User data
  String? userEmail;
  bool isLoadingUser = true;
  
  // Track current segment start time for Firestore
  DateTime? _currentSegmentStart;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load user data
    _loadUserData();
    
    // Check for custom mode
    _isCustomMode = widget.customMode;
    
    if (_isCustomMode) {
      // Initialize custom mode
      _customSessionMinutes = List.from(widget.customSessionMinutes);
      _customBreakMinutes = List.from(widget.customBreakMinutes);
      
      // Calculate total segments
      _totalSegments = _customSessionMinutes.length + _customBreakMinutes.length;
      
      // Set initial time to first session
      if (_customSessionMinutes.isNotEmpty) {
        _timeInt = _customSessionMinutes[0];
        _time = Duration(minutes: _timeInt);
        _currMax = _timeInt;
      }
    } else {
      // Initialize standard mode
      try {
        if(widget.breakTime == '0'){
          throw Exception('Break time cannot be 0');
        }
        _timeInt = int.parse(widget.workTime);
        _time = Duration(minutes: _timeInt);
        _break = Duration(minutes: int.parse(widget.breakTime));
        _sessionCount = int.parse(widget.workSessions);
        _currMax = _timeInt;
      } catch (e) {
        _timeInt = 60;
        _time = Duration(minutes: _timeInt);
        _break = const Duration(minutes: 10);
        _sessionCount = 4;
        _showInvalidInputSnackbar(context);
        Navigator.pop(context);
        return;
      }
    }
    
    _getPrefs();
  }
  
  // Load user data
  Future<void> _loadUserData() async {
    setState(() {
      isLoadingUser = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          userEmail = user.email;
          isLoadingUser = false;
        });
      } else {
        setState(() {
          userEmail = 'Guest User';
          isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Error getting user data: $e');
      setState(() {
        userEmail = 'Guest User';
        isLoadingUser = false;
      });
    }
  }
  
  void _showAlert(String title, String body) {
    // Show a SnackBar since we've removed notifications
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(body),
            ],
          ),
          backgroundColor: Colors.greenAccent.shade700,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _scheduleEndTime() {
    // Calculate when the timer will end
    _timerEndTime = DateTime.now().add(_time);
  }
  
  void _cancelEndTime() {
    _timerEndTime = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is in the background
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // App is back in the foreground
      if (_pausedAt != null && _isRunning && _timerEndTime != null) {
        // Calculate elapsed time while app was in background
        final now = DateTime.now();
        final elapsedSeconds = now.difference(_pausedAt!).inSeconds;
        
        if (elapsedSeconds > 0) {
          // Check if timer should have ended while in background
          if (now.isAfter(_timerEndTime!)) {
            // Timer ended while in background
            if (_isCustomMode) {
              _moveToNextSegment();
            } else {
              _standardModeNextSegment();
            }
          } else {
            // Update timer with elapsed time
            setState(() {
              _time = _time - Duration(seconds: elapsedSeconds);
              if (_time.inSeconds <= 0) {
                if (_isCustomMode) {
                  _moveToNextSegment();
                } else {
                  _standardModeNextSegment();
                }
              }
            });
          }
        }
      }
      _pausedAt = null;
    }
  }

  void _showInvalidInputSnackbar(BuildContext context) {
    AnimatedSnackBar(
      builder: ((context) {
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.redAccent,
          height: 65,
          child: Flex(
            direction: Axis.vertical,
            children: [
              Row(
                children: const [
                  Icon(Icons.close, size: 30,),
                  SizedBox(width: 20),
                  Text('Invalid input!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Arial',),),
                ],
              ),
              Row(
                children: const [
                  SizedBox(width: 50),
                  Text("Please enter valid numbers to start.", style: TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Arial',),),
                ],
              ),
            ],
          ),
        );
      }),
    ).show(context);
  }

  void _getPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _storeTime() async {
    if (_prefs == null) return;
    
    String? curr = '';
    curr = _prefs?.getString('time') ?? '';
    var now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);
    String formattedDate = "${date.day}-${date.month}-${date.year}";
    
    int totalMinutes = 0;
    if (_isCustomMode) {
      // Sum up all session minutes for custom mode
      for (int minutes in _customSessionMinutes) {
        totalMinutes += minutes;
      }
    } else {
      // Standard mode
      totalMinutes = _sessionCount * _timeInt;
    }
    
    await _prefs!.setString('time', '$curr / $totalMinutes $formattedDate');
  }

  Future<void> _resetTime() async {
    if (_prefs == null) return;
    await _prefs!.setString('time', '');
  }

  @override
  void dispose() {
    // If a session is active but user is leaving, mark it as incomplete
    if (widget.sessionId.isNotEmpty && _isRunning) {
      // Record the last segment if there was one in progress
      if (_currentSegmentStart != null) {
        final now = DateTime.now();
        final segmentType = _isCustomMode ? 
                         (_isBreakTime ? 'break' : 'work') : 
                         (_timerCount % 2 == 1 ? 'break' : 'work');
        
        // Calculate which session or break we're on and its planned duration
        int plannedDuration;
        if (_isCustomMode) {
          int index = _isBreakTime ? 
              _currentSegmentIndex ~/ 2 - 1 : // For breaks
              (_currentSegmentIndex ~/ 2);    // For sessions
              
          plannedDuration = _isBreakTime ? 
              (index < _customBreakMinutes.length ? _customBreakMinutes[index] : 5) : 
              (index < _customSessionMinutes.length ? _customSessionMinutes[index] : 25);
        } else {
          plannedDuration = segmentType == 'work' ? _timeInt : _break.inMinutes;
        }
        
        // Calculate actual duration
        final actualDuration = now.difference(_currentSegmentStart!).inMinutes;
        
        // Log this segment to Firestore
        PomodoroSession.addSessionSegment(
          sessionId: widget.sessionId,
          type: segmentType,
          durationPlanned: plannedDuration,
          durationActual: actualDuration < 1 ? 1 : actualDuration, // Minimum 1 min
          startTime: _currentSegmentStart!,
          endTime: now,
        );
      }
      
      // Mark the session as incomplete
      PomodoroSession.completeSession(
        sessionId: widget.sessionId,
        completed: false,
      );
    }
    
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startTimer() async {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _time = _time - const Duration(seconds: 1);
        if (_time.inSeconds <= 0) {
          if (_isCustomMode) {
            _moveToNextSegment();
          } else {
            _standardModeNextSegment();
          }
        }
      });
    });
    
    // Set the segment start time
    _currentSegmentStart = DateTime.now();
    
    // Schedule end time
    _scheduleEndTime();
    
    // Set running state
    _isRunning = true;
  }
  
  void _moveToNextSegment() {
    // Record this segment completion if there was a start time
    if (_currentSegmentStart != null && widget.sessionId.isNotEmpty) {
      final now = DateTime.now();
      final segmentType = _isBreakTime ? 'break' : 'work';
      
      // Fix the index calculation for breaks
      int index;
      if (_isBreakTime) {
        // Safer calculation for break index
        index = (_currentSegmentIndex / 2).floor() - 1;
        if (index < 0) index = 0;  // Ensure index is never negative
      } else {
        index = (_currentSegmentIndex ~/ 2);  // Original calculation for work sessions
      }
      
      // Get planned duration with safer index access
      int plannedDuration;
      if (_isBreakTime) {
        plannedDuration = (index >= 0 && index < _customBreakMinutes.length) 
            ? _customBreakMinutes[index] 
            : 5;  // Default to 5 minutes if out of bounds
      } else {
        plannedDuration = (index < _customSessionMinutes.length) 
            ? _customSessionMinutes[index] 
            : 25;  // Default to 25 minutes if out of bounds
      }
      
      // Calculate actual duration (could be less than planned if user left early)
      final actualDuration = now.difference(_currentSegmentStart!).inMinutes;
      
      // Log this segment to Firestore
      PomodoroSession.addSessionSegment(
        sessionId: widget.sessionId,
        type: segmentType,
        durationPlanned: plannedDuration,
        durationActual: actualDuration < 1 ? 1 : actualDuration, // Minimum 1 min
        startTime: _currentSegmentStart!,
        endTime: now,
      );
    }
    
    // For custom mode
    _currentSegmentIndex++;
    
    // Check if we've completed all segments
    if (_currentSegmentIndex >= _totalSegments) {
      _showSessionCompletedSnackbar();
      
      // Show alert for completed session
      _showAlert(
        'Pomodoro Completed!', 
        'You have completed all your custom sessions!'
      );
      
      _storeTime();
      _stopTimer();
      _isRunning = false;
      
      // Mark session as completed in Firestore
      if (widget.sessionId.isNotEmpty) {
        PomodoroSession.completeSession(
          sessionId: widget.sessionId,
          completed: true,
        );
      }
      
      Navigator.pop(context);
      return;
    }
    
    // Determine if this is a break or session
    _isBreakTime = !_isBreakTime;
    
    if (_isBreakTime) {
      // Calculate which break we're on - fixing the calculation to prevent negative index
      int breakIndex = (_currentSegmentIndex / 2).floor();
      if (breakIndex >= 0 && breakIndex < _customBreakMinutes.length) {
        _time = Duration(minutes: _customBreakMinutes[breakIndex]);
        _currMax = _customBreakMinutes[breakIndex];
        _currentSegmentName = "Break ${breakIndex + 1}";
        
        // Show alert for break
        _showAlert(
          'Break Time!', 
          'Take a ${_customBreakMinutes[breakIndex]} minute break.'
        );
      }
    } else {
      // Calculate which session we're on
      int sessionIndex = (_currentSegmentIndex + 1) ~/ 2;
      if (sessionIndex < _customSessionMinutes.length) {
        _time = Duration(minutes: _customSessionMinutes[sessionIndex]);
        _currMax = _customSessionMinutes[sessionIndex];
        _currentSegmentName = "Session ${sessionIndex + 1}";
        
        // Show alert for new session
        _showAlert(
          'Session Time!', 
          'Start Session ${sessionIndex + 1} (${_customSessionMinutes[sessionIndex]} minutes).'
        );
      }
    }
    
    // No longer stop the timer or reset running state
    // Instead, just continue with the next session/break automatically
    // Only briefly pause to notify the user
    setState(() {
      // Brief pause to notify user of session change
      _stopTimer();
      
      // Update segment start time
      _currentSegmentStart = DateTime.now();
      
      // Restart the timer after a short delay
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _startTimer();
          });
        }
      });
    });
  }
  
  void _standardModeNextSegment() {
    // Record this segment completion if there was a start time
    if (_currentSegmentStart != null && widget.sessionId.isNotEmpty) {
      final now = DateTime.now();
      final segmentType = _timerCount % 2 == 0 ? 'work' : 'break';
      final plannedDuration = segmentType == 'work' ? _timeInt : _break.inMinutes;
      
      // Calculate actual duration (could be less than planned if user left early)
      final actualDuration = now.difference(_currentSegmentStart!).inMinutes;
      
      // Log this segment to Firestore
      PomodoroSession.addSessionSegment(
        sessionId: widget.sessionId,
        type: segmentType,
        durationPlanned: plannedDuration,
        durationActual: actualDuration < 1 ? 1 : actualDuration, // Minimum 1 min
        startTime: _currentSegmentStart!,
        endTime: now,
      );
    }
    
    if(_timerCount % 2 == 1) {
      _time = Duration(minutes: _timeInt);
      _currMax = _timeInt;
      _timerCount++;
      
      // Show alert for work session
      _showAlert(
        'Session Time!', 
        'Start Session $_counter of $_sessionCount.'
      );
    } else {
      _time = _break;
      _currMax = _break.inMinutes;
      _counter++;
      _timerCount++;
      
      // Show alert for break
      _showAlert(
        'Break Time!', 
        'Take a ${_break.inMinutes} minute break.'
      );
    }
    
    if (_counter > _sessionCount) {
      _showSessionCompletedSnackbar();
      
      // Show completion alert
      _showAlert(
        'Pomodoro Completed!', 
        'You logged ${_sessionCount * _timeInt} minutes.'
      );
      
      _storeTime();
      _stopTimer();
      _isRunning = false;
      
      // Mark session as completed in Firestore
      if (widget.sessionId.isNotEmpty) {
        PomodoroSession.completeSession(
          sessionId: widget.sessionId,
          completed: true,
        );
      }
      
      Navigator.pop(context);
    } else {
      // Similar to custom mode - auto-continue instead of stopping
      setState(() {
        // Brief pause to notify user of session change
        _stopTimer();
        
        // Update segment start time
        _currentSegmentStart = DateTime.now();
        
        // Restart the timer after a short delay
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _startTimer();
            });
          }
        });
      });
    }
  }
  
  void _showSessionCompletedSnackbar() {
    AnimatedSnackBar(
      builder: ((context) {
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.greenAccent,
          height: 65,
          child: Column(
            children: [
              Row(
                children: const [
                  Icon(Icons.check_circle_outline, size: 30,),
                  SizedBox(width: 20),
                  Text('Session Completed!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Arial',),),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 50),
                  Text(
                    _isCustomMode 
                      ? 'You completed all your custom sessions!' 
                      : 'You logged ${_sessionCount * _timeInt} minutes.',
                    style: TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Arial',),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    ).show(context);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _stopTimer() {
    _timer?.cancel();
    _cancelEndTime();
    _isRunning = false;
  }

  void _resetTimer() {
    setState(() {
      if (_isRunning) {
        _stopTimer();
      }
      
      if (_isCustomMode) {
        // Reset to the first session
        _currentSegmentIndex = 0;
        _isBreakTime = false;
        if (_customSessionMinutes.isNotEmpty) {
          _time = Duration(minutes: _customSessionMinutes[0]);
          _currMax = _customSessionMinutes[0];
          _currentSegmentName = "Session 1";
        }
      } else {
        // Standard mode reset
        _timerCount = 0;
        _counter = 1;
        _time = Duration(minutes: _timeInt);
        _currMax = _timeInt;
      }
      
      _isRunning = false;
      
      // Reset segment start time
      _currentSegmentStart = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int minutes = _time.inMinutes;
    final int seconds = _time.inSeconds % 60;
    
    // Determine what to display for the timer state
    String timerState;
    if (_isCustomMode) {
      timerState = _currentSegmentName;
    } else {
      timerState = _timerCount % 2 == 0 ? '$_counter / $_sessionCount' : "Break";
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default back button
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.greenAccent),
          onPressed: () {
            if (_isRunning) {
              // Show a confirmation dialog since timer is running
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: Text(
                      'Exit Session?',
                      style: TextStyle(color: Colors.greenAccent),
                    ),
                    content: Text(
                      'Your timer is still running. Are you sure you want to exit? Your progress will be saved.',
                      style: TextStyle(color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text(
                          'Exit',
                          style: TextStyle(color: Colors.greenAccent),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context).pop(); // Exit timer screen
                        },
                      ),
                    ],
                  );
                },
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        centerTitle: false,
        backgroundColor: Colors.black,
        title: Text.rich(
          TextSpan(
            text: 'Session',
            style: TextStyle(
              fontSize: 24,
              color: Colors.greenAccent,
              fontFamily: 'Arial',
            ),
          ),
        ),
        actions: [
          // User email display
          if (!isLoadingUser)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  userEmail ?? 'Guest User',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                    fontFamily: 'Arial',
                  ),
                ),
              ),
            ),
          IconButton(
            padding: const EdgeInsets.only(right: 20.0),
            icon: const Icon(Icons.restart_alt, color: Colors.greenAccent, size: 30),
            onPressed: () {
              setState(() {
                _resetTimer();
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container (
                  width: 300,
                  height: 300,
                  child: CircularProgressIndicator(
                    color: Colors.greenAccent,
                    backgroundColor: Colors.black,
                    value: _time.inSeconds / (_currMax * 60),
                    strokeWidth: 2,
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 70,
                  child: Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 60,
                      color: Colors.greenAccent,
                      fontFamily: 'Arial',
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: 130,
                  child: Text(
                    timerState,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.greenAccent,
                      fontFamily: 'Arial',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Exit button (left side)
            FloatingActionButton(
              onPressed: () {
                if (_isRunning) {
                  // Show confirmation dialog if timer is running
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: Text(
                          'Exit to Home?',
                          style: TextStyle(color: Colors.greenAccent),
                        ),
                        content: Text(
                          'Your timer is still running. Are you sure you want to exit to home? Your progress will be saved.',
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text(
                              'Exit',
                              style: TextStyle(color: Colors.greenAccent),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close dialog
                              // Navigate to home (popping until home)
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // Navigate to home directly if timer is not running
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              heroTag: 'exitBtn',
              backgroundColor: Colors.black,
              child: const Icon(Icons.home, color: Colors.greenAccent),
            ),
            
            // Play/Pause button (right side - original position)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (_isRunning) {
                    _stopTimer();
                  } else {
                    _startTimer();
                  }
                });
              },
              heroTag: 'playPauseBtn',
              backgroundColor: Colors.black,
              child: _isRunning
                  ? const Icon(Icons.pause, color: Colors.greenAccent)
                  : const Icon(Icons.play_arrow, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
    );
  }
}