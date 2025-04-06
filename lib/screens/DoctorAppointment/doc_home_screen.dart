import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_list_screen.dart';
import 'top_doctors_screen.dart'; 
import 'ai_assisstance_screen.dart'; 
import 'my_appointments_screen.dart';

class DocHomeScreen extends StatefulWidget {
  const DocHomeScreen({Key? key}) : super(key: key);

  @override
  State<DocHomeScreen> createState() => _DocHomeScreenState();
}

class _DocHomeScreenState extends State<DocHomeScreen> {
  String? userEmail;

  @override
  void initState() {
    super.initState();
    // Get current user's email
    userEmail = FirebaseAuth.instance.currentUser?.email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Doctor-Patient Connect",
          style: TextStyle(color: Colors.greenAccent),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.greenAccent),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.greenAccent),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Search functionality coming soon",
                    style: TextStyle(color: Colors.black),
                  ),
                  backgroundColor: Colors.greenAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userEmail != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      radius: 20,
                      child: Icon(
                        Icons.person,
                        color: Colors.greenAccent,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome back,",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            userEmail!.split('@').first,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              "Find the Best Neurologists",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Connect with specialists for neurodiversity conditions",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _featureCard(
                    "Book Appointment", 
                    Icons.calendar_today, 
                    "Find and schedule appointments with specialists",
                    Colors.blue[700]!,
                    context,
                  ),
                  _featureCard(
                    "Top Doctors", 
                    Icons.medical_services, 
                    "Highest rated neurologists and specialists",
                    Colors.purple[700]!,
                    context,
                  ),
                  _featureCard(
                    "AI Assistance", 
                    Icons.smart_toy, 
                    "Get AI help with finding the right doctor",
                    Colors.orange[800]!,
                    context,
                  ),
                  _featureCard(
                    "My Appointments", 
                    Icons.list_alt, 
                    "View and manage your scheduled appointments",
                    Colors.teal[700]!,
                    context,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(String title, IconData icon, String description, Color accentColor, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == "Book Appointment") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorListScreen()));
        } else if (title == "Top Doctors") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => TopDoctorsScreen()));
        } else if (title == "AI Assistance") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AIAssistanceScreen()));
        } else if (title == "My Appointments") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => MyAppointmentsScreen()));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon, 
                      size: 30, 
                      color: Colors.greenAccent,
                    ),
                  ),
                  Spacer(),
                  Text(
                    title, 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}