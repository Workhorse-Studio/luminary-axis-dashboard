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
        child: FutureBuilderTemplate(
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
                                width: MediaQuery.of(context).size.width * 0.3,
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
                                                                  poDoc.data(),
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
                                                                  poDoc.data(),
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
                                                          initialSessionCount: {
                                                            obData.classId: 0,
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
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
