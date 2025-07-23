import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TutorPage extends StatefulWidget {
  const TutorPage({super.key});

  @override
  State<TutorPage> createState() => _TutorPageState();
}

class _TutorPageState extends State<TutorPage> {
  void _showAddTutorDialog() {
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Add Tutor",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
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
                                const SizedBox(height: 8),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "Course Name",
                                  ),
                                  onChanged:
                                      (val) => course['courseName'] = val,
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
                                          flex: 2,
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
                                          flex: 2,
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
                                          flex: 2,
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
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            child: const Text("Add Tutor"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
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
                              Navigator.pop(context);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tutors")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _showAddTutorDialog,
              icon: const Icon(Icons.add),
              label: const Text("Add Tutor"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('tutors')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tutors = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: tutors.length,
                  itemBuilder: (context, index) {
                    final data = tutors[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: Text(
                          "${data['courses']?.length ?? 0} courses",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
