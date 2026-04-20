part of axis_dashboard;

class TeacherCreationDialog extends StatefulWidget {
  final String? teacherId;
  const TeacherCreationDialog({
    required this.teacherId,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => TeacherCreationDialogState();
}

class TeacherCreationDialogState extends State<TeacherCreationDialog> {
  final GenericCache<DocumentSnapshot<JSON>> templatesCache = GenericCache(
    (classId) => firestore.collection('templates').doc(classId).get(),
  );
  final GenericCache<DocumentSnapshot<JSON>> classesCache = GenericCache(
    (classId) => firestore.collection('classes').doc(classId).get(),
  );
  final Map<String, bool> isTemplateSelected = {};
  final Map<String, bool> isClassSelected = {};

  TextEditingController teacherNameController = TextEditingController(text: '');
  TextEditingController teacherEmailController = TextEditingController(
    text: '',
  );
  DocumentSnapshot<JSON>? teacherData;
  bool hasInit = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 500,
        height: MediaQuery.of(context).size.height * 0.72,
        foregroundDecoration: dialogForegroundDecoration,
        child: Scaffold(
          backgroundColor: AxisColors.blackPurple50,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Theme(
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
              child: FutureBuilderTemplate(
                key: ValueKey(widget.teacherId),
                future: () async {
                  if (!hasInit) {
                    await templatesCache.initAll(
                      collection: firestore.collection('templates'),
                    );
                    await classesCache.initAll(
                      collection: firestore.collection('classes'),
                    );
                    TeacherData? teacher;
                    if (widget.teacherId != null) {
                      teacherData = await firestore
                          .collection('users')
                          .doc(widget.teacherId)
                          .get();
                      teacher = TeacherData.fromJson(teacherData!.data()!);
                      teacherNameController.text = teacher.name;
                      teacherEmailController.text = teacher.email;
                    }
                    for (final k in classesCache.registry.keys) {
                      isClassSelected[k] = teacher != null
                          ? teacher.classIds.contains(k)
                          : false;
                    }
                    for (final k in templatesCache.registry.keys) {
                      isTemplateSelected[k] = teacher != null
                          ? teacher.offeredClassTemplates.contains(k)
                          : false;
                    }
                    hasInit = true;
                  }
                  return hasInit;
                }(),
                builder: (context, snapshot) => SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teacher Name',
                        style: heading3,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: teacherNameController,
                        style: body2,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Teacher Email',
                        style: heading3,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: teacherEmailController,
                        style: body2,
                      ),
                      const SizedBox(height: 30),

                      /* Text(
                        'Classes Assigned',
                        style: heading3,
                      ),
                      const SizedBox(height: 6),
                      ...[
                        for (final classEntry
                            in classesCache.registry.entries) ...[
                          Row(
                            children: [
                              Checkbox(
                                key: ValueKey(isClassSelected[classEntry.key]),
                                value: isClassSelected[classEntry.key],
                                onChanged: (isSelected) async {
                                  if (isSelected != null) {
                                    setState(() {
                                      isClassSelected[classEntry.key] =
                                          isSelected;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 10),
                              Text(
                                ClassData.fromJson(
                                  classEntry.value.data()!,
                                ).name,
                                style: body2,
                              ),
                            ],
                          ),
                        ],
                      ], */
                      const SizedBox(height: 30),
                      Text(
                        'Templates Assigned',
                        style: heading3,
                      ),
                      const SizedBox(height: 6),
                      ...[
                        for (final templateEntry
                            in templatesCache.registry.entries) ...[
                          Row(
                            children: [
                              Checkbox(
                                key: ValueKey(
                                  isTemplateSelected[templateEntry.key],
                                ),
                                value: isTemplateSelected[templateEntry.key],
                                onChanged: (isSelected) async {
                                  if (isSelected != null) {
                                    setState(() {
                                      isTemplateSelected[templateEntry.key] =
                                          isSelected;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 10),
                              Text(
                                ClassTemplate.fromJson(
                                  templateEntry.value.data()!,
                                ).className,
                                style: body2,
                              ),
                            ],
                          ),
                        ],
                      ],
                      const SizedBox(height: 50),
                      AxisButton.text(
                        label: 'Save',
                        onPressed: () async {
                          if (teacherNameController.text != '' &&
                              teacherEmailController.text != '') {
                            Navigator.of(context).pop(
                              TeacherData(
                                name: teacherNameController.text,
                                role: teacherData != null
                                    ? TeacherData.fromJson(teacherData!.data()!).role
                                    : 'teacher',
                                email: teacherEmailController.text,
                                classIds: isClassSelected.entries
                                    .where((e) => e.value)
                                    .map((e) => e.key)
                                    .toList(),
                                offeredClassTemplates: isTemplateSelected
                                    .entries
                                    .where((e) => e.value)
                                    .map((e) => e.key)
                                    .toList(),
                                invoiceIds: teacherData != null
                                    ? TeacherData.fromJson(
                                        teacherData!.data()!,
                                      ).invoiceIds
                                    : {},
                              ),
                            );
                          } else {
                            Navigator.of(context).pop(null);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
