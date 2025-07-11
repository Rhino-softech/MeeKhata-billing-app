import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String? selectedCourse;
  String? selectedBatch;
  List<String> courses = [];
  List<String> batches = [];
  bool isLoading = false;
  bool isFetchingBatches = false;

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  void fetchCourses() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('course_details').get();

      final courseNames =
          snapshot.docs
              .map((doc) => doc.data()['name']?.toString())
              .where((name) => name != null && name.isNotEmpty)
              .cast<String>()
              .toList();

      setState(() {
        courses = courseNames;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching courses: $e')));
    }
  }

  void fetchBatches(String? courseName) async {
    if (courseName == null) return;

    setState(() {
      isFetchingBatches = true;
      selectedBatch = null;
      batches = [];
    });

    try {
      // First find the course document with this name
      final courseQuery =
          await FirebaseFirestore.instance
              .collection('course_details')
              .where('name', isEqualTo: courseName)
              .limit(1)
              .get();

      if (courseQuery.docs.isEmpty) {
        setState(() {
          batches = [];
        });
        return;
      }

      final courseDoc = courseQuery.docs.first;

      // Now get all batches from the subcollection using 'batch_name' field
      final batchesSnapshot =
          await courseDoc.reference.collection('batches').get();

      final batchNames =
          batchesSnapshot.docs
              .map((doc) => doc.data()['batch_name']?.toString())
              .where((name) => name != null && name.isNotEmpty)
              .cast<String>()
              .toList();

      setState(() {
        batches = batchNames;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching batches: $e')));
      setState(() {
        batches = [];
      });
    } finally {
      setState(() {
        isFetchingBatches = false;
      });
    }
  }

  void addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('student_enroll_details')
          .add({
            'name': nameController.text.trim(),
            'course_name': selectedCourse,
            'batch_name': selectedBatch,
            'total_fees': double.tryParse(feeController.text.trim()) ?? 0,
            'phone': phoneController.text.trim(),
            'email': emailController.text.trim(),
            'amount_paid': 0,
            'enrollment_date': Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding student: $e')));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Student Information",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Add a new student to a course",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),
                const Text("Student Name"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Enter student name",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 20),
                const Text("Course"),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedCourse,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text("Select a course"),
                  items:
                      courses
                          .map(
                            (course) => DropdownMenuItem<String>(
                              value: course,
                              child: Text(course),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCourse = value;
                      selectedBatch = null;
                    });
                    fetchBatches(value);
                  },
                  validator:
                      (value) =>
                          value == null ? 'Please select a course' : null,
                ),

                const SizedBox(height: 20),
                const Text("Batch"),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedBatch,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  hint:
                      isFetchingBatches
                          ? const Text("Loading batches...")
                          : batches.isEmpty
                          ? const Text("No batches available")
                          : const Text("Select a batch"),
                  items:
                      batches
                          .map(
                            (batch) => DropdownMenuItem<String>(
                              value: batch,
                              child: Text(batch),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (isFetchingBatches || batches.isEmpty)
                          ? null
                          : (value) => setState(() => selectedBatch = value),
                  validator:
                      (value) => value == null ? 'Please select a batch' : null,
                ),

                const SizedBox(height: 20),
                const Text("Course Fee"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Enter course fee",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 20),
                const Text("Phone Number"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: "+91 98765 43210",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 20),
                const Text("Email (Optional)"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: "student@example.com",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : addStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.add),
                    label:
                        isLoading
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                            : const Text("Add Student"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoices'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
