import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../controller/userUserController.dart';
import '../view/UserFormScreen.dart';
import 'package:flutter/services.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    final userController = Provider.of<UserController>(context, listen: false);
    userController.fetchUsers();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User List')),
      body: _isConnected
          ? Consumer<UserController>(
              builder: (context, userController, child) {
                if (userController.users.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: userController.users.length,
                  itemBuilder: (context, index) {
                    final user = userController.users[index];
                    return Card(
                      elevation: 5,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(
                          user.name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserFormScreen(userIndex: index),
                                  ),
                                );
                              },
                              tooltip: 'Edit User',
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                final userId =
                                    userController.users[index].userId;
                                print(
                                    'Attempting to delete user with ID: $userId');

                                if (userId.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete User'),
                                      content: Text(
                                          'Are you sure you want to delete ${user.name}?'),
                                      actions: [
                                        TextButton(
                                          child: Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Delete'),
                                          onPressed: () {
                                            userController.deleteUser(userId);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  print('User ID is null or empty');
                                }
                              },
                              tooltip: 'Delete User',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : Center(
              child: Image.asset('assets/images/no-internet.png'),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserFormScreen()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
        tooltip: 'Add User',
      ),
    );
  }
}
