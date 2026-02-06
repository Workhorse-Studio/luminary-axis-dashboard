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
  final Map<String, bool> selections = {};
  final TextEditingController nameController = TextEditingController(),
      hpController = TextEditingController(),
      parentsNameController = TextEditingController(),
      parentsHpController = TextEditingController(),
      teachersNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AxisColors.blackPurple50,
      child: Padding(
        padding: const EdgeInsetsGeometry.only(
          left: 260,
          right: 260,
          top: 100,
        ),
        child: SingleChildScrollView(
          child: FutureBuilderTemplate(
            future: () async {
              if (classesDocs.isEmpty) {
                classesDocs =
                    (await firestore.collection('classes').get()).docs;
                selections.addAll({for (final cl in classesDocs) cl.id: false});
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
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Student Contact Number',
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: hpController),
                  const SizedBox(height: 15),
                  Text(
                    "Parent's Name",
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: parentsNameController),
                  const SizedBox(height: 15),
                  Text(
                    "Parent's Contact Number",
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: parentsHpController),
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
                    'Select your class(es)',
                    style: heading3.copyWith(
                      color: AxisColors.lilacPurple50.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...[
                    for (final cl in classesDocs) ...[
                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Checkbox(
                            value: selections[cl.id],
                            onChanged: (selected) => selected != null
                                ? setState(() {
                                    selections[cl.id] = selected;
                                  })
                                : null,
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
                  const SizedBox(height: 15),

                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: () async {},
                    child: Text('Submit'),
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
