import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceMarkPage extends StatefulWidget {
  final String courseName;
  final String batchName;

  const AttendanceMarkPage({
    super.key,
    required this.courseName,
    required this.batchName,
  });

  @override
  State<AttendanceMarkPage> createState() => _AttendanceMarkPageState();
}

class _AttendanceMarkPageState extends State<AttendanceMarkPage> {
  Map<String, bool> attendanceMap = {};
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> markedToday = [];
  List<Map<String, dynamic>> unmarkedToday = [];
  bool attendanceAlreadyMarked = false;
  String? filter = 'all';
  Position? currentPosition;
  bool selfMarkingEnabled = false;

  final String today = DateTime.now().toIso8601String().split('T').first;

  String get selfMarkingDocId => "${widget.courseName}_${widget.batchName}";

  Future<void> fetchSelfMarkingStatus() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('self_marking_settings')
            .doc(selfMarkingDocId)
            .get();

    setState(() {
      selfMarkingEnabled =
          doc.exists ? (doc.data()?['self_marking_enabled'] ?? false) : false;
    });
  }

  Future<void> updateSelfMarkingStatus(bool value) async {
    await FirebaseFirestore.instance
        .collection('self_marking_settings')
        .doc(selfMarkingDocId)
        .set({'self_marking_enabled': value, 'last_updated': Timestamp.now()});

    setState(() {
      selfMarkingEnabled = value;
    });
  }

  Future<void> fetchStudents() async {
    markedToday.clear();
    unmarkedToday.clear();
    attendanceMap.clear();

    final snapshot =
        await FirebaseFirestore.instance
            .collection('student_enroll_details')
            .where('course_name', isEqualTo: widget.courseName)
            .where('batch_name', isEqualTo: widget.batchName)
            .get();

    final tempStudents =
        snapshot.docs.map((doc) {
          final data = doc.data();
          final id = doc.id;
          final name = data['name'];
          final email = data['email'];
          final attendance = Map<String, dynamic>.from(
            data['attendance'] ?? {},
          );
          final isMarkedToday = attendance.containsKey(today);
          if (isMarkedToday) {
            markedToday.add({
              'id': id,
              'name': name,
              'email': email,
              'isPresent': attendance[today] == true,
            });
          } else {
            unmarkedToday.add({'id': id, 'name': name, 'email': email});
            attendanceMap[id] = true;
          }
          return {'id': id, 'name': name, 'email': email};
        }).toList();

    setState(() {
      students = tempStudents;
      attendanceAlreadyMarked = unmarkedToday.isEmpty;
    });
  }

  void toggleAttendance(String studentId, bool isPresent) {
    setState(() {
      attendanceMap[studentId] = isPresent;
    });
  }

  Future<void> saveAttendance() async {
    if (attendanceAlreadyMarked) return;

    await getCurrentLocation();

    for (var entry in attendanceMap.entries) {
      final studentId = entry.key;
      final isPresent = entry.value;

      final docRef = FirebaseFirestore.instance
          .collection('student_enroll_details')
          .doc(studentId);
      final docSnapshot = await docRef.get();

      Map<String, dynamic> data = docSnapshot.data() ?? {};
      Map<String, dynamic> attendanceData =
          (data['attendance'] as Map<String, dynamic>? ?? {});
      int presentCount = (data['present_count'] ?? 0);
      int absentCount = (data['absent_count'] ?? 0);

      if (!attendanceData.containsKey(today)) {
        if (isPresent) {
          presentCount++;
        } else {
          absentCount++;
        }

        attendanceData[today] = isPresent;

        await docRef.update({
          'attendance': attendanceData,
          'present_count': presentCount,
          'absent_count': absentCount,
          'last_updated': Timestamp.now(),
          'marked_latitude': currentPosition?.latitude,
          'marked_longitude': currentPosition?.longitude,
        });
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Attendance saved!')));

    await fetchStudents();
  }

  Future<void> exportPresentStudents() async {
    final presentStudents = markedToday.where((s) => s['isPresent'] == true);
    final csv = StringBuffer();
    csv.writeln('Name,Email');
    for (var student in presentStudents) {
      csv.writeln('${student['name']},${student['email']}');
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/present_students_$today.csv';
    final file = File(filePath);
    await file.writeAsString(csv.toString());
  }

  Future<void> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStudents();
    fetchSelfMarkingStatus();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    final todayDate = DateTime.now();
    final formattedDate =
        "${todayDate.day.toString().padLeft(2, '0')}/${todayDate.month.toString().padLeft(2, '0')}/${todayDate.year}";
    final presentCount = attendanceMap.values.where((v) => v).length;
    final absentCount = attendanceMap.values.where((v) => !v).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: const BackButton(),
      ),
      body:
          students.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        title: const Text("Student Self-Marking"),
                        subtitle: Text(
                          selfMarkingEnabled ? "Enabled" : "Disabled",
                        ),
                        trailing: Switch(
                          value: selfMarkingEnabled,
                          onChanged: (value) => updateSelfMarkingStatus(value),
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF0A1128),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(
                                  '${widget.batchName} - ${widget.courseName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('${students.length} students'),
                                trailing: Text(formattedDate),
                              ),
                              if (!attendanceAlreadyMarked)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('✔ $presentCount Present'),
                                      Text('✘ $absentCount Absent'),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (attendanceAlreadyMarked) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      FilterChip(
                                        label: const Text("All"),
                                        selected: filter == 'all',
                                        onSelected: (_) {
                                          setState(() {
                                            filter = 'all';
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      FilterChip(
                                        label: const Text("Present"),
                                        selected: filter == 'present',
                                        onSelected: (_) {
                                          setState(() {
                                            filter = 'present';
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      FilterChip(
                                        label: const Text("Absent"),
                                        selected: filter == 'absent',
                                        onSelected: (_) {
                                          setState(() {
                                            filter = 'absent';
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                ...markedToday
                                    .where((student) {
                                      if (filter == 'present') {
                                        return student['isPresent'] == true;
                                      } else if (filter == 'absent') {
                                        return student['isPresent'] == false;
                                      }
                                      return true;
                                    })
                                    .map(
                                      (student) => ListTile(
                                        leading: CircleAvatar(
                                          child: Text(student['name'][0]),
                                        ),
                                        title: Text(student['name']),
                                        subtitle: Text(student['email']),
                                        trailing: Icon(
                                          student['isPresent']
                                              ? Icons.check
                                              : Icons.close,
                                          color:
                                              student['isPresent']
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                    ),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: exportPresentStudents,
                                    icon: const Icon(Icons.download),
                                    label: const Text("Export Present"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0A1128),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                              if (!attendanceAlreadyMarked &&
                                  unmarkedToday.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "🕓 Mark Attendance",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                                ...unmarkedToday.map((student) {
                                  final isPresent =
                                      attendanceMap[student['id']] ?? true;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(student['name'][0]),
                                    ),
                                    title: Text(student['name']),
                                    subtitle: Text(student['email']),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.check,
                                            color:
                                                isPresent
                                                    ? Colors.green
                                                    : Colors.grey,
                                          ),
                                          onPressed:
                                              () => toggleAttendance(
                                                student['id'],
                                                true,
                                              ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color:
                                                !isPresent
                                                    ? Colors.red
                                                    : Colors.grey,
                                          ),
                                          onPressed:
                                              () => toggleAttendance(
                                                student['id'],
                                                false,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          attendanceAlreadyMarked ? null : saveAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1128),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        attendanceAlreadyMarked
                            ? "Attendance Already Marked"
                            : "Save Attendance",
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
