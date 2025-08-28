import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddTutorForm extends StatefulWidget {
  final VoidCallback onClose;
  final String loggedInUid; // <- UID passed from Dashboard
  const AddTutorForm({
    super.key,
    required this.onClose,
    required this.loggedInUid,
  });

  @override
  State<AddTutorForm> createState() => _AddTutorFormState();
}

class _AddTutorFormState extends State<AddTutorForm> {
  String name = '';
  String email = '';
  String phone = '';
  String password = ''; // ✅ Added password field
  String? instituteId;
  Map<String, dynamic>? instituteData;

  List<Map<String, dynamic>> courses = [
    {'courseId': null, 'type': 'normal', 'batches': []},
  ];

  List<DocumentSnapshot> availableCourses = [];

  @override
  void initState() {
    super.initState();
    debugPrint("🆔 Logged-in UID at init: ${widget.loggedInUid}");
    _fetchInstituteDetails();
  }

  Future<void> _fetchInstituteDetails() async {
    try {
      final userUid = widget.loggedInUid;
      if (userUid.isEmpty) return;

      final userDetailsSnapshot =
          await FirebaseFirestore.instance
              .collection('user_details')
              .where('reference_id', isEqualTo: userUid)
              .limit(1)
              .get();

      if (userDetailsSnapshot.docs.isEmpty) return;
      final userDoc = userDetailsSnapshot.docs.first;
      final id = userDoc.id;

      final instituteDoc =
          await FirebaseFirestore.instance
              .collection('institutes')
              .doc(id)
              .get();

      if (!instituteDoc.exists) return;

      if (!mounted) return;
      setState(() {
        instituteId = id;
        instituteData = instituteDoc.data();
      });

      /// fetch courses for this institute
      final courseSnapshot =
          await FirebaseFirestore.instance
              .collection('courses')
              .where('institute_id', isEqualTo: id)
              .get();

      if (!mounted) return;
      setState(() {
        availableCourses = courseSnapshot.docs;
      });
    } catch (e) {
      debugPrint("❌ Exception in _fetchInstituteDetails: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBatchesForCourse(
    String courseId,
  ) async {
    final batchSnapshot =
        await FirebaseFirestore.instance
            .collection('batches')
            .where('course_id', isEqualTo: courseId)
            .get();

    return batchSnapshot.docs
        .map((b) => {'batchId': b.id, 'name': b['name'] ?? ''})
        .toList();
  }

  Future<void> _addBatchDialog(int courseIndex, String courseId) async {
    final TextEditingController batchNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Add Batch"),
          content: TextField(
            controller: batchNameController,
            decoration: const InputDecoration(labelText: "Batch Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final batchName = batchNameController.text.trim();
                if (batchName.isEmpty || instituteId == null) return;

                final newBatchRef =
                    FirebaseFirestore.instance.collection('batches').doc();
                await newBatchRef.set({
                  'name': batchName,
                  'course_id': courseId,
                  'institute_id': instituteId,
                  'created_at': FieldValue.serverTimestamp(),
                });

                final createdBatch = await newBatchRef.get();

                if (!mounted) return;
                setState(() {
                  courses[courseIndex]['batches'].add({
                    'batchId': createdBatch.id,
                    'name': batchName,
                  });
                });

                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitTutor() async {
    try {
      final userUid = widget.loggedInUid;

      if (instituteId == null || instituteData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Institute data not loaded")),
        );
        return;
      }

      if (userUid.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User UID is missing")));
        return;
      }

      final tutorData = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password, // ✅ Save password in Firestore
        'institute_id': instituteId,
        'institute': instituteData,
        'assigned_course_ids': courses.map((c) => c['courseId']).toList(),
        'created_at': FieldValue.serverTimestamp(),
        'added_by_uid': userUid,
      };

      final tutorRef = await FirebaseFirestore.instance
          .collection('tutors')
          .add(tutorData);

      for (var course in courses) {
        for (var batch in course['batches']) {
          if (batch['batchId'] != null) {
            await FirebaseFirestore.instance
                .collection('batches')
                .doc(batch['batchId'])
                .update({'tutor_id': tutorRef.id});
          }
        }

        if (course['courseId'] != null) {
          await FirebaseFirestore.instance
              .collection('courses')
              .doc(course['courseId'])
              .update({'assigned_tutor_id': tutorRef.id});
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Tutor added successfully")),
      );
      widget.onClose();
    } catch (e, stack) {
      debugPrint("🔥 Error while submitting tutor: $e");
      debugPrint("🧱 Stack Trace:\n$stack");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add tutor")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Add Tutor",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    /// Basic details
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Name"),
                      onChanged: (val) => name = val,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Email"),
                      onChanged: (val) => email = val,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Phone"),
                      onChanged: (val) => phone = val,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Password",
                      ), // ✅ New field
                      obscureText: true,
                      onChanged: (val) => password = val,
                    ),

                    const SizedBox(height: 20),

                    /// Courses
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Courses & Batches",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (!mounted) return;
                            setState(() {
                              courses.add({
                                'courseId': null,
                                'type': 'normal',
                                'batches': [],
                              });
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Course"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// Course + Batch Cards
                    ...courses.asMap().entries.map((entry) {
                      int courseIndex = entry.key;
                      var course = entry.value;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Course ${courseIndex + 1}"),

                              /// Course dropdown
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Course',
                                ),
                                value: course['courseId'],
                                items:
                                    availableCourses.map((doc) {
                                      return DropdownMenuItem<String>(
                                        value: doc.id,
                                        child: Text(doc['name']),
                                      );
                                    }).toList(),
                                onChanged: (val) async {
                                  if (!mounted) return;
                                  setState(() {
                                    course['courseId'] = val;
                                    course['batches'] = [];
                                  });

                                  if (val != null) {
                                    final batches =
                                        await _fetchBatchesForCourse(val);

                                    if (!mounted) return;
                                    setState(() {
                                      course['batches'] = batches;
                                    });
                                  }
                                },
                              ),

                              /// Type dropdown
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Type',
                                ),
                                value: course['type'],
                                items: const [
                                  DropdownMenuItem(
                                    value: 'normal',
                                    child: Text('Normal'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'addon',
                                    child: Text('Add-on'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (!mounted) return;
                                  setState(() {
                                    course['type'] = val!;
                                  });
                                },
                              ),

                              const SizedBox(height: 10),

                              /// Batches
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...course['batches'].map<Widget>((batch) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                      ),
                                      child: Text(
                                        "Batch: ${batch['name']}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  TextButton.icon(
                                    onPressed:
                                        course['courseId'] == null
                                            ? null
                                            : () => _addBatchDialog(
                                              courseIndex,
                                              course['courseId'],
                                            ),
                                    icon: const Icon(Icons.add),
                                    label: const Text("Add Batch"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    /// Footer buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: widget.onClose,
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _submitTutor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: const Text("Add Tutor"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
