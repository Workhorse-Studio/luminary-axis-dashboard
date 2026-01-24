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
  final Map<String, ({String name, bool present})> records = {};
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.2,
        height: MediaQuery.of(context).size.height * 0.8,
        child: FutureBuilderTemplate(
          future: () async {
            if (records.isNotEmpty) return records;
            final classDoc = await firestore
                .collection('classes')
                .doc(widget.classId)
                .get();
            final classData = ClassData.fromJson(classDoc.data()!);

            className = classData.name;

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
            final now = DateTime.now();
            final String todayId = '${now.day}-${now.month}-${now.year}';
            for (final ({StudentData data, String id}) studentDoc
                in studentsData) {
              records[studentDoc.id] = (
                name: studentDoc.data.name,
                present: classData.attendance.containsKey(todayId)
                    ? classData.attendance[todayId]!.contains(studentDoc.id)
                    : false,
              );
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
                        CheckboxListTile(
                          title: Text(record.value.name),
                          value: record.value.present,
                          onChanged: (isChecked) => setState(() {
                            records[record.key] = (
                              name: record.value.name,
                              present: isChecked!,
                            );
                          }),
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
