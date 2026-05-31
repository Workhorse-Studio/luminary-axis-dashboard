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
  List<({StudentData data, String id})> studentsData = [];
  AttendanceType selectedBulkType = AttendanceType.presentPhysical;
  final Set<String> selectedStudentIds = {};
  int nextSessionNumber = 1;
  List<String> existingSessionLabels = [];
  DateTime date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.8,
        foregroundDecoration: dialogForegroundDecoration,
        child: Scaffold(
          backgroundColor: AxisColors.blackPurple50,
          body: FutureBuilderTemplate(
            key: ValueKey(date),
            future: () async {
              final classDoc = await firestore
                  .collection('classes')
                  .doc(widget.classId)
                  .get();
              final classData = ClassData.fromJson(classDoc.data()!);
              final fetchedStudentsData = classData.studentIds.isEmpty
                  ? const <({StudentData data, String id})>[]
                  : (await firestore
                            .collection('users')
                            .where(
                              FieldPath.documentId,
                              whereIn: classData.studentIds,
                            )
                            .get())
                        .docs
                        .map(
                          (doc) => (
                            data: StudentData.fromJson(doc.data()),
                            id: doc.id,
                          ),
                        )
                        .toList();
              fetchedStudentsData.sort(
                (a, b) => a.data.name.toLowerCase().compareTo(
                  b.data.name.toLowerCase(),
                ),
              );

              className = classData.name;
              studentsData = fetchedStudentsData;
              selectedStudentIds.removeWhere(
                (id) => !studentsData.any((student) => student.id == id),
              );
              nextSessionNumber = nextAttendanceSessionNumberForDate(
                classData.attendance.keys,
                date,
              );
              existingSessionLabels =
                  classData.attendance.keys
                      .where((k) => attendanceKeyMatchesDate(k, date))
                      .toList()
                    ..sort(compareAttendanceKeys);
              existingSessionLabels = [
                for (final k in existingSessionLabels)
                  attendanceSessionLabel(k),
              ];
              return 0;
            }(),
            builder: (ctx, snapshot) {
              final bool hasStudents = studentsData.isNotEmpty;
              final bool allSelected =
                  hasStudents &&
                  selectedStudentIds.length == studentsData.length;
              final bool hasPartialSelection =
                  selectedStudentIds.isNotEmpty && !allSelected;

              return Stack(
                children: [
                  Positioned(
                    top: 140,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: SingleChildScrollView(
                        child: DataTable(
                          dividerThickness: 0.5,
                          border: TableBorder(
                            verticalInside: BorderSide(
                              color: AxisColors.blackPurple20.withValues(
                                alpha: 0.15,
                              ),
                              width: 1,
                            ),
                            horizontalInside: BorderSide(
                              color: AxisColors.blackPurple20.withValues(
                                alpha: 0.15,
                              ),
                              width: 1,
                            ),
                          ),
                          columns: [
                            DataColumn(
                              label: Checkbox(
                                tristate: true,
                                value: allSelected
                                    ? true
                                    : hasPartialSelection
                                    ? null
                                    : false,
                                onChanged: !hasStudents
                                    ? null
                                    : (value) => setState(() {
                                        if (value == true) {
                                          selectedStudentIds
                                            ..clear()
                                            ..addAll(
                                              studentsData.map((s) => s.id),
                                            );
                                        } else {
                                          selectedStudentIds.clear();
                                        }
                                      }),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Student',
                                style: body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'School',
                                style: body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          rows: [
                            for (final student in studentsData)
                              DataRow(
                                selected: selectedStudentIds.contains(
                                  student.id,
                                ),
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: selectedStudentIds.contains(
                                        student.id,
                                      ),
                                      onChanged: (value) => setState(() {
                                        if (value == true) {
                                          selectedStudentIds.add(student.id);
                                        } else {
                                          selectedStudentIds.remove(student.id);
                                        }
                                      }),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      student.data.name,
                                      style: body2,
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      student.data.school,
                                      style: body2,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    height: 110,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            className,
                            style: heading1,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              AxisButton.text(
                                width: 210,
                                label: date.toTimestampStringShort(),
                                icon: Icons.edit_calendar,
                                onPressed: () async {
                                  final dt = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 30 * 12),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 30 * 12),
                                    ),
                                  );
                                  if (dt == null) return;
                                  setState(() {
                                    date = dt;
                                    selectedStudentIds.clear();
                                  });
                                },
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 220,
                                child: AxisDropdownButton<AttendanceType>(
                                  width: 220,
                                  initialSelection: selectedBulkType,
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
                                  customBgColoring: (attendanceType) =>
                                      switch (attendanceType) {
                                        AttendanceType.absent =>
                                          Colors.red.withValues(alpha: 0.3),
                                        AttendanceType.presentOnline =>
                                          Colors.green.withValues(alpha: 0.3),
                                        AttendanceType.presentPhysical =>
                                          Colors.green.withValues(alpha: 0.3),
                                        AttendanceType.presentRecording =>
                                          Colors.blue.withValues(alpha: 0.3),
                                      },
                                  onSelected: (value) => setState(() {
                                    if (value != null) {
                                      selectedBulkType = value;
                                    }
                                  }),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Next Session: S$nextSessionNumber',
                                style: body2,
                              ),
                              if (existingSessionLabels.isNotEmpty) ...[
                                const SizedBox(width: 16),
                                Text(
                                  'Existing: ${existingSessionLabels.join(', ')}',
                                  style: body2,
                                ),
                              ],
                              const Spacer(),
                              AxisButton.text(
                                width: 200,
                                label:
                                    'Log Session (${selectedStudentIds.length})',
                                icon: Icons.playlist_add_check,
                                onPressed: !hasStudents
                                    ? null
                                    : () async {
                                        if (selectedStudentIds.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Select at least one student first.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        final classDoc = await firestore
                                            .collection('classes')
                                            .doc(widget.classId)
                                            .get();
                                        final classData = ClassData.fromJson(
                                          classDoc.data()!,
                                        );
                                        final int newSessionNumber =
                                            nextAttendanceSessionNumberForDate(
                                              classData.attendance.keys,
                                              date,
                                            );
                                        final String sessionKey =
                                            buildAttendanceSessionKey(
                                              date: date,
                                              sessionNumber: newSessionNumber,
                                            );

                                        await firestore
                                            .collection('classes')
                                            .doc(widget.classId)
                                            .update({
                                              'attendance.$sessionKey': {
                                                for (final student
                                                    in studentsData)
                                                  student.id:
                                                      selectedStudentIds
                                                          .contains(student.id)
                                                      ? selectedBulkType.name
                                                      : AttendanceType
                                                            .absent
                                                            .name,
                                              },
                                            });
                                        studentAttendanceStore.markStale();
                                        if (context.mounted) {
                                          Navigator.of(
                                            ctx,
                                          ).pop(true);
                                        }
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
