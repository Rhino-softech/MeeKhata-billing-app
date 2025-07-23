import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<Map<String, dynamic>> courses = [
    {
      'courseName': '',
      'batches': [
        {'name': '', 'start': '', 'end': ''},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Add Tutor",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
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
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                      ),
                      onChanged: (val) => phone = val,
                    ),
                    const SizedBox(height: 20),

                    // Courses Section
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
                                'courseName': '',
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
                    ...courses.asMap().entries.map((courseEntry) {
                      int courseIndex = courseEntry.key;
                      var course = courseEntry.value;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Course ${courseIndex + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: "Course Name",
                                ),
                                onChanged: (val) => course['courseName'] = val,
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Batches",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                                int batchIndex = batchEntry.key;
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
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: widget.onClose,
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: const Text("Add Tutor"),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('tutors')
                                .add({
                                  'name': name,
                                  'email': email,
                                  'phone': phone,
                                  'courses': courses,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                            widget.onClose();
                          },
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
