import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIAssistanceScreen extends StatefulWidget {
  const AIAssistanceScreen({Key? key}) : super(key: key);

  @override
  _AIAssistanceScreenState createState() => _AIAssistanceScreenState();
}

class _AIAssistanceScreenState extends State<AIAssistanceScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  String? userEmail;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email;
    
    // Add a welcome message
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({
          "sender": "ai", 
          "text": "Hello${userEmail != null ? ' ' + userEmail!.split('@').first : ''}! I'm NeuroAI, your medical assistant. How can I help you today?"
        });
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final userMessage = _messageController.text;
      setState(() {
        _messages.add({"sender": "user", "text": userMessage});
        _isTyping = true;
        _messageController.clear();
      });
      
      _scrollToBottom();

      // Simulate AI thinking time
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        _messages.add({"sender": "ai", "text": _generateAIResponse(userMessage)});
        _isTyping = false;
      });
      
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateAIResponse(String query) {
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains("headache") || lowerQuery.contains("head pain")) {
      return "If you're experiencing persistent headaches, I recommend staying hydrated, getting adequate rest, and avoiding triggers like bright lights or loud noises. If the headache is severe or accompanied by other symptoms, please consult a neurologist for proper evaluation.";
    } 
    else if (lowerQuery.contains("dyslexia")) {
      return "Dyslexia is a learning disorder that affects reading, spelling, and writing. It's not related to intelligence but involves difficulty processing language. Specialized educational approaches and assistive technologies can significantly help manage dyslexia. A neuropsychological evaluation is recommended for diagnosis.";
    } 
    else if (lowerQuery.contains("adhd")) {
      return "ADHD (Attention-Deficit/Hyperactivity Disorder) involves persistent patterns of inattention, hyperactivity, and impulsivity. Treatment typically includes behavioral therapy, educational support, and sometimes medication. I recommend consulting a neurologist or psychiatrist who specializes in ADHD for a comprehensive evaluation.";
    }
    else if (lowerQuery.contains("autism") || lowerQuery.contains("asd")) {
      return "Autism Spectrum Disorder (ASD) is a developmental condition that affects social interaction, communication, and behavior. Every person with autism has unique strengths and challenges. Early intervention with therapies like speech therapy, occupational therapy, and behavioral therapy can be very helpful. A developmental pediatrician or neurologist can provide a proper evaluation.";
    }
    else if (lowerQuery.contains("tourette") || lowerQuery.contains("tics")) {
      return "Tourette's Syndrome is a neurological disorder characterized by repetitive, involuntary movements and vocalizations called tics. Many people with Tourette's lead full, productive lives. Treatment options include behavioral therapy, medication, and supportive care. A neurologist can provide proper diagnosis and treatment recommendations.";
    }
    else if (lowerQuery.contains("dyscalculia")) {
      return "Dyscalculia is a learning disability that affects one's ability to understand and work with numbers and mathematical concepts. It's not related to intelligence. Educational interventions, specialized teaching methods, and assistive technologies can help manage dyscalculia. An educational psychologist can provide a proper evaluation.";
    }
    else if (lowerQuery.contains("dyspraxia") || lowerQuery.contains("motor")) {
      return "Dyspraxia (Developmental Coordination Disorder) affects physical coordination and motor skills. It can impact fine and gross motor skills, balance, and spatial awareness. Occupational therapy, physical therapy, and specialized educational support can be beneficial. A neurologist or developmental pediatrician can provide a proper diagnosis.";
    }
    else if (lowerQuery.contains("doctor") || lowerQuery.contains("specialist") || lowerQuery.contains("appointment")) {
      return "If you need to see a specialist, you can use our app to book an appointment with a qualified neurologist who specializes in your specific condition. Would you like me to help you find the right doctor for your needs?";
    }
    else if (lowerQuery.contains("hi") || lowerQuery.contains("hello") || lowerQuery.contains("hey")) {
      return "Hello! I'm here to help with questions about neurological conditions. How can I assist you today?";
    }
    
    return "I'm here to assist with questions about neurological conditions and neurodiversity. Could you provide more details about your concern so I can give you more specific information? Or you can ask about specific conditions like ADHD, dyslexia, autism, dyspraxia, dyscalculia, or Tourette's syndrome.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "NeuroAI Assistant",
          style: TextStyle(color: Colors.greenAccent),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.greenAccent),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (userEmail != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Logged in as: $userEmail",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy_outlined,
                            size: 60,
                            color: Colors.greenAccent,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "NeuroAI Assistant",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            "Ask me any questions about neurological conditions or neurodiversity",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message["sender"] == "user";
                      
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          margin: EdgeInsets.only(
                            top: 8,
                            bottom: 8,
                            left: isUser ? 64 : 0,
                            right: isUser ? 0 : 64,
                          ),
                          decoration: BoxDecoration(
                            color: isUser 
                                ? Colors.greenAccent.withOpacity(0.9) 
                                : Colors.grey[800],
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isUser ? Radius.circular(0) : Radius.circular(16),
                              bottomLeft: isUser ? Radius.circular(16) : Radius.circular(0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.smart_toy,
                                        size: 14,
                                        color: Colors.greenAccent,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "NeuroAI",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.greenAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Text(
                                message["text"] ?? "",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isUser ? Colors.black : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // AI typing indicator
          if (_isTyping)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomLeft: Radius.circular(0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (index) {
                          return Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "NeuroAI is typing...",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Quick suggestion chips
          if (!_isTyping && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSuggestionChip("What is ADHD?"),
                    _buildSuggestionChip("Tell me about dyslexia"),
                    _buildSuggestionChip("Autism symptoms"),
                    _buildSuggestionChip("Tourette's syndrome"),
                    _buildSuggestionChip("Find a specialist"),
                  ],
                ),
              ),
            ),
          
          // Input area
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Ask about neurological conditions...",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send_rounded, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(text),
        labelStyle: TextStyle(color: Colors.white, fontSize: 12),
        backgroundColor: Colors.grey[800],
        side: BorderSide(color: Colors.grey[700]!),
        onPressed: () {
          _messageController.text = text;
          _sendMessage();
        },
      ),
    );
  }
}