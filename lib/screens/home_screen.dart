import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/route_names.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userEmail;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Refresh user to get the latest data
        await user.reload();
        setState(() {
          userEmail = user.email;
          isLoading = false;
        });
      } else {
        setState(() {
          userEmail = 'Guest User';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting user data: $e');
      setState(() {
        userEmail = 'Guest User';
        isLoading = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, RouteNames.login);
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'NeuroAssist',
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // User email display
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  userEmail ?? 'Guest User',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          // Logout button
          IconButton(
            icon: Icon(Icons.logout, color: Colors.greenAccent),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome message with user email
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Welcome,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            userEmail ?? 'Guest User',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Feature buttons
                    _buildFeatureButton(
                      context,
                      icon: Icons.person,
                      label: 'Profile',
                      onPressed: () => Navigator.pushNamed(context, RouteNames.profile),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFeatureButton(
                      context,
                      icon: Icons.settings,
                      label: 'Settings',
                      onPressed: () => Navigator.pushNamed(context, RouteNames.settings),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFeatureButton(
                      context,
                      icon: Icons.record_voice_over,
                      label: 'Text to Speech & Speech to Text',
                      onPressed: () => Navigator.pushNamed(context, RouteNames.ttsStt),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFeatureButton(
                      context,
                      icon: Icons.timer,
                      label: 'Pomodoro Timer',
                      onPressed: () => Navigator.pushNamed(context, RouteNames.habit),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.greenAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 16),
            Icon(icon, size: 24),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16),
            SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}