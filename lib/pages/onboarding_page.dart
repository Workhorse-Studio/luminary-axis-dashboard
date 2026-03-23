part of axis_dashboard;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<StatefulWidget> createState() => OnboardingPageState();
}

class OnboardingPageState extends State<OnboardingPage> {
  List<QueryDocumentSnapshot<JSON>> classesDocs = [];
  List<QueryDocumentSnapshot<JSON>> teachersDocs = [];
  List<
    ({
      QueryDocumentSnapshot<JSON> teacherData,
      QueryDocumentSnapshot<JSON> classData,
    })
  >
  selections = [];

  final TextEditingController nameController = TextEditingController(),
      hpController = TextEditingController(),
      parentsNameController = TextEditingController(),
      parentsHpController = TextEditingController(),
      emailController = TextEditingController(),
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
                            .where('role', whereIn: const ['teacher', 'admin'])
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
                    'Invoicing Email',
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: emailController,
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
                    "Select your classes",
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...[
                    for (final tData in teachersDocs) ...[
                      for (final cData in classesDocs.where(
                        (cd) => TeacherData.fromJson(
                          tData.data(),
                        ).classIds.contains(cd.id),
                      ))
                        Row(
                          children: [
                            Checkbox(
                              value: selections.any(
                                (s) =>
                                    s.classData.id == cData.id &&
                                    s.teacherData.id == tData.id,
                              ),
                              onChanged: (sel) {
                                if (sel != null) {
                                  if (sel) {
                                    selections.add((
                                      classData: cData,
                                      teacherData: tData,
                                    ));
                                  } else {
                                    selections.removeWhere(
                                      (s) =>
                                          s.classData.id == cData.id &&
                                          s.teacherData.id == tData.id,
                                    );
                                  }
                                  setState(() {});
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${ClassData.fromJson(cData.data()).name} by ${TeacherData.fromJson(tData.data()).name}",
                              style: body2,
                            ),
                          ],
                        ),
                    ],
                  ],

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
                          selections.isNotEmpty) {
                        await firestore
                            .collection('global')
                            .doc('state')
                            .collection('pendingOnboarding')
                            .add(
                              OnboardingStudentData(
                                studentContactNo: hpController.text,
                                studentName: nameController.text,
                                email: emailController.text,
                                parentContactNo: parentsNameController.text,
                                parentName: parentsHpController.text,
                                classIdToTeacherId: {
                                  for (final sel in selections)
                                    sel.classData.id: sel.teacherData.id,
                                },
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
