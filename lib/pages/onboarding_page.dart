part of axis_dashboard;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<StatefulWidget> createState() => OnboardingPageState();
}

class OnboardingPageState extends State<OnboardingPage> {
  List<QueryDocumentSnapshot<JSON>> classTemplateDocs = [];
  List<QueryDocumentSnapshot<JSON>> teachersDocs = [];
  List<QueryDocumentSnapshot<JSON>> selections = [];

  final TextEditingController nameController = TextEditingController(),
      hpController = TextEditingController(),
      parentsNameController = TextEditingController(),
      parentsHpController = TextEditingController(),
      schoolController = TextEditingController(),
      addressController = TextEditingController(),
      postalCodeController = TextEditingController(),
      subjectCombi = TextEditingController(),
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
              if (classTemplateDocs.isEmpty) {
                classTemplateDocs =
                    (await firestore.collection('templates').get()).docs;
              }
              if (teachersDocs.isEmpty) {
                teachersDocs =
                    (await firestore
                            .collection('users')
                            .where('role', whereIn: const ['teacher', 'admin'])
                            .get())
                        .docs;
              }
              return classTemplateDocs;
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
                    "School Name",
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: schoolController,
                    style: body2,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Full Address",
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    style: body2,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Postal Code",
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: postalCodeController,
                    style: body2,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Subject Combination",
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subjectCombi,
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

                  for (final cData in classTemplateDocs)
                    Row(
                      children: [
                        Checkbox(
                          value: selections.any((s) => s.id == cData.id),
                          onChanged: (sel) {
                            if (sel != null) {
                              if (sel) {
                                selections.add(
                                  cData,
                                );
                              } else {
                                selections.removeWhere((s) => s.id == cData.id);
                              }
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ClassTemplate.fromJson(cData.data()).className,
                          style: body2,
                        ),
                      ],
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
                                school: schoolController.text,
                                address: addressController.text,
                                postalCode: postalCodeController.text,
                                subjectCombi: subjectCombi.text,
                                classes: selections.map((s) => s.id).toList(),
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
