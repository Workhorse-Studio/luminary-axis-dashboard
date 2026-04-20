part of axis_dashboard;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<StatefulWidget> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  bool hasLoaded = false;
  String name = '';
  GlobalState? globalState;
  late TermData currentTerm;
  final GenericCache<DocumentSnapshot<JSON>> classesCache = GenericCache(
    (classId) async => firestore.collection('classes').doc(classId).get(),
  );
  final GenericCache<DocumentSnapshot<JSON>> teachersCache = GenericCache(
    (teacherId) async => firestore.collection('users').doc(teacherId).get(),
  );

  /// { studentId : { classId: teacherId } }
  final Map<String, Map<String, String?>> assignedTeachers = {};

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

                await classesCache.initAll(
                  collection: firestore.collection('classes'),
                );
                await teachersCache.initAll(
                  query: firestore
                      .collection('users')
                      .where('role', whereIn: const ['teacher', 'admin']),
                );
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
                    if (isAdmin)
                      FutureBuilderTemplate(
                        future: () async {
                          final gs = (globalState == null)
                              ? globalState = GlobalState.fromJson(
                                  (await firestore
                                          .collection('global')
                                          .doc('state')
                                          .get())
                                      .data()!,
                                )
                              : globalState;

                          return currentTerm = gs!.terms[gs.currentTermNum];
                        }(),
                        builder: (context, snapshot) =>
                            (currentTerm.hasEndDateSet &&
                                DateTime.now().isSameDayAs(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    currentTerm.termEndDate,
                                  ),
                                ))
                            ? Text(
                                'New Term Setup Required\nPlease update initial session allocations for students before logging attendance for the new term.',
                                style: body2,
                              )
                            : const SizedBox(),
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
                                  width: MediaQuery.of(context).size.width * 8,
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Wrap(
                                      spacing: 20,
                                      runSpacing: 20,
                                      children: [
                                        for (final poDoc in snapshot.data!)
                                          ...generateSeparateOnboardingForEachClass(
                                            poDoc,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                        },
                      ),
                      const SizedBox(height: 60),
                      Text('Classes', style: heading1),
                      const SizedBox(height: 10),

                      classesCache.registry.isEmpty
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
                                for (final clEntry
                                    in classesCache.registry.entries)
                                  AxisCard(
                                    header: ClassData.fromJson(
                                      clEntry.value.data()!,
                                    ).name,
                                    width: 300,
                                    height: 190,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Teacher',
                                                style: body2,
                                              ),
                                              const Spacer(),
                                              Text(
                                                TeacherData.fromJson(
                                                  teachersCache.registry.entries
                                                          .where(
                                                            (e) =>
                                                                TeacherData.fromJson(
                                                                      e.value
                                                                          .data()!,
                                                                    ).classIds
                                                                    .contains(
                                                                      clEntry
                                                                          .key,
                                                                    ),
                                                          )
                                                          .firstOrNull
                                                          ?.value
                                                          .data() ??
                                                      TeacherData(
                                                        name: 'No teacher',
                                                        role: 'teacher',
                                                        classIds: [clEntry.key],
                                                        email: '',
                                                        offeredClassTemplates:
                                                            const [],
                                                        invoiceIds: const {},
                                                      ).toJson(),
                                                ).name,
                                                style: body2,
                                                textAlign: TextAlign.right,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                'Students',
                                                style: body2,
                                              ),
                                              const Spacer(),
                                              Text(
                                                ClassData.fromJson(
                                                  clEntry.value.data()!,
                                                ).studentIds.length.toString(),
                                                style: body2,
                                                textAlign: TextAlign.right,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                      const SizedBox(height: 30),
                      AxisButton.text(
                        label: 'Create New Class Template',
                        width: 260,
                        isHighlighted: true,
                        onPressed: () async {
                          final ClassTemplate? classData = await showDialog(
                            context: context,
                            builder: (_) => ClassCreationDialog(),
                          );
                          final String msg;
                          if (classData != null) {
                            await firestore
                                .collection('templates')
                                .add(classData.toJson());

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
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 40),
                      const SizedBox(height: 60),
                      Text('Teachers', style: heading1),
                      const SizedBox(height: 10),

                      teachersCache.registry.isEmpty
                          ? Center(
                              child: Text(
                                'No teachers.',
                                style: heading3,
                              ),
                            )
                          : Wrap(
                              spacing: 50,
                              runSpacing: 50,
                              children: [
                                for (final teacherEntry
                                    in teachersCache.registry.entries)
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
                                          Row(
                                            children: [
                                              Text(
                                                TeacherData.fromJson(
                                                  teacherEntry.value.data()!,
                                                ).name,
                                                style: heading2,
                                              ),
                                              const Spacer(),
                                              AxisButton(
                                                width: 45,
                                                height: 45,
                                                child: Icon(
                                                  Icons.edit,
                                                  color:
                                                      AxisColors.blackPurple20,
                                                ),
                                                onPressed: () async {
                                                  final TeacherData?
                                                  tData = await showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        TeacherCreationDialog(
                                                          teacherId:
                                                              teacherEntry.key,
                                                        ),
                                                  );
                                                  final String msg;
                                                  if (tData != null) {
                                                    await firestore
                                                        .collection('users')
                                                        .doc(teacherEntry.key)
                                                        .set(tData.toJson());

                                                    for (final template
                                                        in tData
                                                            .offeredClassTemplates) {
                                                      bool exists = false;
                                                      for (final clId
                                                          in tData.classIds) {
                                                        final clDoc = await classesCache.get(clId);
                                                        if (!clDoc.exists) continue;
                                                        if (ClassData.fromJson(
                                                              clDoc.data()!,
                                                            ).templateReference ==
                                                            template) {
                                                          exists = true;
                                                          break;
                                                        }
                                                      }
                                                      if (!exists) {
                                                        final docRef = await firestore
                                                            .collection(
                                                              'classes',
                                                            )
                                                            .add(
                                                              ClassData(
                                                                name: ClassTemplate.fromJson(
                                                                  (await (firestore
                                                                              .collection(
                                                                                'templates',
                                                                              )
                                                                              .doc(
                                                                                template,
                                                                              ))
                                                                          .get())
                                                                      .data()!,
                                                                ).className,
                                                                studentIds:
                                                                    const [],
                                                                templateReference:
                                                                    template,
                                                                attendance: {},
                                                              ).toJson(),
                                                            );
                                                        classesCache.registry[docRef.id] = await docRef.get();
                                                        await firestore
                                                            .collection('users')
                                                            .doc(
                                                              teacherEntry.key,
                                                            )
                                                            .update(
                                                              {
                                                                'classes':
                                                                    tData
                                                                        .classIds
                                                                      ..add(
                                                                        docRef
                                                                            .id,
                                                                      ),
                                                              },
                                                            );
                                                      }
                                                    }
                                                    teachersCache
                                                        .registry[teacherEntry
                                                        .key] = await firestore
                                                        .collection('users')
                                                        .doc(
                                                          teacherEntry.key,
                                                        )
                                                        .get();
                                                    msg =
                                                        'Teacher details updated!';
                                                    setState(() {});
                                                  } else {
                                                    msg = 'No updates made.';
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
                                          ),

                                          if (TeacherData.fromJson(
                                            teacherEntry.value.data()!,
                                          ).classIds.isEmpty)
                                            Text(
                                              'No classes taught.',
                                              style: body2,
                                            ),
                                          for (final clId
                                              in TeacherData.fromJson(
                                                teacherEntry.value.data()!,
                                              ).classIds) ...[
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
                                                  color:
                                                      AxisColors.blackPurple30,
                                                ),
                                                color: AxisColors.blackPurple30
                                                    .withValues(alpha: 0.6),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                child: FutureBuilderTemplate(
                                                  future: () async {
                                                    return ClassData.fromJson(
                                                      (await classesCache.get(
                                                        clId,
                                                      )).data()!,
                                                    );
                                                  }(),
                                                  builder:
                                                      (
                                                        context,
                                                        snapshot,
                                                      ) => Row(
                                                        children: [
                                                          Text(
                                                            snapshot.data!.name,
                                                            style: body2,
                                                          ),
                                                          const Spacer(),
                                                          Text(
                                                            "${snapshot.data!.studentIds.length} students",
                                                            style: body2.copyWith(
                                                              color: body2
                                                                  .color!
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                      const SizedBox(height: 30),
                      AxisButton.text(
                        label: 'Add New Teacher',
                        width: 180,
                        isHighlighted: true,
                        onPressed: () async {
                          final TeacherData? tData = await showDialog(
                            context: context,
                            builder: (_) => TeacherCreationDialog(
                              teacherId: null,
                            ),
                          );
                          final String msg;
                          if (tData != null) {
                            final res = await makeRequest(
                              body: jsonEncode({
                                'op': 'registerTeacher',
                                'name': tData.name,
                                'email': tData.email,
                              }).toJS,
                            );
                            if (res.ok) {
                              if (res.body != null &&
                                  res.body!.containsKey('uid')) {
                                final String uid = res.body!['uid'] as String;
                                for (final template
                                    in tData.offeredClassTemplates) {
                                  bool exists = false;
                                  for (final clId in tData.classIds) {
                                    final clDoc = await classesCache.get(clId);
                                    if (!clDoc.exists) continue;
                                    if (ClassData.fromJson(
                                          clDoc.data()!,
                                        ).templateReference ==
                                        template) {
                                      exists = true;
                                      break;
                                    }
                                  }
                                  if (!exists) {
                                    final docRef = await firestore
                                        .collection(
                                          'classes',
                                        )
                                        .add(
                                          ClassData(
                                            name: ClassTemplate.fromJson(
                                              (await (firestore
                                                          .collection(
                                                            'templates',
                                                          )
                                                          .doc(
                                                            template,
                                                          ))
                                                      .get())
                                                  .data()!,
                                            ).className,
                                            studentIds: const [],
                                            templateReference: template,
                                            attendance: {},
                                          ).toJson(),
                                        );
                                    classesCache.registry[docRef.id] = await docRef.get();
                                    await firestore
                                        .collection('users')
                                        .doc(
                                          uid,
                                        )
                                        .set(tData.toJson());
                                    await firestore
                                        .collection('users')
                                        .doc(
                                          uid,
                                        )
                                        .update(
                                          {
                                            'classes': tData.classIds
                                              ..add(
                                                docRef.id,
                                              ),
                                          },
                                        );
                                  }
                                }
                                msg = 'New teacher added successfully!';
                                final docRef = firestore
                                    .collection('users')
                                    .doc(uid);
                                await docRef.set(tData.toJson());
                                teachersCache.registry[docRef.id] = await docRef
                                    .get();
                                setState(() {});
                              } else {
                                msg =
                                    'Something went wrong on the client-side when setting teacher data.';
                              }
                            } else {
                              msg =
                                  'An error occurred on the server-side when creating the teacher account.';
                            }
                          } else {
                            msg = 'Action cancelled.';
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 40),
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

  List<Widget> generateSeparateOnboardingForEachClass(
    QueryDocumentSnapshot<JSON> poDoc,
  ) {
    final List<Widget> cards = [];
    final obd = OnboardingStudentData.fromJson(
      poDoc.data(),
    );
    for (final tempId in obd.classes) {
      cards.add(
        AxisCard(
          header: obd.studentName,
          width: 450,
          height: 380,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 30,
              right: 30,
              bottom: 30,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilderTemplate(
                    future: (() async => ClassTemplate.fromJson(
                      (await firestore
                              .collection('templates')
                              .doc(tempId)
                              .get())
                          .data()!,
                    ))(),
                    builder: (_, snapshot) => Text(
                      snapshot.data!.className,
                      style: heading3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Contact: ${obd.studentContactNo}",
                    style: body2,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Parent: ${obd.parentName}",
                    style: body2,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Parent's Contact: ${obd.parentContactNo}",
                    style: body2,
                  ),
                  const SizedBox(height: 10),

                  AxisDropdownButton(
                    width: 240,
                    entries: [
                      for (final tEntry in teachersCache.registry.entries.where(
                        (t) =>
                            TeacherData.fromJson(
                              t.value.data()!,
                            ).offeredClassTemplates.contains(
                              tempId,
                            ),
                      ))
                        (
                          TeacherData.fromJson(
                            tEntry.value.data()!,
                          ).name,
                          tEntry,
                        ),
                    ],
                    onSelected: (selection) {
                      if (!assignedTeachers.containsKey(poDoc.id)) {
                        assignedTeachers[poDoc.id] = {};
                      }
                      assignedTeachers[poDoc.id]![tempId] = selection?.key;
                    },
                  ),

                  const SizedBox(height: 20),
                  AxisButton.text(
                    label: 'Approve',
                    isHighlighted: true,
                    width: 100,
                    height: 60,
                    onPressed: () async {
                      final String msg;
                      if (assignedTeachers.containsKey(
                            poDoc.id,
                          ) &&
                          assignedTeachers[poDoc.id] != null) {
                        final uid = await onboardStudent(obd);

                        final td = TeacherData.fromJson(
                          (await firestore
                                  .collection(
                                    'users',
                                  )
                                  .doc(
                                    assignedTeachers[poDoc.id]![tempId],
                                  )
                                  .get())
                              .data()!,
                        );
                        bool found = false;
                        for (final clId in td.classIds) {
                          final clRef = (await classesCache.get(clId));
                          final cd = ClassData.fromJson(
                            clRef.data()!,
                          );
                          if (cd.templateReference == tempId) {
                            await clRef.reference.update({
                              'students': cd.studentIds..add(uid),
                            });
                            final termDr = firestore
                                .collection('global')
                                .doc('state')
                                .collection('allocations')
                                .doc(
                                  globalState!
                                      .terms[globalState!.currentTermNum]
                                      .termName,
                                );
                            if ((await termDr.get()).exists) {
                              await termDr.update({'$clId.$uid': 0});
                            } else {
                              await termDr.set({
                                clId: {uid: 0},
                              });
                            }
                            await firestore.collection('users').doc(uid).update(
                              {'withdrawn.$clId': false},
                            );

                            found = true;
                            break;
                          }
                        }
                        final template = ClassTemplate.fromJson(
                          (await firestore
                                  .collection('templates')
                                  .doc(tempId)
                                  .get())
                              .data()!,
                        );
                        if (!found) {
                          msg =
                              'The selected teacher does not teach any ${template.className} classes.';
                        } else {
                          await firestore
                              .collection(
                                'global',
                              )
                              .doc('state')
                              .collection(
                                'pendingOnboarding',
                              )
                              .doc(poDoc.id)
                              .delete();
                          msg = 'Student has been onboarded';
                        }

                        setState(() {});
                      } else {
                        msg =
                            "Please select a teacher to assign to this student.";
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              msg,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return cards;
  }
}
