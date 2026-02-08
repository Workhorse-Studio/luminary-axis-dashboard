part of axis_dashboard;

class StudentInfoDialog extends StatefulWidget {
  final String studentId;
  final QueryDocumentSnapshot<JSON> studentData;
  final Map<String, String> classIdToTeacherNameMap;

  const StudentInfoDialog({
    required this.studentId,
    required this.studentData,
    required this.classIdToTeacherNameMap,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => StudentInfoDialogState();
}

class StudentInfoDialogState extends State<StudentInfoDialog> {
  late QueryDocumentSnapshot<JSON> studentData;
  late final Map<String, String> classIdToTeacherNameMap;
  @override
  void initState() {
    studentData = widget.studentData;
    classIdToTeacherNameMap = widget.classIdToTeacherNameMap;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> generateContactDetailsRows(StudentData data) {
      return {
        "Name": data.name,
        "Contact Number": data.studentContactNo,
        "Parent's Name": data.parentName,
        "Parent's Contact Number": data.parentContactNo,
      };
    }

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.9,
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AxisColors.blackPurple20),
        ),
        child: Scaffold(
          backgroundColor: AxisColors.blackPurple50,
          body: Padding(
            padding: const EdgeInsetsGeometry.only(left: 40, right: 40),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Contact Details',
                    style: heading1,
                  ),
                  const SizedBox(height: 20),
                  for (final infoItem in generateContactDetailsRows(
                    StudentData.fromJson(studentData.data()),
                  ).entries) ...[
                    RichText(
                      text: TextSpan(
                        text: infoItem.key,
                        style: heading3,
                        children: [
                          TextSpan(
                            text: ": ${infoItem.value}",
                            style: heading3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 40),
                  Text(
                    'Registered Classes',
                    style: heading1,
                  ),
                  const SizedBox(height: 20),
                  FutureBuilderTemplate(
                    future: () async {
                      final sd = StudentData.fromJson(
                        studentData.data(),
                      );

                      return sd.initialSessionCount.isNotEmpty
                          ? (await firestore
                                    .collection('classes')
                                    .where(
                                      FieldPath.documentId,
                                      whereIn: sd.initialSessionCount.keys,
                                    )
                                    .get())
                                .docs
                          : const <QueryDocumentSnapshot<JSON>>[];
                    }(),

                    builder: (context, snapshot) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (snapshot.data!.isNotEmpty)
                          for (final clDoc in snapshot.data!) ...[
                            RichText(
                              text: TextSpan(
                                text: ClassData.fromJson(clDoc.data()).name,
                                style: heading3,
                                children: [
                                  TextSpan(
                                    text:
                                        " taught by ${classIdToTeacherNameMap[clDoc.id]}",
                                    style: heading3,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        if (snapshot.data!.isEmpty)
                          Text(
                            'Not registered for any classes.',
                            style: body2,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
