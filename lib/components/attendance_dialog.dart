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
  final Map<String, StudentData> studentsDataMap = {};
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.8,
        color: AxisColors.blackPurple50,
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
              studentsDataMap[studentDoc.id] = studentDoc.data;
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
                      for (final record in records.entries) ...[
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: ListTile(
                              title: Text(
                                studentsDataMap[record.key]!.name,
                                style: heading3,
                              ),
                              trailing: AxisDropdownButton<AttendanceType>(
                                initialSelection: record.value,
                                width: MediaQuery.of(context).size.width * 0.25,
                                entries: [
                                  for (final label in const [
                                    'Present Online',
                                    'Present Physical',
                                    'Present Recording',
                                    'Absent',
                                  ])
                                    (
                                      label,
                                      AttendanceType.fromLabel(label),
                                    ),
                                ],
                                onSelected: (value) => setState(() {
                                  (value != null)
                                      ? records[record.key] = value
                                      : null;
                                }),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
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
                      Text(
                        className,
                        style: heading1,
                      ),
                      const Spacer(),
                      AxisButton(
                        width: 100,
                        onPressed: () {
                          Navigator.of(ctx).pop(records);
                        },
                        child: Icon(
                          Icons.check,
                          size: 30,
                          color: AxisColors.blackPurple20,
                        ),
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
