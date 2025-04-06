import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_appointment_screen.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({Key? key}) : super(key: key);

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final List<Map<String, dynamic>> doctors = [
    {
      "name": "Dr. Alice Johnson",
      "specialty": "Alzheimer's Specialist",
      "rating": 4.8,
      "experience": "12 years",
      "availability": "Mon, Wed, Fri",
      "image": "https://randomuser.me/api/portraits/women/1.jpg"
    },
    {
      "name": "Dr. Bob Smith",
      "specialty": "Dyslexia Expert",
      "rating": 4.7,
      "experience": "10 years",
      "availability": "Tue, Thu, Sat",
      "image": "https://randomuser.me/api/portraits/men/2.jpg"
    },
    {
      "name": "Dr. Carol Adams",
      "specialty": "Epilepsy Specialist",
      "rating": 4.9,
      "experience": "15 years",
      "availability": "Mon, Tue, Wed",
      "image": "https://randomuser.me/api/portraits/women/3.jpg"
    },
    {
      "name": "Dr. Daniel Brown",
      "specialty": "ADHD Specialist",
      "rating": 4.6,
      "experience": "8 years",
      "availability": "Wed, Thu, Fri",
      "image": "https://randomuser.me/api/portraits/men/4.jpg"
    },
    {
      "name": "Dr. Emma Wilson",
      "specialty": "Autism Specialist",
      "rating": 4.7,
      "experience": "11 years",
      "availability": "Mon, Thu, Sat",
      "image": "https://randomuser.me/api/portraits/women/5.jpg"
    },
    {
      "name": "Dr. Frank Miller",
      "specialty": "Tourette's Syndrome Expert",
      "rating": 4.5,
      "experience": "9 years",
      "availability": "Tue, Fri, Sat",
      "image": "https://randomuser.me/api/portraits/men/6.jpg"
    },
    {
      "name": "Dr. Grace White",
      "specialty": "Dyspraxia Expert",
      "rating": 4.8,
      "experience": "13 years",
      "availability": "Mon, Wed, Sat",
      "image": "https://randomuser.me/api/portraits/women/7.jpg"
    },
    {
      "name": "Dr. Henry Clark",
      "specialty": "Dyscalculia Specialist",
      "rating": 4.6,
      "experience": "7 years",
      "availability": "Tue, Thu, Fri",
      "image": "https://randomuser.me/api/portraits/men/8.jpg"
    },
    {
      "name": "Dr. Isabella Martinez",
      "specialty": "Pediatric Neurologist",
      "rating": 4.9,
      "experience": "14 years",
      "availability": "Mon, Wed, Fri",
      "image": "https://randomuser.me/api/portraits/women/9.jpg"
    },
    {
      "name": "Dr. Jack Turner",
      "specialty": "Neurosurgeon",
      "rating": 4.8,
      "experience": "16 years",
      "availability": "Tue, Thu, Sat",
      "image": "https://randomuser.me/api/portraits/men/10.jpg"
    },
  ];

  String? userEmail;
  String _searchQuery = "";
  
  @override
  void initState() {
    super.initState();
    // Get current user's email
    userEmail = FirebaseAuth.instance.currentUser?.email;
  }

  List<Map<String, dynamic>> get filteredDoctors {
    if (_searchQuery.isEmpty) {
      return doctors;
    }
    
    return doctors.where((doctor) {
      final name = doctor['name'].toString().toLowerCase();
      final specialty = doctor['specialty'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || specialty.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Select a Doctor",
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
              child: Text(
                "Logged in as: $userEmail",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by name or specialty",
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.greenAccent),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.greenAccent, width: 1),
                ),
              ),
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip("All Specialists", true),
                _filterChip("Autism", false),
                _filterChip("ADHD", false),
                _filterChip("Dyslexia", false),
                _filterChip("Dyspraxia", false),
                _filterChip("Dyscalculia", false),
              ],
            ),
          ),
          SizedBox(height: 12),
          // Doctor list
          Expanded(
            child: filteredDoctors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[700],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No doctors found",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Try adjusting your search criteria",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredDoctors.length,
                    itemBuilder: (context, index) {
                      final doctor = filteredDoctors[index];
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[800]!, width: 1),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.all(16),
                                leading: Hero(
                                  tag: "doctor-${doctor['name']}",
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(doctor['image']),
                                    radius: 30,
                                    backgroundColor: Colors.grey[800],
                                    onBackgroundImageError: (exception, stackTrace) {
                                      // Handle image loading errors
                                    },
                                  ),
                                ),
                                title: Text(
                                  doctor['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text(
                                      doctor['specialty'],
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          "${doctor['rating']}",
                                          style: TextStyle(color: Colors.amber),
                                        ),
                                        SizedBox(width: 12),
                                        Icon(Icons.work, color: Colors.grey[400], size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          doctor['experience'],
                                          style: TextStyle(color: Colors.grey[400]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookAppointmentScreen(doctor: doctor),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    "Book",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Available: ${doctor['availability']}",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        // Show doctor details
                                        _showDoctorDetails(context, doctor);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.grey[400],
                                      ),
                                      child: Text("VIEW DETAILS"),
                                    ),
                                  ],
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

  Widget _filterChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey[800],
        selectedColor: Colors.greenAccent,
        onSelected: (bool selected) {
          // Implement filter functionality
          setState(() {
            // In a real app, you would filter based on this selection
          });
        },
      ),
    );
  }

  void _showDoctorDetails(BuildContext context, Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 10),
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor profile header
                    Row(
                      children: [
                        Hero(
                          tag: "doctor-${doctor['name']}-detail",
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(doctor['image']),
                            radius: 40,
                            backgroundColor: Colors.grey[800],
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                doctor['specialty'],
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    "${doctor['rating']}",
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.work, color: Colors.grey[400], size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    doctor['experience'],
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Info sections
                    _infoSection("About", 
                      "Dr. ${doctor['name'].toString().split(' ')[1]} specializes in treating patients with ${doctor['specialty'].toString().toLowerCase().replaceAll('specialist', '').replaceAll('expert', '').trim()}. With ${doctor['experience']} of clinical practice, they have helped numerous patients manage their conditions effectively."
                    ),
                    
                    _infoSection("Availability", 
                      "Available on: ${doctor['availability']}\nAppointment duration: 45 minutes\nNext available slot: Tomorrow"
                    ),
                    
                    _infoSection("Patient Reviews", 
                      "\"Excellent doctor, very thorough and caring. Helped me understand my condition better.\" - Recent Patient"
                    ),
                    
                    // Buttons
                    Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey[700]!),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text("CLOSE"),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookAppointmentScreen(doctor: doctor),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              "BOOK APPOINTMENT",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
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

  Widget _infoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}