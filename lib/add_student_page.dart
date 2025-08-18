import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddStudentPage extends StatefulWidget {
  final String loggedInUid; // ✅ Get UID from login page

  const AddStudentPage({super.key, required this.loggedInUid});

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
  bool isAssigned = false;
  String assignedLabel = 'Unassigned';

  List<String> courses = [];
  List<String> batches = [];
  bool isLoading = false;
  bool isFetchingBatches = false;

  Map<String, String> courseIdMap = {};
  Map<String, String> batchIdMap = {};

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  /// 🔹 Fetch courses from `courses` collection
  void fetchCourses() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('courses').get();
      final courseNames = <String>[];
      final courseIds = <String, String>{};

      for (var doc in snapshot.docs) {
        final name = doc.data()['name']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          courseNames.add(name);
          courseIds[name] = doc.id;
        }
      }

      if (!mounted) return;
      setState(() {
        courses = courseNames;
        courseIdMap = courseIds;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching courses: $e')));
    }
  }

  /// 🔹 Fetch batches from `batches` collection using `course_id`
  void fetchBatches(String? courseName) async {
    if (courseName == null || courseName.isEmpty) return;

    if (!mounted) return;
    setState(() {
      isFetchingBatches = true;
      selectedBatch = null;
      selectedTimeSlot = null;
      batches = [];
      batchIdMap = {};
    });

    try {
      final courseId = courseIdMap[courseName];
      if (courseId == null) return;

      final batchDocs =
          await FirebaseFirestore.instance
              .collection('batches')
              .where('course_id', isEqualTo: courseId)
              .get();

      final batchNames = <String>[];
      final batchIds = <String, String>{};

      for (var doc in batchDocs.docs) {
        final name = doc.data()['name']?.toString();
        if (name != null && name.isNotEmpty) {
          batchNames.add(name);
          batchIds[name] = doc.id;
        }
      }

      if (!mounted) return;
      setState(() {
        batches = batchNames;
        batchIdMap = batchIds;
        isFetchingBatches = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isFetchingBatches = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching batches: $e')));
    }
  }

  /// 🔹 Fetch time slot for a selected batch
  void fetchTimeSlot(String? batchName) async {
    if (selectedCourse == null || batchName == null) return;

    final batchDocId = batchIdMap[batchName];
    if (batchDocId == null) return;

    try {
      final slotDoc =
          await FirebaseFirestore.instance
              .collection('batches')
              .doc(batchDocId)
              .get();

      if (slotDoc.exists) {
        final data = slotDoc.data();
        final timeSlot = data?['time'];
        if (timeSlot != null) {
          if (!mounted) return;
          setState(() {
            selectedTimeSlot = timeSlot;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching time slot: $e')));
    }
  }

  /// 🔹 Add new student (no tutor_id for now)
  void addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('student_enroll_details').add(
        {
          'name': nameController.text.trim(),
          'course_name': selectedCourse,
          'batch_name': selectedBatch,
          'time': selectedTimeSlot,
          'total_fees': double.tryParse(feeController.text.trim()) ?? 0,
          'amount_paid': double.tryParse(amountPaidController.text.trim()) ?? 0,
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'assigned': isAssigned,
          'enrollment_date': Timestamp.now(),
          'created_by_uid': widget.loggedInUid, // ✅ Store UID
          // tutor_id NOT stored now, will be updated later
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding student: $e')));
    }

    if (!mounted) return;
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

                _buildTextField("Student Name", nameController, "Enter name"),
                const SizedBox(height: 20),

                _buildDropdown(
                  "Course",
                  selectedCourse,
                  courses,
                  (val) {
                    setState(() {
                      selectedCourse = val;
                      selectedBatch = null;
                      selectedTimeSlot = null;
                    });
                    fetchBatches(val);
                  },
                  validator:
                      (val) => val == null ? 'Please select a course' : null,
                ),
                const SizedBox(height: 20),

                _buildDropdown(
                  "Batch",
                  selectedBatch,
                  batches,
                  (val) {
                    setState(() {
                      selectedBatch = val;
                      selectedTimeSlot = null;
                    });
                    fetchTimeSlot(val);
                  },
                  hint:
                      isFetchingBatches
                          ? "Loading batches..."
                          : batches.isEmpty
                          ? "No batches available"
                          : "Select a batch",
                  validator:
                      (val) => val == null ? 'Please select a batch' : null,
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

                _buildTextField(
                  "Course Fee",
                  feeController,
                  "Enter course fee",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  "Amount Paid",
                  amountPaidController,
                  "Enter amount paid",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  "Phone Number",
                  phoneController,
                  "+91 98765 43210",
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  "Email (Optional)",
                  emailController,
                  "student@example.com",
                  required: false,
                ),
                const SizedBox(height: 20),

                const Text("Assigned Status"),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: assignedLabel,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Unassigned',
                      child: Text('Unassigned'),
                    ),
                    DropdownMenuItem(
                      value: 'Assigned',
                      child: Text('Assigned'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      assignedLabel = value!;
                      isAssigned = value == 'Assigned';
                    });
                  },
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hintText, {
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          validator:
              required
                  ? (value) =>
                      value == null || value.isEmpty ? 'Required' : null
                  : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    void Function(String?) onChanged, {
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          hint: Text(hint ?? "Select $label"),
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: items.isEmpty ? null : onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
