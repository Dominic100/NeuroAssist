import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({Key? key}) : super(key: key);

  @override
  _MyAppointmentsScreenState createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  List<Map<String, String>> _appointments = [
    {
      "doctor": "Dr. Alice Johnson",
      "specialty": "Alzheimer's Specialist",
      "date": "2025-04-10",
      "time": "10:30 AM",
      "image": "https://randomuser.me/api/portraits/women/10.jpg"
    },
    {
      "doctor": "Dr. Daniel Brown",
      "specialty": "ADHD Specialist",
      "date": "2025-04-12",
      "time": "3:00 PM",
      "image": "https://randomuser.me/api/portraits/men/13.jpg"
    }
  ];

  String? userEmail;

  @override
  void initState() {
    super.initState();
    // Get current user's email
    userEmail = FirebaseAuth.instance.currentUser?.email;
  }

  void _cancelAppointment(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Cancel Appointment",
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: Text(
          "Are you sure you want to cancel your appointment with ${_appointments[index]['doctor']}?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
            child: Text("NO"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _appointments.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Appointment cancelled",
                    style: TextStyle(color: Colors.black),
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text("YES, CANCEL"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "My Appointments",
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
            child: _appointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 80,
                          color: Colors.grey[700],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No upcoming appointments",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.add),
                          label: Text("BOOK NEW APPOINTMENT"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _appointments[index];
                      // Parse the date for styling
                      final date = DateTime.parse(appointment['date']!);
                      final isUpcoming = date.isAfter(DateTime.now());

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isUpcoming ? Colors.greenAccent.withOpacity(0.3) : Colors.grey[800]!,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(appointment['image']!),
                                    radius: 30,
                                    backgroundColor: Colors.grey[800],
                                    onBackgroundImageError: (exception, stackTrace) {
                                      // Handle image loading errors
                                    },
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appointment['doctor']!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          appointment['specialty']!,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.cancel_outlined, color: Colors.redAccent),
                                    onPressed: () => _cancelAppointment(index),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _infoColumn(
                                      Icons.calendar_today,
                                      "Date",
                                      _formatDate(appointment['date']!),
                                    ),
                                    _infoColumn(
                                      Icons.access_time,
                                      "Time",
                                      appointment['time']!,
                                    ),
                                    _infoColumn(
                                      Icons.person,
                                      "Patient",
                                      userEmail?.split('@').first ?? "You",
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      // This would open a reschedule dialog
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Reschedule feature coming soon",
                                            style: TextStyle(color: Colors.black),
                                          ),
                                          backgroundColor: Colors.amberAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.calendar_month),
                                    label: Text("RESCHEDULE"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.amberAccent,
                                      side: BorderSide(color: Colors.amberAccent),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // This would navigate to appointment details
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Details feature coming soon",
                                            style: TextStyle(color: Colors.black),
                                          ),
                                          backgroundColor: Colors.greenAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.info_outline),
                                    label: Text("DETAILS"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent,
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                ],
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

  Widget _infoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 18),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month) {
      if (date.day == now.day) {
        return "Today";
      } else if (date.day == now.day + 1) {
        return "Tomorrow";
      }
    }
    
    final months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    
    return "${date.day} ${months[date.month - 1]}";
  }
}