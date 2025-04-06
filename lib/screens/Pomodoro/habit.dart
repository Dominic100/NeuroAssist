import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neuroassist/screens/Pomodoro/timer.dart';

class Habit extends StatefulWidget {
  const Habit({Key? key}) : super(key: key);

  @override
  _HabitState createState() => _HabitState();
}

class _HabitState extends State<Habit> {
  bool _useStandardMode = true; // Toggle between standard and custom modes
  
  // Controllers for standard mode
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _breakController = TextEditingController();
  final TextEditingController _sessionController = TextEditingController();
  
  // Custom mode: List of session and break durations
  List<int> _customSessionMinutes = [25]; // Default first session is 25 min
  List<int> _customBreakMinutes = []; // No breaks initially
  
  // Controllers for custom mode input fields
  List<TextEditingController> _sessionControllers = [TextEditingController(text: '25')];
  List<TextEditingController> _breakControllers = [];

  @override
  void dispose() {
    _workController.dispose();
    _breakController.dispose();
    _sessionController.dispose();
    
    // Dispose all custom controllers
    for (var controller in _sessionControllers) {
      controller.dispose();
    }
    for (var controller in _breakControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  void _addNewSession() {
    setState(() {
      // Add a new break before the new session (except for the first session)
      if (_customSessionMinutes.isNotEmpty) {
        _customBreakMinutes.add(5); // Default 5 min break
        _breakControllers.add(TextEditingController(text: '5'));
      }
      
      // Add a new session
      _customSessionMinutes.add(25); // Default 25 min session
      _sessionControllers.add(TextEditingController(text: '25'));
    });
  }

  void _removeSession(int index) {
    if (_customSessionMinutes.length <= 1) {
      // Don't remove if it's the last session
      return;
    }
    
    setState(() {
      // Remove the session
      _customSessionMinutes.removeAt(index);
      _sessionControllers[index].dispose();
      _sessionControllers.removeAt(index);
      
      // Remove the break before this session (or after if it's the first session)
      int breakIndexToRemove = index > 0 ? index - 1 : 0;
      if (_customBreakMinutes.isNotEmpty && breakIndexToRemove < _customBreakMinutes.length) {
        _customBreakMinutes.removeAt(breakIndexToRemove);
        _breakControllers[breakIndexToRemove].dispose();
        _breakControllers.removeAt(breakIndexToRemove);
      }
    });
  }

  List<Widget> _buildCustomSessionInputs() {
    List<Widget> widgets = [];
    
    for (int i = 0; i < _customSessionMinutes.length; i++) {
      // Add session input
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  "Session ${i + 1}",
                  style: TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'Arial'),
                ),
              ),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _sessionControllers[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Arial'),
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black12,
                    labelText: 'minutes',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      borderSide: BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      borderSide: BorderSide(color: Colors.white10),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _customSessionMinutes[i] = int.tryParse(value) ?? _customSessionMinutes[i];
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _removeSession(i),
              ),
            ],
          ),
        ),
      );
      
      // Add break input after each session (except the last one)
      if (i < _customSessionMinutes.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Break ${i + 1}",
                    style: TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'Arial'),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _breakControllers[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Arial'),
                    keyboardType: TextInputType.number,
                    keyboardAppearance: Brightness.dark,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black12,
                      labelText: 'minutes',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _customBreakMinutes[i] = int.tryParse(value) ?? _customBreakMinutes[i];
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: Colors.transparent),
                  onPressed: null,
                ),
              ],
            ),
          ),
        );
      }
    }
    
    // Add button to add a new session
    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: ElevatedButton.icon(
          onPressed: _addNewSession,
          icon: Icon(Icons.add, color: Colors.black),
          label: Text(
            "Add Session",
            style: TextStyle(color: Colors.black, fontFamily: 'Arial'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );
    
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    Color col = Colors.greenAccent;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          centerTitle: false,
          backgroundColor: Colors.black,
          title: Text.rich(
            TextSpan(
              text: 'Start session',
              style: TextStyle(
                fontSize: 24,
                color: Colors.greenAccent,
                fontFamily: 'Arial',
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            color: Colors.black38,
            margin: EdgeInsets.all(30),
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _useStandardMode = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _useStandardMode ? Colors.greenAccent : Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          "Standard",
                          style: TextStyle(
                            color: _useStandardMode ? Colors.black : Colors.white70,
                            fontFamily: 'Arial',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _useStandardMode = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_useStandardMode ? Colors.greenAccent : Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          "Custom",
                          style: TextStyle(
                            color: !_useStandardMode ? Colors.black : Colors.white70,
                            fontFamily: 'Arial',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Standard mode inputs
                if (_useStandardMode) ...[
                  const Text(
                    "Work duration",
                    style: TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'Arial'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _workController,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Arial'),
                    keyboardType: TextInputType.number,
                    keyboardAppearance: Brightness.dark,
                    decoration: const InputDecoration(
                      fillColor: Colors.black12,
                      labelText: '(in minutes)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Break duration",
                    style: TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'Arial'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _breakController,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Arial'),
                    keyboardType: TextInputType.number,
                    keyboardAppearance: Brightness.dark,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.black12,
                      labelText: '(in minutes)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Sessions",
                    style: TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'Arial'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _sessionController,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Arial'),
                    keyboardType: TextInputType.number,
                    keyboardAppearance: Brightness.dark,
                    decoration: const InputDecoration(
                      fillColor: Colors.black12,
                      labelText: '(number of work sessions)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                    ),
                  ),
                ] 
                // Custom mode inputs
                else ...[
                  Text(
                    "Custom Session Setup",
                    style: TextStyle(fontSize: 18, color: Colors.greenAccent, fontFamily: 'Arial', fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Set up your custom work and break sessions below. Each work session will be followed by a break.",
                    style: TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'Arial'),
                  ),
                  SizedBox(height: 20),
                  ..._buildCustomSessionInputs(),
                ],
                
                SizedBox(height: 40),
                Center(
                  child: TextButton(
                    onPressed: () {
                      if (_useStandardMode) {
                        // Standard mode
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(seconds: 1),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return FadeTransition(
                                opacity: animation,
                                child: MyTimer(
                                  breakTime: _breakController.text,
                                  workTime: _workController.text,
                                  workSessions: _sessionController.text,
                                  customMode: false,
                                  customSessionMinutes: [],
                                  customBreakMinutes: [],
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        // Custom mode - update values from controllers
                        List<int> sessionMinutes = [];
                        List<int> breakMinutes = [];
                        
                        for (int i = 0; i < _sessionControllers.length; i++) {
                          String sessionText = _sessionControllers[i].text;
                          sessionMinutes.add(int.tryParse(sessionText) ?? 25);
                        }
                        
                        for (int i = 0; i < _breakControllers.length; i++) {
                          String breakText = _breakControllers[i].text;
                          breakMinutes.add(int.tryParse(breakText) ?? 5);
                        }
                        
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: Duration(seconds: 1),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return FadeTransition(
                                opacity: animation,
                                child: MyTimer(
                                  breakTime: "5", // Dummy values for custom mode
                                  workTime: "25",
                                  workSessions: "1",
                                  customMode: true,
                                  customSessionMinutes: sessionMinutes,
                                  customBreakMinutes: breakMinutes,
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: EdgeInsets.zero,
                      minimumSize: Size(150, 50),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(color: Colors.black12, width: 2.0),
                      )
                    ),
                    child: const Text(
                      "Start",
                      style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Arial'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}