part of axis_dashboard;

class AttendanceDialog extends StatefulWidget {
  final String classId;

  const AttendanceDialog({
    required this.classId,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => AttendanceDialogState();
}

class AttendanceDialogState extends State<AttendanceDialog> {
  String className = '';
  final Map<String, AttendanceType> records = {};
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.2,
        height: MediaQuery.of(context).size.height * 0.8,
        child: FutureBuilderTemplate(
          future: () async {
            if (records.isNotEmpty) return records;
            final now = DateTime.now();
            final String todayId = '${now.day}-${now.month}-${now.year}';

            final classDoc = await firestore
                .collection('classes')
                .doc(widget.classId)
                .get();
            ClassData classData = ClassData.fromJson(classDoc.data()!);
            final studentsData =
                (await firestore
                        .collection('users')
                        .where(
                          FieldPath.documentId,
                          whereIn: classData.studentIds,
                        )
                        .get())
                    .docs
                    .map(
                      (doc) =>
                          (data: StudentData.fromJson(doc.data()), id: doc.id),
                    );

            if (!classData.attendance.containsKey(todayId)) {
              await firestore.collection('classes').doc(widget.classId).update({
                'attendance.$todayId': {
                  for (final entry in studentsData)
                    entry.id: AttendanceType.absent.toString(),
                },
              });
              classData = ClassData.fromJson(
                (await firestore
                        .collection('classes')
                        .doc(widget.classId)
                        .get())
                    .data()!,
              );
            }
            className = classData.name;

            for (final ({StudentData data, String id}) studentDoc
                in studentsData) {
              records[studentDoc.id] =
                  classData.attendance[todayId]![studentDoc.id]!;
            }
            return records;
          }(),
          builder: (ctx, snapshot) {
            return Stack(
              children: [
                Positioned(
                  top: 30,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ListView(
                    children: [
                      for (final record in records.entries)
                        ListTile(
                          title: Text(record.value.name),
                          trailing: DropdownMenu<AttendanceType>(
                            initialSelection: record.value,
                            dropdownMenuEntries: [
                              for (final label in const [
                                'Present Online',
                                'Present Physical',
                                'Present Recording',
                                'Absent',
                              ])
                                DropdownMenuEntry(
                                  value: AttendanceType.fromLabel(label),
                                  label: label,
                                ),
                            ],
                            onSelected: (value) => setState(() {
                              (value != null)
                                  ? records[record.key] = value
                                  : null;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 30,
                  child: Row(
                    children: [
                      Text(className),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(records);
                        },
                        child: Icon(Icons.check),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
