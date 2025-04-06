import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopDoctorsScreen extends StatefulWidget {
  const TopDoctorsScreen({Key? key}) : super(key: key);

  @override
  State<TopDoctorsScreen> createState() => _TopDoctorsScreenState();
}

class _TopDoctorsScreenState extends State<TopDoctorsScreen> {
  final List<Map<String, dynamic>> topDoctors = [
    {
      "name": "Dr. A. Sharma",
      "specialty": "Neurologist - Brain Stroke Specialist",
      "rating": 4.9,
      "image": "https://randomuser.me/api/portraits/men/1.jpg"
    },
    {
      "name": "Dr. B. Patil",
      "specialty": "Autism Specialist",
      "rating": 4.7,
      "image": "https://randomuser.me/api/portraits/men/2.jpg"
    },
    {
      "name": "Dr. C. Nair",
      "specialty": "ADHD Expert",
      "rating": 4.8,
      "image": "https://randomuser.me/api/portraits/women/1.jpg"
    },
    {
      "name": "Dr. D. Kulkarni",
      "specialty": "Dyslexia Specialist",
      "rating": 4.6,
      "image": "https://randomuser.me/api/portraits/men/3.jpg"
    },
    {
      "name": "Dr. E. Rao",
      "specialty": "Dyscalculia Specialist",
      "rating": 4.9,
      "image": "https://randomuser.me/api/portraits/men/4.jpg"
    },
    {
      "name": "Dr. F. Deshmukh",
      "specialty": "Dyspraxia Specialist",
      "rating": 4.5,
      "image": "https://randomuser.me/api/portraits/women/2.jpg"
    },
    {
      "name": "Dr. G. Joshi",
      "specialty": "Tourette's Syndrome Specialist",
      "rating": 4.7,
      "image": "https://randomuser.me/api/portraits/men/5.jpg"
    },
    {
      "name": "Dr. H. Mehta",
      "specialty": "Pediatric Neurologist - Autism & ADHD",
      "rating": 4.8,
      "image": "https://randomuser.me/api/portraits/women/3.jpg"
    },
    {
      "name": "Dr. I. Reddy",
      "specialty": "Neurodevelopmental Disorder Specialist",
      "rating": 4.6,
      "image": "https://randomuser.me/api/portraits/men/6.jpg"
    },
    {
      "name": "Dr. J. Thakur",
      "specialty": "Cognitive & Behavioral Neurologist",
      "rating": 4.9,
      "image": "https://randomuser.me/api/portraits/men/7.jpg"
    },
  ];

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
          "Top Neurologists & Specialists",
          style: TextStyle(color: Colors.greenAccent),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.greenAccent),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userEmail != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Logged in as: $userEmail",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: topDoctors.length,
              itemBuilder: (context, index) {
                final doctor = topDoctors[index];

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(doctor['image']),
                      radius: 30,
                      backgroundColor: Colors.grey[800],
                      onBackgroundImageError: (exception, stackTrace) {
                        // Handle image loading errors
                      },
                    ),
                    title: Text(
                      doctor['name'], 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctor['specialty'],
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text(
                                "${doctor['rating']}",
                                style: TextStyle(color: Colors.amber),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        _showDoctorDetails(context, doctor);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Details"),
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

  void _showDoctorDetails(BuildContext context, Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            doctor['name'],
            style: TextStyle(color: Colors.greenAccent),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    doctor['image'], 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person, 
                        size: 80,
                        color: Colors.greenAccent,
                      );
                    }
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.medical_services_outlined, 
                      "Specialization", 
                      doctor['specialty']
                    ),
                    SizedBox(height: 10),
                    _infoRow(
                      Icons.star, 
                      "Rating", 
                      "${doctor['rating']}"
                    ),
                    if (userEmail != null) ...[
                      SizedBox(height: 10),
                      _infoRow(
                        Icons.email_outlined, 
                        "Your Email", 
                        userEmail!
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[400],
              ),
              child: Text("CLOSE"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Here you would navigate to appointment booking
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Booking appointment with ${doctor['name']}...",
                      style: TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.greenAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
              ),
              child: Text("BOOK APPOINTMENT"),
            ),
          ],
        );
      },
    );
  }
  
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}