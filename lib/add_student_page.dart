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
  final TextEditingController amountPaidController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String? selectedCourse;
  String? selectedBatch;
  String? selectedTimeSlot;
  List<String> courses = [];
  List<String> batches = [];
  List<String> timeSlots = [];
  bool isLoading = false;
  bool isFetchingBatches = false;

  Map<String, String> courseIdMap = {}; // name -> id
  Map<String, String> batchIdMap = {}; // batch name -> doc id

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  void fetchCourses() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('course_details').get();

      final courseNames = <String>[];
      final courseIds = <String, String>{};

      for (var doc in snapshot.docs) {
        final name = doc.data()['name']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          courseNames.add(name);
          courseIds[name] = doc.id;
        }
      }

      setState(() {
        courses = courseNames;
        courseIdMap = courseIds;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching courses: $e')));
    }
  }

  void fetchBatches(String? courseName) async {
    if (courseName == null || courseName.isEmpty) return;

    setState(() {
      isFetchingBatches = true;
      selectedBatch = null;
      selectedTimeSlot = null;
      batches = [];
      timeSlots = [];
      batchIdMap = {};
    });

    try {
      final courseId = courseIdMap[courseName];
      if (courseId == null) return;

      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('course_details')
              .doc(courseId)
              .get();

      if (!docSnapshot.exists) return;

      final data = docSnapshot.data();
      if (data == null || !data.containsKey('batches')) return;

      final batchArray = data['batches'];
      if (batchArray is List) {
        final batchNames =
            batchArray
                .where((b) => b['name'] != null)
                .map((b) => b['name'].toString())
                .toList();

        setState(() {
          batches = batchNames;
          isFetchingBatches = false;
        });
      }

      // Fetch subcollection for time slots
      final batchDocs =
          await FirebaseFirestore.instance
              .collection('course_details')
              .doc(courseId)
              .collection('batches')
              .get();

      for (var doc in batchDocs.docs) {
        final name = doc.data()['name'];
        final time = doc.data()['time']; // <-- updated here
        if (name != null && time != null) {
          batchIdMap[name] = doc.id;
        }
      }
    } catch (e) {
      setState(() => isFetchingBatches = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching batches: $e')));
    }
  }

  void fetchTimeSlot(String? batchName) async {
    if (selectedCourse == null || batchName == null) return;

    final courseId = courseIdMap[selectedCourse!];
    final batchDocId = batchIdMap[batchName];

    if (courseId == null || batchDocId == null) return;

    try {
      final slotDoc =
          await FirebaseFirestore.instance
              .collection('course_details')
              .doc(courseId)
              .collection('batches')
              .doc(batchDocId)
              .get();

      if (slotDoc.exists) {
        final data = slotDoc.data();
        final timeSlot = data?['time']; // <-- updated here
        if (timeSlot != null) {
          setState(() {
            selectedTimeSlot = timeSlot;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching time slot: $e')));
    }
  }

  void addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('student_enroll_details').add(
        {
          'name': nameController.text.trim(),
          'course_name': selectedCourse,
          'batch_name': selectedBatch,
          'time': selectedTimeSlot, // <-- updated here
          'total_fees': double.tryParse(feeController.text.trim()) ?? 0,
          'amount_paid': double.tryParse(amountPaidController.text.trim()) ?? 0,
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'enrollment_date': Timestamp.now(),
        },
      );

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
                            (course) => DropdownMenuItem(
                              value: course,
                              child: Text(course),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCourse = value;
                      selectedBatch = null;
                      selectedTimeSlot = null;
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
                            (batch) => DropdownMenuItem(
                              value: batch,
                              child: Text(batch),
                            ),
                          )
                          .toList(),
                  onChanged:
                      isFetchingBatches || batches.isEmpty
                          ? null
                          : (value) {
                            setState(() {
                              selectedBatch = value;
                              selectedTimeSlot = null;
                            });
                            fetchTimeSlot(value);
                          },
                  validator:
                      (value) => value == null ? 'Please select a batch' : null,
                ),

                const SizedBox(height: 20),
                const Text("Time Slot"),
                const SizedBox(height: 6),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: selectedTimeSlot ?? "Time slot will appear here",
                    border: const OutlineInputBorder(),
                  ),
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
                const Text("Amount Paid"),
                const SizedBox(height: 6),
                TextFormField(
                  controller: amountPaidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Enter amount paid",
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
    );
  }
}
