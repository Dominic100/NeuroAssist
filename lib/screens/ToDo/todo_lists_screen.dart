import 'package:flutter/material.dart';
import 'package:neuroassist/models/todo_list.dart';
import 'package:neuroassist/services/todo_service.dart';
import 'package:neuroassist/screens/ToDo/todo_tasks_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodoListsScreen extends StatefulWidget {
  const TodoListsScreen({Key? key}) : super(key: key);

  @override
  _TodoListsScreenState createState() => _TodoListsScreenState();
}

class _TodoListsScreenState extends State<TodoListsScreen> {
  final TodoService _todoService = TodoService();
  final TextEditingController _newListController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String get _userEmail => _auth.currentUser?.email ?? 'No user email';
  
  @override
  void initState() {
    super.initState();
    // Verify user is logged in
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAuthError();
      });
    }
  }
  
  void _showAuthError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Authentication Error',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          'You must be logged in to access your to-do lists.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: Text(
              'Go back',
              style: TextStyle(color: Colors.greenAccent),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  void _showAddListDialog() {
    _newListController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Create New List',
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: TextField(
          controller: _newListController,
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'List name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.greenAccent),
            ),
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
              'Create',
              style: TextStyle(color: Colors.greenAccent),
            ),
            onPressed: () {
              if (_newListController.text.trim().isNotEmpty) {
                _todoService.createList(
                  TodoList(
                    name: _newListController.text.trim(),
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditListDialog(TodoList list) {
    _newListController.text = list.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Edit List',
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: TextField(
          controller: _newListController,
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'List name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.greenAccent),
            ),
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
            onPressed: () {
              if (_newListController.text.trim().isNotEmpty) {
                _todoService.updateList(
                  TodoList(
                    id: list.id,
                    name: _newListController.text.trim(),
                    color: list.color,
                    createdAt: list.createdAt,
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(TodoList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Delete List',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          'Are you sure you want to delete "${list.name}" and all its tasks? This cannot be undone.',
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
            onPressed: () {
              _todoService.deleteList(list.id);
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
              'To-Do Lists',
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
      body: StreamBuilder<List<TodoList>>(
        stream: _todoService.getLists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }
          
          if (snapshot.hasError) {
            bool isPermissionError = snapshot.error.toString().contains('permission-denied');
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
                    isPermissionError 
                        ? 'Authentication Error' 
                        : isIndexError 
                            ? 'Database Index Being Created'
                            : 'Error Loading Lists',
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
                      isPermissionError
                          ? 'You don\'t have permission to access these lists. Please ensure you\'re signed in with the correct account: $_userEmail'
                          : isIndexError
                              ? 'Please wait while we set up your database. This may take a minute.'
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
                  if (isPermissionError) ...[
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back
                      },
                      child: Text(
                        'Go Back',
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          
          final lists = snapshot.data ?? [];
          
          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 80,
                    color: Colors.greenAccent.withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No to-do lists yet',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first list by tapping the + button',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.greenAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.greenAccent,
                    child: Icon(
                      Icons.list_alt,
                      color: Colors.black,
                    ),
                  ),
                  title: Text(
                    list.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Created on ${_formatDate(list.createdAt)}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.greenAccent),
                    color: Colors.grey[850],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditListDialog(list);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(list);
                      }
                    },
                    itemBuilder: (context) => [
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TodoTasksScreen(todoList: list),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        child: Icon(Icons.add, color: Colors.black),
        onPressed: _showAddListDialog,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}