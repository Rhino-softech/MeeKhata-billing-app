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
  String? instituteId;
  Map<String, dynamic>? instituteData;

  List<Map<String, dynamic>> courses = [
    {
      'courseId': null,
      'type': 'normal',
      'batches': [
        {'name': '', 'start': '', 'end': ''},
      ],
    },
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
      debugPrint("🆔 Logged-in UID in _fetchInstituteDetails: $userUid");

      if (userUid.isEmpty) {
        debugPrint("❌ UID is empty, cannot fetch institute details");
        return;
      }

      final userDetailsSnapshot =
          await FirebaseFirestore.instance
              .collection('user_details')
              .where('reference_id', isEqualTo: userUid)
              .limit(1)
              .get();

      if (userDetailsSnapshot.docs.isEmpty) {
        debugPrint("❌ user_details not found for uid: $userUid");
        return;
      }

      final userDoc = userDetailsSnapshot.docs.first;
      final id = userDoc.id;

      final instituteDoc =
          await FirebaseFirestore.instance
              .collection('institutes')
              .doc(id)
              .get();

      if (!instituteDoc.exists) {
        debugPrint("❌ Institute document with ID $id does not exist.");
        return;
      }

      setState(() {
        instituteId = id;
        instituteData = instituteDoc.data();
      });

      final courseSnapshot =
          await FirebaseFirestore.instance
              .collection('courses')
              .where('institute_id', isEqualTo: id)
              .get();

      setState(() {
        availableCourses = courseSnapshot.docs;
      });
    } catch (e) {
      debugPrint("❌ Exception in _fetchInstituteDetails: $e");
    }
  }

  Future<void> _submitTutor() async {
    try {
      final userUid = widget.loggedInUid;
      debugPrint("🆔 Logged-in UID in _submitTutor: $userUid");

      if (instituteId == null || instituteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Institute data not loaded")),
        );
        return;
      }

      if (userUid.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User UID is missing")));
        return;
      }

      final tutorData = {
        'name': name,
        'email': email,
        'phone': phone,
        'institute_id': instituteId,
        'institute': instituteData,
        'assigned_course_ids': courses.map((c) => c['courseId']).toList(),
        'created_at': FieldValue.serverTimestamp(),
        'added_by_uid': userUid, // <- Store the logged-in UID
      };

      debugPrint("📦 Adding tutor: $tutorData");

      final tutorRef = await FirebaseFirestore.instance
          .collection('tutors')
          .add(tutorData);

      debugPrint("✅ Tutor added with ID: ${tutorRef.id}");

      for (var course in courses) {
        for (var batch in course['batches']) {
          await FirebaseFirestore.instance.collection('batches').add({
            'name': batch['name'],
            'start_date': batch['start'],
            'end_date': batch['end'],
            'tutor_id': tutorRef.id,
            'course_id': course['courseId'],
            'institute_id': instituteId,
            'created_at': FieldValue.serverTimestamp(),
          });
        }

        if (course['courseId'] != null) {
          await FirebaseFirestore.instance
              .collection('courses')
              .doc(course['courseId'])
              .update({'assigned_tutor_id': tutorRef.id});
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Tutor added successfully")),
      );
      widget.onClose();
    } catch (e, stack) {
      debugPrint("🔥 Error while submitting tutor: $e");
      debugPrint("🧱 Stack Trace:\n$stack");
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
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Courses & Batches",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              courses.add({
                                'courseId': null,
                                'type': 'normal',
                                'batches': [
                                  {'name': '', 'start': '', 'end': ''},
                                ],
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
                                onChanged: (val) {
                                  setState(() {
                                    course['courseId'] = val;
                                  });
                                },
                              ),
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
                                  setState(() {
                                    course['type'] = val!;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Batches"),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        course['batches'].add({
                                          'name': '',
                                          'start': '',
                                          'end': '',
                                        });
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text("Add Batch"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              ...course['batches'].asMap().entries.map((
                                batchEntry,
                              ) {
                                var batch = batchEntry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: "Name",
                                          ),
                                          onChanged:
                                              (val) => batch['name'] = val,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: "Start",
                                          ),
                                          onChanged:
                                              (val) => batch['start'] = val,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: "End",
                                          ),
                                          onChanged:
                                              (val) => batch['end'] = val,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
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
