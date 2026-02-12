part of axis_dashboard;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<StatefulWidget> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  bool hasLoaded = false;
  String name = '';

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Dashboard',
      actions: [
        RichText(
          text: TextSpan(
            text: 'powered by',
            style: body2,
            children: [
              TextSpan(
                text: '  Luminary',
                style: heading3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
      ],
      body: (_) => Align(
        alignment: Alignment.topLeft,
        child: switch (role) {
          'teacher' => SizedBox(),
          'admin' => FutureBuilderTemplate(
            future: () async {
              if (!hasLoaded) {
                name =
                    (await firestore
                            .collection('users')
                            .doc(auth.currentUser!.uid)
                            .get())
                        .data()!['name'];
                hasLoaded = true;
              }
              return name;
            }(),
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(left: 40, top: 40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $name!',
                      style: heading2,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "You're signed in as ${isAdmin ? 'an' : 'a'} ${isAdmin ? 'admin' : role}",
                      style: body2,
                    ),
                    const SizedBox(height: 30),
                    if (isAdmin) ...[
                      Text('Pending Onboarding', style: heading1),
                      const SizedBox(height: 10),
                      FutureBuilderTemplate(
                        future: () async {
                          return (await firestore
                                  .collection('global')
                                  .doc('state')
                                  .collection('pendingOnboarding')
                                  .where('hasOnboarded', isEqualTo: false)
                                  .get())
                              .docs;
                        }(),
                        builder: (context, snapshot) {
                          return snapshot.data!.isEmpty
                              ? Center(
                                  child: Text(
                                    'No students pending onboarding.',
                                    style: heading3,
                                  ),
                                )
                              : SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.3,
                                  height:
                                      MediaQuery.of(context).size.height * 0.9,
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: ListView(
                                      children: [
                                        for (final poDoc in snapshot.data!)
                                          AxisCard(
                                            header:
                                                OnboardingStudentData.fromJson(
                                                  poDoc.data(),
                                                ).studentName,
                                            width: double.infinity,
                                            height: 360,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 30,
                                                right: 30,
                                                bottom: 30,
                                              ),
                                              child: Align(
                                                alignment: Alignment.topLeft,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Contact: ${OnboardingStudentData.fromJson(
                                                        poDoc.data(),
                                                      ).studentContactNo}",
                                                      style: body2,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      "Parent: ${OnboardingStudentData.fromJson(
                                                        poDoc.data(),
                                                      ).parentName}",
                                                      style: body2,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      "Parent's Contact: ${OnboardingStudentData.fromJson(
                                                        poDoc.data(),
                                                      ).parentContactNo}",
                                                      style: body2,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    FutureBuilderTemplate(
                                                      future: () async {
                                                        return (await firestore
                                                                .collection(
                                                                  'users',
                                                                )
                                                                .doc(
                                                                  OnboardingStudentData.fromJson(
                                                                    poDoc
                                                                        .data(),
                                                                  ).teacherId,
                                                                )
                                                                .get())
                                                            .data()!;
                                                      }(),
                                                      builder:
                                                          (
                                                            context,
                                                            snapshot,
                                                          ) => Text(
                                                            TeacherData.fromJson(
                                                              snapshot.data!,
                                                            ).name,
                                                            style: heading3,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    FutureBuilderTemplate(
                                                      future: () async {
                                                        return (await firestore
                                                                .collection(
                                                                  'classes',
                                                                )
                                                                .doc(
                                                                  OnboardingStudentData.fromJson(
                                                                    poDoc
                                                                        .data(),
                                                                  ).classId,
                                                                )
                                                                .get())
                                                            .data()!;
                                                      }(),
                                                      builder:
                                                          (
                                                            context,
                                                            snapshot,
                                                          ) => Text(
                                                            ClassData.fromJson(
                                                              snapshot.data!,
                                                            ).name,
                                                            style: heading3,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    AxisButton.text(
                                                      label: 'Approve',
                                                      isHighlighted: true,
                                                      width: 100,
                                                      height: 60,
                                                      onPressed: () async {
                                                        final obData =
                                                            OnboardingStudentData.fromJson(
                                                              poDoc.data(),
                                                            );
                                                        onboardStudent(
                                                          StudentData(
                                                            role: 'student',
                                                            name: obData
                                                                .studentName,
                                                            email: obData.email,
                                                            studentContactNo: obData
                                                                .studentContactNo,
                                                            parentContactNo: obData
                                                                .parentContactNo,
                                                            parentName: obData
                                                                .parentContactNo,
                                                            initialSessionCount:
                                                                {
                                                                  obData.classId:
                                                                      0,
                                                                },
                                                          ),
                                                        );
                                                        setState(() {});
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                        },
                      ),
                      const SizedBox(height: 30),
                      Text('Class Details', style: heading1),
                      const SizedBox(height: 10),
                      FutureBuilderTemplate(
                        future: () async {
                          return (await firestore.collection('classes').get())
                              .docs;
                        }(),
                        builder: (context, snapshot) {
                          return snapshot.data!.isEmpty
                              ? Center(
                                  child: Text(
                                    'No classes.',
                                    style: heading3,
                                  ),
                                )
                              : Wrap(
                                  spacing: 50,
                                  runSpacing: 50,
                                  children: [
                                    for (final clDoc in snapshot.data!)
                                      Container(
                                        width: 300,
                                        decoration: BoxDecoration(
                                          color: AxisColors.blackPurple30
                                              .withValues(alpha: 0.4),
                                          border: Border.all(
                                            color: AxisColors.blackPurple30,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ClassData.fromJson(
                                                  clDoc.data(),
                                                ).name,
                                                style: heading2,
                                              ),

                                              for (final studId
                                                  in ClassData.fromJson(
                                                    clDoc.data(),
                                                  ).studentIds) ...[
                                                const SizedBox(height: 20),
                                                Container(
                                                  width: double.infinity,
                                                  height: 40,

                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                    border: Border.all(
                                                      color: AxisColors
                                                          .blackPurple30,
                                                    ),
                                                    color: AxisColors
                                                        .blackPurple30
                                                        .withValues(alpha: 0.6),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    child: FutureBuilderTemplate(
                                                      future: () async {
                                                        return StudentData.fromJson(
                                                          (await firestore
                                                                  .collection(
                                                                    'users',
                                                                  )
                                                                  .doc(studId)
                                                                  .get())
                                                              .data()!,
                                                        );
                                                      }(),
                                                      builder:
                                                          (
                                                            context,
                                                            snapshot,
                                                          ) => Text(
                                                            snapshot.data!.name,
                                                            style: body2,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    AxisButton.text(
                                      label: 'Add New Class',
                                      width: 160,
                                      isHighlighted: true,
                                      onPressed: () async {
                                        final (ClassData, String)? classData =
                                            await showDialog(
                                              context: context,
                                              builder: (_) =>
                                                  ClassCreationDialog(),
                                            );
                                        final String msg;
                                        if (classData != null) {
                                          final docRef = await firestore
                                              .collection('classes')
                                              .add(classData.$1.toJson());
                                          final classIds = TeacherData.fromJson(
                                            (await firestore
                                                    .collection('users')
                                                    .doc(classData.$2)
                                                    .get())
                                                .data()!,
                                          ).classIds;
                                          await firestore
                                              .collection('users')
                                              .doc(classData.$2)
                                              .update({
                                                'classes': [
                                                  ...classIds,
                                                  docRef.id,
                                                ],
                                              });
                                          msg = 'Class created successfully!';
                                        } else {
                                          msg = 'No new class created';
                                        }
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(msg),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          String _ => const SizedBox(),
        },
      ),
    );
  }
}
