import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTutorForm extends StatefulWidget {
  final VoidCallback onClose;
  const AddTutorForm({super.key, required this.onClose});

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
    _getInstituteIdAndCourses();
  }

  Future<void> _getInstituteIdAndCourses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDetailsSnapshot =
          await FirebaseFirestore.instance
              .collection('user_details')
              .where('reference_id', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (userDetailsSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User details not found.")),
        );
        return;
      }

      final userDoc = userDetailsSnapshot.docs.first;
      final id = userDoc.id; // Use document ID as instituteId

      final instituteDoc =
          await FirebaseFirestore.instance
              .collection('institutes')
              .doc(id)
              .get();

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
      debugPrint("Error fetching institute or courses: $e");
    }
  }

  Future<void> _submitTutor() async {
    if (instituteId == null || instituteData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Institute data not loaded")),
      );
      return;
    }

    try {
      final tutorRef = await FirebaseFirestore.instance
          .collection('tutors')
          .add({
            'name': name,
            'email': email,
            'phone': phone,
            'institute_id': instituteId,
            'institute': instituteData,
            'assigned_course_ids': courses.map((c) => c['courseId']).toList(),
            'created_at': FieldValue.serverTimestamp(),
          });

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

      widget.onClose();
    } catch (e) {
      debugPrint("Error adding tutor: $e");
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
