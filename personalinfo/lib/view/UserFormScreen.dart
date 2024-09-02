import 'package:flutter/material.dart';
import '../controller/userUserController.dart';
import '../model/user_info.dart';
import 'package:provider/provider.dart';

// UserFormScreen
class UserFormScreen extends StatefulWidget {
  final int? userIndex; // Index for editing, null for new user

  UserFormScreen({this.userIndex});

  @override
  _UserFormScreenState createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late int age;
  late String email;
  late String dob;
  late String gender;
  late String employmentStatus;
  late String address;

  @override
  void initState() {
    super.initState();
    final userController = Provider.of<UserController>(context, listen: false);
    if (widget.userIndex != null) {
      // Populate fields with existing user data if editing
      final user = userController.users[widget.userIndex!];
      name = user.name;
      age = user.age;
      email = user.email;
      dob = user.dob;
      gender = user.gender;
      employmentStatus = user.employmentStatus;
      address = user.address;
    } else {
      // Default values for new user
      name = '';
      age = 0;
      email = '';
      dob = '';
      gender = '';
      employmentStatus = '';
      address = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = Provider.of<UserController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userIndex == null ? 'Add User' : 'Edit User'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: InputDecoration(labelText: 'Name',hintText: 'Enter Your Name'),
                  validator: (value) => value!.isEmpty ? 'Enter Name' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  initialValue: age.toString(),
                  decoration: InputDecoration(labelText: 'Age',hintText: 'Enter Your Age 0 to 99'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter Age 0 to 99' : null,
                  onSaved: (value) => age = int.parse(value!),
                ),
                TextFormField(
                  initialValue: email,
                  decoration: InputDecoration(labelText: 'Email',hintText: 'Enter your email e.g: tejeshvi@cdac.in'),
                  validator: (value) => value!.isEmpty ? 'Enter Email' : null,
                  onSaved: (value) => email = value!,
                ),
                TextFormField(
                  initialValue: dob,
                  decoration: InputDecoration(
                    labelText: 'DOB',
                    hintText: 'DD-MM-YYYY',
                  ),
                  validator: (value) => value!.isEmpty
                      ? 'Enter DOB in format DD-MM-YYYY format'
                      : null,
                  onSaved: (value) => dob = value!,
                ),
                TextFormField(
                  initialValue: employmentStatus,
                  decoration: InputDecoration(labelText: 'Employment Status', hintText: 'current company name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter Employment Status' : null,
                  onSaved: (value) => employmentStatus = value!,
                ),
                TextFormField(
                  initialValue: address,
                  decoration: InputDecoration(labelText: 'Address' ,hintText: 'Enter Your City'),
                  validator: (value) => value!.isEmpty ? 'Enter Address' : null,
                  onSaved: (value) => address = value!,
                ),
                TextFormField(
                  initialValue: gender,
                  decoration: const InputDecoration(labelText: 'Gender', hintText: 'Enter Your Gender  e.g :Female'),
                  validator: (value) => value!.isEmpty ? 'Enter Gender' : null,
                  onSaved: (value) => gender = value!,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final newUser = UserInfo(
                        name: name,
                        age: age,
                        email: email,
                        dob: dob,
                        gender: gender,
                        employmentStatus: employmentStatus,
                        address: address,
                        userId: widget.userIndex != null
                            ? userController.users[widget.userIndex!].userId
                            : '', // Use existing userId if editing
                      );

                      if (widget.userIndex == null) {
                        // Add new user and generate/upload PDF
                        userController.addUser(newUser);
                      } else {
                        // Update existing user
                        final userId =
                            userController.users[widget.userIndex!].userId;
                        userController.updateUser(userId, newUser, context);
                      }

                      // Generate and upload PDF
                      String pdfPath =
                          await userController.generatePDF(newUser);
                      await userController.uploadToSFTP(
                          newUser, pdfPath, newUser.name, context);
                      await userController.generateAndUploadPDF(
                          newUser, context);

                      Navigator.pop(context);
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
