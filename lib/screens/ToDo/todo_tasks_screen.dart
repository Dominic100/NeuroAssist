import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:neuroassist/models/todo_list.dart';
import 'package:neuroassist/services/todo_service.dart';
import 'package:neuroassist/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodoTasksScreen extends StatefulWidget {
  final TodoList todoList;

  const TodoTasksScreen({Key? key, required this.todoList}) : super(key: key);

  @override
  _TodoTasksScreenState createState() => _TodoTasksScreenState();
}

class _TodoTasksScreenState extends State<TodoTasksScreen> {
  final TodoService _todoService = TodoService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String get _userEmail => _auth.currentUser?.email ?? 'No user email';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }
  
  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAlarmPermissionGuide() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Enable Exact Alarms',
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To receive timely task reminders:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '1. Open your device Settings\n'
              '2. Go to Apps or Applications\n'
              '3. Find NeuroAssist\n'
              '4. Tap on Permissions\n'
              '5. Select "Alarms & Reminders"\n'
              '6. Enable the permission',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleNotificationSafely(TodoTask task) async {
    if (task.dueDate == null) return;
    
    try {
      await _notificationService.scheduleTaskReminder(task);
    } catch (e) {
      print('Error scheduling notification: $e');
      
      if (e.toString().contains('exact_alarms_not_permitted')) {
        _showAlarmPermissionGuide();
      }
    }
  }
  
  Future<void> _cancelNotificationSafely(String taskId) async {
    try {
      await _notificationService.cancelTaskReminder(taskId);
    } catch (e) {
      print('Error cancelling notification: $e');
    }
  }

  Future<void> _showAddTaskDialog() async {
    _nameController.clear();
    _descriptionController.clear();
    _selectedDate = null;
    _selectedTime = null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Add New Task',
              style: TextStyle(color: Colors.greenAccent),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Task name *',
                      labelStyle: TextStyle(color: Colors.greenAccent),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: Colors.greenAccent),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Due Date (optional)',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _selectedDate != null 
                          ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)
                          : 'No date selected',
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: Colors.greenAccent),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: Colors.greenAccent,
                                      onPrimary: Colors.black,
                                      surface: Colors.grey[900]!,
                                      onSurface: Colors.white,
                                    ),
                                    dialogBackgroundColor: Colors.grey[900],
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate = date;
                              });
                            }
                          },
                        ),
                        if (_selectedDate != null)
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                                _selectedTime = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  if (_selectedDate != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Due Time (optional)',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _selectedTime != null 
                            ? _selectedTime!.format(context)
                            : 'No time selected',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.access_time, color: Colors.greenAccent),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime ?? TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.dark(
                                        primary: Colors.greenAccent,
                                        onPrimary: Colors.black,
                                        surface: Colors.grey[900]!,
                                        onSurface: Colors.white,
                                      ),
                                      dialogBackgroundColor: Colors.grey[900],
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() {
                                  _selectedTime = time;
                                });
                              }
                            },
                          ),
                          if (_selectedTime != null)
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _selectedTime = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text(
                  'Add',
                  style: TextStyle(color: Colors.greenAccent),
                ),
                onPressed: () async {
                  if (_nameController.text.trim().isNotEmpty) {
                    final task = TodoTask(
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim(),
                      dueDate: _selectedDate,
                      dueTime: _selectedTime,
                    );
                    
                    await _todoService.addTask(widget.todoList.id, task);
                    
                    if (_selectedDate != null) {
                      await _scheduleNotificationSafely(task);
                    }
                    
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Task name is required'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditTaskDialog(TodoTask task) async {
    _nameController.text = task.name;
    _descriptionController.text = task.description;
    _selectedDate = task.dueDate;
    _selectedTime = task.dueTime;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Edit Task',
              style: TextStyle(color: Colors.greenAccent),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Task name *',
                      labelStyle: TextStyle(color: Colors.greenAccent),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: Colors.greenAccent),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Due Date (optional)',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _selectedDate != null 
                          ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)
                          : 'No date selected',
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.calendar_today, color: Colors.greenAccent),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365 * 5)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: Colors.greenAccent,
                                      onPrimary: Colors.black,
                                      surface: Colors.grey[900]!,
                                      onSurface: Colors.white,
                                    ),
                                    dialogBackgroundColor: Colors.grey[900],
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate = date;
                              });
                            }
                          },
                        ),
                        if (_selectedDate != null)
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                                _selectedTime = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  if (_selectedDate != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Due Time (optional)',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _selectedTime != null 
                            ? _selectedTime!.format(context)
                            : 'No time selected',
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.access_time, color: Colors.greenAccent),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime ?? TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.dark(
                                        primary: Colors.greenAccent,
                                        onPrimary: Colors.black,
                                        surface: Colors.grey[900]!,
                                        onSurface: Colors.white,
                                      ),
                                      dialogBackgroundColor: Colors.grey[900],
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() {
                                  _selectedTime = time;
                                });
                              }
                            },
                          ),
                          if (_selectedTime != null)
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _selectedTime = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.greenAccent),
                ),
                onPressed: () async {
                  if (_nameController.text.trim().isNotEmpty) {
                    final updatedTask = task.copyWith(
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim(),
                      dueDate: _selectedDate,
                      dueTime: _selectedTime,
                    );
                    
                    await _todoService.updateTask(widget.todoList.id, updatedTask);
                    
                    if (_selectedDate != null) {
                      await _scheduleNotificationSafely(updatedTask);
                    } else {
                      await _cancelNotificationSafely(task.id);
                    }
                    
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Task name is required'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(TodoTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Delete Task',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          'Are you sure you want to delete "${task.name}"?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () async {
              await _todoService.deleteTask(widget.todoList.id, task.id);
              await _cancelNotificationSafely(task.id);
              Navigator.pop(context);
            },
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
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.todoList.name,
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _userEmail,
              style: TextStyle(
                color: Colors.greenAccent.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.greenAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<TodoTask>>(
        stream: _todoService.getTasks(widget.todoList.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }
          
          // Enhanced error handling specifically for Firebase index error
          if (snapshot.hasError) {
            bool isIndexError = snapshot.error.toString().contains('FAILED_PRECONDITION') && 
                               snapshot.error.toString().contains('index');
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  SizedBox(height: 16),
                  Text(
                    isIndexError ? 'Firebase Index Being Created' : 'Error Loading Tasks',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      isIndexError
                          ? 'The required database index is being created. This may take a few minutes. Please try again shortly.'
                          : 'An error occurred: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Force reload
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isIndexError) ...[
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back to lists screen
                      },
                      child: Text(
                        'Go Back to Lists',
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                  ]
                ],
              ),
            );
          }
          
          final allTasks = snapshot.data ?? [];
          final pendingTasks = allTasks.where((task) => !task.isCompleted).toList();
          final completedTasks = allTasks.where((task) => task.isCompleted).toList();
          
          if (allTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 80,
                    color: Colors.greenAccent.withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first task by tapping the + button',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Pending Tasks Section
              Text(
                'Pending Tasks (${pendingTasks.length})',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              if (pendingTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No pending tasks. Good job!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: pendingTasks.length,
                  itemBuilder: (context, index) {
                    final task = pendingTasks[index];
                    return _buildTaskItem(task);
                  },
                ),
              
              // Divider
              if (completedTasks.isNotEmpty) ...[
                SizedBox(height: 24),
                Divider(color: Colors.greenAccent.withOpacity(0.3)),
                SizedBox(height: 8),
                
                // Completed Tasks Section
                Text(
                  'Completed Tasks (${completedTasks.length})',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: completedTasks.length,
                  itemBuilder: (context, index) {
                    final task = completedTasks[index];
                    return _buildTaskItem(task);
                  },
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        child: Icon(Icons.add, color: Colors.black),
        onPressed: _showAddTaskDialog,
      ),
    );
  }

  Widget _buildTaskItem(TodoTask task) {
    final bool isOverdue = task.dueDate != null && 
        !task.isCompleted && 
        task.dueDate!.isBefore(DateTime.now().subtract(Duration(days: 1)));
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: task.isCompleted 
              ? Colors.greenAccent.withOpacity(0.3)
              : isOverdue 
                  ? Colors.redAccent.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: InkWell(
          onTap: () {
            _todoService.toggleTaskComplete(
              widget.todoList.id,
              task,
              !task.isCompleted,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: task.isCompleted ? Colors.greenAccent : Colors.grey,
                width: 2,
              ),
            ),
            padding: EdgeInsets.all(2),
            child: task.isCompleted
                ? Icon(Icons.check, color: Colors.greenAccent, size: 16)
                : SizedBox(width: 16, height: 16),
          ),
        ),
        title: Text(
          task.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                task.description,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (task.dueDate != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: isOverdue ? Colors.redAccent : Colors.greenAccent,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${DateFormat('EEE, MMM d').format(task.dueDate!)}${task.dueTime != null ? ' at ${task.dueTime!.format(context)}' : ''}',
                    style: TextStyle(
                      color: isOverdue ? Colors.redAccent : Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                  if (isOverdue) ...[
                    SizedBox(width: 4),
                    Text(
                      'OVERDUE',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (task.isCompleted && task.completedAt != null) ...[
              SizedBox(height: 4),
              Text(
                'Completed on ${DateFormat('MMM d, yyyy').format(task.completedAt!)}',
                style: TextStyle(
                  color: Colors.greenAccent.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white70),
          color: Colors.grey[850],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditTaskDialog(task);
            } else if (value == 'delete') {
              _showDeleteConfirmation(task);
            } else if (value == 'toggle') {
              _todoService.toggleTaskComplete(
                widget.todoList.id,
                task,
                !task.isCompleted,
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    task.isCompleted ? Icons.radio_button_unchecked : Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    task.isCompleted ? 'Mark as pending' : 'Mark as completed',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}