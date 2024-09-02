import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

import '../model/user_info.dart';
import '../view/PDFViewPage.dart';

class UserController with ChangeNotifier {
  List<UserInfo> users = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  void addUser(UserInfo user) async {
    final docRef = _db.collection('users').doc();
    await docRef.set({
      'name': user.name,
      'age': user.age,
      'email': user.email,
      'dob': user.dob,
      'gender': user.gender,
      'employmentStatus': user.employmentStatus,
      'address': user.address,
    });
    fetchUsers();
    notifyListeners();
  }

  void updateUser(
      String documentId, UserInfo updatedUser, BuildContext context) async {
    try {
      await _db.collection('users').doc(documentId).update({
        'name': updatedUser.name,
        'age': updatedUser.age,
        'email': updatedUser.email,
        'dob': updatedUser.dob,
        'gender': updatedUser.gender,
        'employmentStatus': updatedUser.employmentStatus,
        'address': updatedUser.address,
      });
      print('User updated successfully');
      fetchUsers(); // Optionally refresh the list
      await generateAndUploadPDF(updatedUser, context);
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  UserController() {
    fetchUsers(); // Fetch users when the controller is created
  }

  // Fetch users from Firebase
  void fetchUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      print('Documents found: ${snapshot.docs.length}'); // Debugging output

      if (snapshot.docs.isEmpty) {
        print('No documents found.');
      } else {
        print('Documents retrieved:');
      }

      users = snapshot.docs.map((doc) {
        final data = doc.data();
        final documentId = doc.id; // Correctly retrieve the document ID

        print('Fetched Document ID: $documentId'); // Debugging output
        print('User data: $data'); // Debugging output

        return UserInfo(
          userId: documentId, // Set document ID correctly
          name: data['name'] ?? '',
          age: int.tryParse(data['age'].toString()) ?? 0,
          email: data['email'] ?? '',
          dob: data['dob'] ?? '',
          gender: data['gender'] ?? '',
          employmentStatus: data['employmentStatus'] ?? '',
          address: data['address'] ?? '',
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void deleteUser(String documentId) async {
    try {
      // Fetch user information before deletion
      final userDoc = await _db.collection('users').doc(documentId).get();
      if (!userDoc.exists) {
        print('User does not exist.');
        return;
      }

      final user = UserInfo(
        userId: documentId,
        name: userDoc['name'] ?? '',
        age: int.tryParse(userDoc['age'].toString()) ?? 0,
        email: userDoc['email'] ?? '',
        dob: userDoc['dob'] ?? '',
        gender: userDoc['gender'] ?? '',
        employmentStatus: userDoc['employmentStatus'] ?? '',
        address: userDoc['address'] ?? '',
      );

      // Delete user document from Firestore
      await _db.collection('users').doc(documentId).delete();

      // Delete the associated PDF from Firebase Storage
      final pdfRef = _storage.ref().child('pdfs/${user.name.trim()}.pdf');
      try {
        await pdfRef.delete();
      } catch (e) {
        print('Error deleting PDF from Firebase Storage: $e');
      }

      // Remove the PDF from the SFTP server
      await deleteFromSFTP(user);

      // Refresh the user list
      fetchUsers();
      notifyListeners();
    } catch (e) {
      print('Error deleting user: $e');
    }
  }



  Future<String> generatePDF(UserInfo user) async {
    final pdf = pw.Document();

    final customFont =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('User Information'),
              pw.Text('Name: ${user.name}',
                  style: pw.TextStyle(font: customFont)),
              pw.Text('Age: ${user.age}',
                  style: pw.TextStyle(font: customFont)),
              pw.Text('Email: ${user.email}',
                  style: pw.TextStyle(font: customFont)),
              pw.Text('DOB: ${user.dob}',
                  style: pw.TextStyle(font: customFont)),
              pw.Text('Gender: ${user.gender}',
                  style: pw.TextStyle(font: customFont)),
              pw.Text('Employment Status: ${user.employmentStatus}',
                  style: pw.TextStyle(font: customFont)),
              pw.Text('Address: ${user.address}',
                  style: pw.TextStyle(font: customFont)),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${user.name.trim()}.pdf");
    print("PATHH: $file");
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  Future<void> uploadToSFTP(UserInfo user, String filePath, String fileName,
      BuildContext context) async {
    try {
      final socket = await SSHSocket.connect('ap-southeast-1.sftpcloud.io', 22);
      final client = SSHClient(
        socket,
        username: 'flutterDev',
        onPasswordRequest: () => 'qLvS8YEjqZBpCRjnVvzBT9SvYdYtNFEE',
      );

      final sftp = await client.sftp();
      try {
        // Attempt to create directory, handle failure if not supported
        try {
          await sftp.mkdir(user.name); // Create directory
        } catch (e) {
          print('Directory creation might not be supported or failed: $e');
        }

        // Check if the local file exists before attempting to upload
        final localFile = File(filePath);
        if (await localFile.exists()) {
          final remoteFilePath = '/${user.name.trim()}/${fileName}';
          try {
            final remoteFile = await sftp.open(remoteFilePath,
                mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
            await remoteFile.write(localFile.openRead().cast());

            // Close the remote file
            await remoteFile.close();
          } catch (e) {
            print('Error during file upload: $e');
          }

          // Navigate to PDF view page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PDFViewPage(filePath: filePath),
            ),
          );
        } else {
          print('Local file does not exist: $filePath');
        }
      } finally {
        sftp.close();
        client.close();
      }
    } catch (e) {
      print('SFTP upload error: $e');
    }
  }

  Future<void> generateAndUploadPDF(UserInfo user, BuildContext context) async {
    final pdfPath = await generatePDF(user); // Your function to generate PDF
    final pdfRef = _storage.ref().child('pdfs/${user.name}.pdf');

    // If PDF already exists, delete it first
    try {
      await pdfRef.delete();
    } catch (e) {
      // PDF does not exist
    }

    await pdfRef.putFile(File(pdfPath));

    // Update PDF on SFTP server
    await uploadToSFTP(user, pdfPath, '${user.name.trim()}.pdf',
        context); // Ensure you have context here
  }
}

Future<void> deleteFromSFTP(UserInfo user) async {
  try {
    final socket = await SSHSocket.connect('ap-southeast-1.sftpcloud.io', 22);
    final client = SSHClient(
      socket,
      username: 'flutterDev',
      onPasswordRequest: () => 'qLvS8YEjqZBpCRjnVvzBT9SvYdYtNFEE',
    );

    final sftp = await client.sftp();
    try {
      final remoteFilePath = '/${user.name.trim()}/${user.name.trim()}.pdf';
      try {
        await sftp.remove(remoteFilePath);
        print('PDF removed from SFTP server');
      } catch (e) {
        print('Error removing PDF from SFTP server: $e');
      }
    } finally {
      sftp.close();
      client.close();
    }
  } catch (e) {
    print('SFTP delete error: $e');
  }
}
