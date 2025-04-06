import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const BookAppointmentScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedReason;
  String? userEmail;
  bool isVirtualAppointment = false;

  final List<String> reasonOptions = [
    "Initial Consultation",
    "Follow-up Appointment",
    "Test Results Review",
    "Treatment Discussion",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email;
  }

  void _selectDate() async {
    final ThemeData theme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.dark(
        primary: Colors.greenAccent,
        onPrimary: Colors.black,
        surface: Colors.grey[900]!,
        onSurface: Colors.white,
      ),
      dialogBackgroundColor: Colors.grey[900],
    );

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: theme,
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void _selectTime() async {
    final ThemeData theme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.dark(
        primary: Colors.greenAccent,
        onPrimary: Colors.black,
        surface: Colors.grey[900]!,
        onSurface: Colors.white,
      ),
      dialogBackgroundColor: Colors.grey[900],
    );

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: theme,
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  void _confirmBooking() {
    if (selectedDate == null || selectedTime == null || selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a date, time, and reason for your appointment",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Confirm Appointment",
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmationRow(
              Icons.person, 
              "Doctor", 
              widget.doctor['name']
            ),
            SizedBox(height: 12),
            _buildConfirmationRow(
              Icons.medical_services_outlined, 
              "Specialty", 
              widget.doctor['specialty']
            ),
            SizedBox(height: 12),
            _buildConfirmationRow(
              Icons.calendar_today, 
              "Date", 
              DateFormat.yMMMMd().format(selectedDate!)
            ),
            SizedBox(height: 12),
            _buildConfirmationRow(
              Icons.access_time, 
              "Time", 
              selectedTime!.format(context)
            ),
            SizedBox(height: 12),
            _buildConfirmationRow(
              Icons.medical_information_outlined, 
              "Reason", 
              selectedReason!
            ),
            SizedBox(height: 12),
            _buildConfirmationRow(
              Icons.videocam_outlined, 
              "Type", 
              isVirtualAppointment ? "Virtual Appointment" : "In-person Visit"
            ),
            if (userEmail != null) ...[
              SizedBox(height: 12),
              _buildConfirmationRow(
                Icons.email_outlined, 
                "Email", 
                userEmail!
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
            child: Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Display toast message
              Fluttertoast.showToast(
                msg: "Appointment confirmed!",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.green,
                textColor: Colors.white,
              );
              
              // Show success dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: Text(
                    "Appointment Scheduled!",
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.greenAccent,
                          size: 60,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Your appointment has been successfully scheduled with ${widget.doctor['name']} on ${DateFormat.yMMMMd().format(selectedDate!)} at ${selectedTime!.format(context)}.",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "A confirmation email has been sent to ${userEmail ?? 'your email'}.",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: Text("DONE"),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            child: Text("CONFIRM"),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 18),
        SizedBox(width: 12),
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
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Book Appointment",
          style: TextStyle(color: Colors.greenAccent),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.greenAccent),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userEmail != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "Logged in as: $userEmail",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ),
              // Doctor info card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: "doctor-${widget.doctor['name']}-booking",
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(widget.doctor['image']),
                        radius: 40,
                        backgroundColor: Colors.grey[800],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.doctor['name'],
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.doctor['specialty'], 
                            style: TextStyle(
                              fontSize: 16, 
                              color: Colors.greenAccent,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text(
                                "${widget.doctor['rating']}",
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Date selection
              _buildSectionTitle("Select Date", Icons.calendar_today),
              SizedBox(height: 12),
              Container(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10, // Show next 10 days
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index));
                    final isSelected = selectedDate != null &&
                        selectedDate!.year == date.year &&
                        selectedDate!.month == date.month &&
                        selectedDate!.day == date.day;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                      child: Container(
                        width: 70,
                        margin: EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.greenAccent : Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.greenAccent : Colors.grey[800]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(date), // Day of week
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.grey[400],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              DateFormat('d').format(date), // Day number
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              DateFormat('MMM').format(date), // Month
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: _selectDate,
                icon: Icon(Icons.date_range, size: 18),
                label: Text("Select specific date"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[400],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Time selection
              _buildSectionTitle("Select Time", Icons.access_time),
              SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildTimeChip(TimeOfDay(hour: 9, minute: 0)),
                  _buildTimeChip(TimeOfDay(hour: 9, minute: 30)),
                  _buildTimeChip(TimeOfDay(hour: 10, minute: 0)),
                  _buildTimeChip(TimeOfDay(hour: 10, minute: 30)),
                  _buildTimeChip(TimeOfDay(hour: 11, minute: 0)),
                  _buildTimeChip(TimeOfDay(hour: 11, minute: 30)),
                  _buildTimeChip(TimeOfDay(hour: 14, minute: 0)),
                  _buildTimeChip(TimeOfDay(hour: 14, minute: 30)),
                  _buildTimeChip(TimeOfDay(hour: 15, minute: 0)),
                  _buildTimeChip(TimeOfDay(hour: 15, minute: 30)),
                  _buildTimeChip(TimeOfDay(hour: 16, minute: 0)),
                  _buildTimeChip(TimeOfDay(hour: 16, minute: 30)),
                ],
              ),
              SizedBox(height: 8),
              TextButton.icon(
                onPressed: _selectTime,
                icon: Icon(Icons.more_time, size: 18),
                label: Text("Select specific time"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[400],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Reason selection
              _buildSectionTitle("Reason for Visit", Icons.medical_information_outlined),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedReason,
                    hint: Text(
                      "Select a reason", 
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    style: TextStyle(color: Colors.white),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
                    items: reasonOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedReason = newValue;
                      });
                    },
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Appointment type
              _buildSectionTitle("Appointment Type", Icons.videocam_outlined),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isVirtualAppointment = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: !isVirtualAppointment ? Colors.greenAccent.withOpacity(0.1) : Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isVirtualAppointment ? Colors.greenAccent : Colors.grey[800]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person,
                              color: !isVirtualAppointment ? Colors.greenAccent : Colors.grey[400],
                              size: 30,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "In-person",
                              style: TextStyle(
                                color: !isVirtualAppointment ? Colors.greenAccent : Colors.grey[400],
                                fontWeight: !isVirtualAppointment ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isVirtualAppointment = true;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isVirtualAppointment ? Colors.greenAccent.withOpacity(0.1) : Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isVirtualAppointment ? Colors.greenAccent : Colors.grey[800]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.videocam,
                              color: isVirtualAppointment ? Colors.greenAccent : Colors.grey[400],
                              size: 30,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Virtual",
                              style: TextStyle(
                                color: isVirtualAppointment ? Colors.greenAccent : Colors.grey[400],
                                fontWeight: isVirtualAppointment ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 32),
              
              // Confirm button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "CONFIRM APPOINTMENT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeChip(TimeOfDay time) {
    final isSelected = selectedTime != null &&
        selectedTime!.hour == time.hour &&
        selectedTime!.minute == time.minute;
    
    return ChoiceChip(
      label: Text(time.format(context)),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selected: isSelected,
      selectedColor: Colors.greenAccent,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.greenAccent : Colors.grey[800]!,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedTime = time;
          });
        }
      },
    );
  }
}