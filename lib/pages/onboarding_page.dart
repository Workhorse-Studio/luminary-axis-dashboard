part of axis_dashboard;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<StatefulWidget> createState() => OnboardingPageState();
}

class OnboardingPageState extends State<OnboardingPage> {
  List<QueryDocumentSnapshot<JSON>> classesDocs = [];
  List<QueryDocumentSnapshot<JSON>> teachersDocs = [];
  QueryDocumentSnapshot<JSON>? selectedTeacher;
  QueryDocumentSnapshot<JSON>? selectedClass;

  final TextEditingController nameController = TextEditingController(),
      hpController = TextEditingController(),
      parentsNameController = TextEditingController(),
      parentsHpController = TextEditingController(),
      teachersNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AxisColors.blackPurple50,
      body: Padding(
        padding: const EdgeInsetsGeometry.only(
          left: 260,
          right: 260,
        ),
        child: SingleChildScrollView(
          child: FutureBuilderTemplate(
            future: () async {
              if (classesDocs.isEmpty) {
                classesDocs =
                    (await firestore.collection('classes').get()).docs;
              }
              if (teachersDocs.isEmpty) {
                teachersDocs =
                    (await firestore
                            .collection('users')
                            .where('role', whereIn: ['teacher', 'admin'])
                            .get())
                        .docs;
              }
              return classesDocs;
            }(),
            builder: (context, snapshot) => Theme(
              data: ThemeData(
                inputDecorationTheme: InputDecorationTheme(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AxisColors.lilacPurple20),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  Text(
                    'Student Onboarding Form',
                    style: heading1,
                  ),
                  const SizedBox(height: 60),
                  Text(
                    'Full Name',
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    cursorColor: AxisColors.lilacPurple20,
                    style: body2,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Student Contact Number',
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: hpController,
                    style: body2,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Parent's Name",
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: parentsNameController,
                    style: body2,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Parent's Contact Number",
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: parentsHpController,
                    style: body2,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Select your teacher",
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioGroup<QueryDocumentSnapshot<JSON>>(
                    groupValue: selectedTeacher,
                    onChanged: (selected) => setState(() {
                      selected != null ? selectedTeacher = selected : null;
                    }),
                    child: Column(
                      children: [
                        for (final td in teachersDocs)
                          Row(
                            children: [
                              Radio(
                                value: td,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                TeacherData.fromJson(td.data()).name,
                                style: body2,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),
                  Text(
                    'Select your class',
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioGroup(
                    groupValue: selectedClass,
                    onChanged: (selected) => selected != null
                        ? setState(() {
                            selectedClass = selected;
                          })
                        : null,
                    child: Column(
                      children: [
                        for (final cl in classesDocs) ...[
                          const SizedBox(height: 5),

                          Row(
                            children: [
                              Radio(
                                value: cl,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                ClassData.fromJson(cl.data()).name,
                                style: body2,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  const SizedBox(height: 30),
                  AxisButton.text(
                    width: 90,
                    onPressed: () async {
                      final String msg;
                      if (nameController.text != '' &&
                          hpController.text != '' &&
                          parentsHpController.text != '' &&
                          parentsNameController.text != '' &&
                          selectedClass != null &&
                          selectedTeacher != null) {
                        await firestore
                            .collection('global')
                            .doc('state')
                            .collection('pendingOnboarding')
                            .add(
                              OnboardingStudentData(
                                studentContactNo: hpController.text,
                                studentName: nameController.text,
                                parentContactNo: parentsNameController.text,
                                parentName: parentsHpController.text,
                                teacherId: selectedTeacher!.id,
                                classId: selectedClass!.id,
                              ).toJson(),
                            );
                        msg =
                            "Onboarding information submitted for admin's review successfully.";
                      } else {
                        msg =
                            "Ensure no fields are empty, and all questions are answered.";
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    },
                    isHighlighted: true,
                    label: 'Submit',
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
