import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewPage extends StatelessWidget {
  final String filePath;

  PDFViewPage({required this.filePath});

  @override
  Widget build(BuildContext context) {
    // Extract the file name from the file path
    final fileName = filePath.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer - $fileName'), // Show file name in AppBar
      ),
      body: PDFView(
        filePath: filePath,
        fitPolicy: FitPolicy.BOTH, // Adjust PDF fit policy as needed
        enableSwipe: true, // Allow swipe to navigate pages
        swipeHorizontal: true, // Swipe horizontally for page navigation
        autoSpacing: true, // Automatically adjust spacing
        pageFling: true, // Enable page fling
        pageSnap: true, // Snap to page on swipe
        onPageChanged: (page, total) {
          print('Page $page of $total'); // Optional: Print page number
        },
        onRender: (pages) {
          print(
              'PDF Rendered with $pages pages'); // Optional: Print number of pages
        },
        onError: (error) {
          print('Error: $error'); // Handle PDF load error
        },
        onPageError: (page, error) {
          print('Page $page error: $error'); // Handle page-specific error
        },
      ),
    );
  }
}
