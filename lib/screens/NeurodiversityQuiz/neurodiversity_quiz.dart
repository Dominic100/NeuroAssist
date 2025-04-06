import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NeurodiversityQuizScreen extends StatefulWidget {
  const NeurodiversityQuizScreen({Key? key}) : super(key: key);
  
  @override
  _NeurodiversityQuizScreenState createState() => _NeurodiversityQuizScreenState();
}

class _NeurodiversityQuizScreenState extends State<NeurodiversityQuizScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Map<int, String> answers = {};

  // Hardcoded questions from the provided JSON
  final List<Map<String, dynamic>> questions = [
    {"id": 1, "text": "I find it difficult to understand maps or diagrams.", "condition": "Dyslexia"},
    {"id": 2, "text": "I often fidget or tap my hands or feet.", "condition": "ADHD"},
    {"id": 3, "text": "I enjoy having a predictable daily routine.", "condition": "Autism"},
    {"id": 4, "text": "I find it hard to judge distances between objects.", "condition": "Dyspraxia"},
    {"id": 5, "text": "I frequently make careless mistakes in calculations.", "condition": "Dyscalculia"},
    {"id": 6, "text": "I feel overwhelmed in noisy or crowded environments.", "condition": "Autism"},
    {"id": 7, "text": "I have difficulty remembering multi-step instructions.", "condition": "ADHD"},
    {"id": 8, "text": "I struggle to maintain eye contact during conversations.", "condition": "Autism"},
    {"id": 9, "text": "I often misread words or skip lines while reading.", "condition": "Dyslexia"},
    {"id": 10, "text": "I find it hard to organize my thoughts when speaking.", "condition": "ADHD"},
    {"id": 11, "text": "I have difficulty coordinating my movements.", "condition": "Dyspraxia"},
    {"id": 12, "text": "I often have to check my calculations multiple times.", "condition": "Dyscalculia"},
    {"id": 13, "text": "I feel uncomfortable with unexpected changes in plans.", "condition": "Autism"},
    {"id": 14, "text": "I have trouble controlling unwanted sounds or movements.", "condition": "Tourette's Syndrome"},
    {"id": 15, "text": "I find it difficult to follow conversations in groups.", "condition": "ADHD"},
    {"id": 16, "text": "I enjoy engaging in repetitive or ritualistic behaviors.", "condition": "Autism"},
    {"id": 17, "text": "I often misspell words, even familiar ones.", "condition": "Dyslexia"},
    {"id": 18, "text": "I find it challenging to tell my left from my right.", "condition": "Dyslexia"},
    {"id": 19, "text": "I find it hard to concentrate on a task when there are distractions.", "condition": "ADHD"},
    {"id": 20, "text": "I avoid physical activities that require coordination.", "condition": "Dyspraxia"},
    {"id": 21, "text": "I struggle to estimate the passage of time.", "condition": "ADHD"},
    {"id": 22, "text": "I have difficulty understanding abstract concepts in math.", "condition": "Dyscalculia"},
    {"id": 23, "text": "I prefer to interact with a small group of people.", "condition": "Autism"},
    {"id": 24, "text": "I sometimes have sudden urges to make specific noises or movements.", "condition": "Tourette's Syndrome"},
    {"id": 25, "text": "I find it hard to complete tasks that require fine motor skills.", "condition": "Dyspraxia"},
    {"id": 26, "text": "I have trouble with tasks that require mental math.", "condition": "Dyscalculia"},
    {"id": 27, "text": "I am very sensitive to certain textures or fabrics.", "condition": "Autism"},
    {"id": 28, "text": "I interrupt others frequently during conversations.", "condition": "ADHD"},
    {"id": 29, "text": "I have difficulty starting or finishing tasks.", "condition": "ADHD"},
    {"id": 30, "text": "I often feel the urge to repeat certain words or phrases.", "condition": "Tourette's Syndrome"}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Question ${_currentPage + 1} of ${questions.length}',
          style: TextStyle(color: Colors.greenAccent),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.greenAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: questions.map((q) => QuestionPage(
                question: q,
                selectedAnswer: answers[q['id']],
                onAnswerSelected: (answer) {
                  setState(() {
                    answers[q['id']] = answer;
                  });
                },
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  ElevatedButton(
                    onPressed: () {
                      _controller.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                      foregroundColor: Colors.greenAccent,
                    ),
                    child: Text('Previous'),
                  )
                else
                  SizedBox(width: 0), // Placeholder for alignment
                ElevatedButton(
                  onPressed: answers.containsKey(questions[_currentPage]['id'])
                      ? () {
                          if (_currentPage < questions.length - 1) {
                            _controller.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          } else {
                            _submitAnswers(context);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[800],
                    disabledForegroundColor: Colors.grey,
                  ),
                  child: Text(_currentPage < questions.length - 1 ? 'Next' : 'Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswers(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
        ),
      ),
    );

    List<Map<String, dynamic>> responseData = questions.map((q) {
      return {
        'id': q['id'],
        'text': q['text'],
        'condition': q['condition'],
        'answer': answers[q['id']] ?? 'Not Answered', // Fallback if unanswered
      };
    }).toList();

    // For demonstration, we're creating a mock result
    // In a real app, you would send this to your API
    try {
      // Simulate network delay
      await Future.delayed(Duration(seconds: 2));
      
      // Mock API response based on answers
      Map<String, dynamic> result = _processResults(responseData);
      
      // Close loading indicator
      Navigator.pop(context);
      
      // Navigate to results screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(result: result),
        ),
      );
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  
  // Process results locally instead of sending to an API
  Map<String, dynamic> _processResults(List<Map<String, dynamic>> responses) {
    // Count answers by condition and response
    Map<String, Map<String, int>> conditionScores = {};
    
    for (var response in responses) {
      String condition = response['condition'];
      String answer = response['answer'];
      
      if (!conditionScores.containsKey(condition)) {
        conditionScores[condition] = {
          'Strongly Agree': 0,
          'Agree': 0,
          'Neutral': 0,
          'Disagree': 0,
          'Strongly Disagree': 0,
        };
      }
      
      if (conditionScores[condition]!.containsKey(answer)) {
        conditionScores[condition]![answer] = conditionScores[condition]![answer]! + 1;
      }
    }
    
    // Calculate likelihood scores (simple algorithm)
    Map<String, String> results = {};
    conditionScores.forEach((condition, scores) {
      int agreeCount = (scores['Strongly Agree'] ?? 0) + (scores['Agree'] ?? 0);
      int totalQuestions = responses.where((r) => r['condition'] == condition).length;
      double percentage = (agreeCount / totalQuestions) * 100;
      
      String likelihood;
      if (percentage >= 70) {
        likelihood = "High likelihood";
      } else if (percentage >= 40) {
        likelihood = "Moderate likelihood";
      } else {
        likelihood = "Low likelihood";
      }
      
      results[condition] = likelihood;
    });
    
    // Add disclaimer
    results['Disclaimer'] = 'This is a preliminary screening tool, not a clinical diagnosis. For a comprehensive evaluation, please consult a healthcare professional.';
    
    return results;
  }
}

// QuestionPage: Displays a single question with radio buttons
class QuestionPage extends StatefulWidget {
  final Map<String, dynamic> question;
  final String? selectedAnswer;
  final Function(String) onAnswerSelected;

  QuestionPage({
    required this.question,
    this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  String? _selectedAnswer;
  final List<String> options = [
    'Strongly Agree',
    'Agree',
    'Neutral',
    'Disagree',
    'Strongly Disagree',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAnswer = widget.selectedAnswer;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question['text'],
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          SizedBox(height: 20),
          ...options.map((option) {
            return Card(
              color: _selectedAnswer == option ? Colors.grey[800] : Colors.grey[900],
              margin: EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _selectedAnswer == option 
                      ? Colors.greenAccent 
                      : Colors.grey[700]!,
                  width: 1,
                ),
              ),
              child: RadioListTile<String>(
                title: Text(option, style: TextStyle(color: Colors.white)),
                value: option,
                groupValue: _selectedAnswer,
                activeColor: Colors.greenAccent,
                onChanged: (String? value) {
                  setState(() {
                    _selectedAnswer = value;
                    widget.onAnswerSelected(value!);
                  });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ResultsScreen: Displays the evaluation results
class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  ResultsScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Results', style: TextStyle(color: Colors.greenAccent)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.greenAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Screening Results',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Based on your responses:',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ...result.entries.where((entry) => entry.key != 'Disclaimer').map((entry) {
                    Color indicatorColor;
                    if (entry.value.contains('High')) {
                      indicatorColor = Colors.redAccent;
                    } else if (entry.value.contains('Moderate')) {
                      indicatorColor = Colors.orangeAccent;
                    } else {
                      indicatorColor = Colors.greenAccent;
                    }
                    
                    return Card(
                      color: Colors.grey[900],
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 100,
                              decoration: BoxDecoration(
                                color: indicatorColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: indicatorColor,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _getConditionDescription(entry.key),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.yellowAccent),
                            SizedBox(width: 8),
                            Text(
                              'Important Disclaimer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellowAccent,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          result['Disclaimer'] ?? 'This is a screening tool, not a diagnosis. For a comprehensive evaluation, consult a professional.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.home),
                          label: Text('Return to Home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getConditionDescription(String condition) {
    switch (condition) {
      case 'ADHD':
        return 'Attention Deficit Hyperactivity Disorder involves difficulties with attention, hyperactivity, and impulsivity.';
      case 'Autism':
        return 'Autism Spectrum Disorder affects social interaction, communication, and can involve repetitive behaviors.';
      case 'Dyslexia':
        return 'Dyslexia is a learning disorder that involves difficulty reading due to problems identifying speech sounds.';
      case 'Dyspraxia':
        return 'Dyspraxia affects physical coordination, causing difficulty with movement and coordination.';
      case 'Dyscalculia':
        return 'Dyscalculia involves difficulty understanding numbers and learning math facts.';
      case 'Tourette\'s Syndrome':
        return 'Tourette\'s Syndrome involves involuntary movements and vocalizations called tics.';
      default:
        return 'A neurodevelopmental condition that affects how the brain processes information.';
    }
  }
}