import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NumberLineScreen extends StatefulWidget {
  const NumberLineScreen({Key? key}) : super(key: key);

  @override
  _NumberLineScreenState createState() => _NumberLineScreenState();
}

class _NumberLineScreenState extends State<NumberLineScreen> {
  int xPosition = 0;
  int yPosition = 0;
  int stepSize = 1;
  List<int> stepOptions = [1, 2, 5, 10];
  String? userEmail;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        userEmail = user?.email;
        isLoading = false;
      });
    } catch (e) {
      print('Error getting user data: $e');
      setState(() {
        userEmail = null;
        isLoading = false;
      });
    }
  }

  void move(String direction) {
    setState(() {
      if (direction == 'left') xPosition -= stepSize;
      if (direction == 'right') xPosition += stepSize;
      if (direction == 'up') yPosition += stepSize;
      if (direction == 'down') yPosition -= stepSize;
    });
  }

  void performOperation(String operation) {
    setState(() {
      if (operation == '+') xPosition += yPosition;
      if (operation == '-') xPosition -= yPosition;
      if (operation == '×') xPosition *= yPosition;
      if (operation == '÷' && yPosition != 0) xPosition ~/= yPosition;
    });
  }
  
  void resetPositions() {
    setState(() {
      xPosition = 0;
      yPosition = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Interactive Number Line',
          style: TextStyle(color: Colors.greenAccent),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.greenAccent),
        elevation: 0,
        actions: [
          if (!isLoading && userEmail != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  userEmail!,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : SafeArea(
              child: Stack(
                children: [
                  // Information Panel (Top)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Position: ($xPosition, $yPosition)',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              DropdownButton<int>(
                                value: stepSize,
                                dropdownColor: Colors.grey[850],
                                style: const TextStyle(color: Colors.greenAccent),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
                                underline: Container(
                                  height: 2,
                                  color: Colors.greenAccent,
                                ),
                                onChanged: (newValue) {
                                  setState(() {
                                    stepSize = newValue!;
                                  });
                                },
                                items: stepOptions
                                    .map((size) => DropdownMenuItem(
                                          value: size,
                                          child: Text("Step: $size"),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Use arrow keys to move, operations to calculate.",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Number Line & Marker
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double unitSize = 40;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildNumberLine(constraints.maxWidth),
                            _buildVerticalNumberLine(constraints.maxHeight),
                            Positioned(
                              left: (constraints.maxWidth / 2) + (xPosition * unitSize) - 20,
                              top: (constraints.maxHeight / 2) - (yPosition * unitSize) - 20,
                              child: _marker(Colors.greenAccent, xPosition, yPosition),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  
                  // Control Buttons (Bottom)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _controlButton("↑", () => move('up')),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _controlButton("←", () => move('left')),
                              const SizedBox(width: 8),
                              _controlButton("↓", () => move('down')),
                              const SizedBox(width: 8),
                              _controlButton("→", () => move('right')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _operationButton("+", () => performOperation('+')),
                              _operationButton("-", () => performOperation('-')),
                              _operationButton("×", () => performOperation('×')),
                              _operationButton("÷", () => performOperation('÷')),
                              _resetButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNumberLine(double width) {
    return CustomPaint(
      size: Size(width, 2),
      painter: NumberLinePainter(),
    );
  }

  Widget _buildVerticalNumberLine(double height) {
    return CustomPaint(
      size: Size(2, height),
      painter: VerticalNumberLinePainter(),
    );
  }

  Widget _marker(Color color, int xValue, int yValue) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '($xValue,$yValue)',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _controlButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.greenAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.all(16),
        elevation: 4,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _operationButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 4,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _resetButton() {
    return ElevatedButton(
      onPressed: resetPositions,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[400],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 4,
      ),
      child: const Text(
        "Reset",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class NumberLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2;

    double centerX = size.width / 2;
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);

    for (int i = -10; i <= 10; i++) {
      double x = centerX + i * 40;
      canvas.drawLine(Offset(x, -10), Offset(x, 10), paint);

      // Major tick marks with labels
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(color: Colors.greenAccent, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 7, 15));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class VerticalNumberLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2;

    double centerY = size.height / 2;
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);

    for (int i = -10; i <= 10; i++) {
      double y = centerY - i * 40;
      canvas.drawLine(Offset(-10, y), Offset(10, y), paint);

      // Major tick marks with labels
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(color: Colors.greenAccent, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(15, y - 7));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}