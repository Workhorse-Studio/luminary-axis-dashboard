part of axis_dashboard;

typedef RegisterForClassData = ({
  String classId,
  int sessionsCount,
});

class RegisterForClassDialog extends StatefulWidget {
  final String? fixedClassId;
  final GenericCache<DocumentSnapshot<JSON>> classesDataCache;

  const RegisterForClassDialog({
    required this.classesDataCache,
    this.fixedClassId,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => RegisterForClassDialogState();
}

class RegisterForClassDialogState extends State<RegisterForClassDialog> {
  final TextEditingController sessionCountController = TextEditingController();
  bool hasFetchedAllClasses = false;
  late String currentClassId;

  @override
  void initState() {
    currentClassId = widget.fixedClassId ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: 350,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop<RegisterForClassData>((
                        classId: '',
                        sessionsCount: -1,
                      ));
                    },
                    icon: Icon(Icons.cancel),
                  ),
                  const Spacer(),

                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop<RegisterForClassData>((
                        classId: currentClassId,
                        sessionsCount:
                            int.tryParse(sessionCountController.text) ?? -1,
                      ));
                    },
                    icon: Icon(Icons.check),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (widget.fixedClassId == null)
                FutureBuilderTemplate(
                  future: () async {
                    if (widget.fixedClassId != null) return const [];
                    if (!hasFetchedAllClasses) {
                      final newDocs =
                          (await firestore
                                  .collection('classes')
                                  .where(
                                    FieldPath.documentId,
                                    whereNotIn:
                                        widget.classesDataCache.registry.keys,
                                  )
                                  .get())
                              .docs;
                      for (final doc in newDocs) {
                        widget.classesDataCache.registry[doc.id] = doc;
                      }
                      hasFetchedAllClasses = true;
                    }
                    return const [];
                  }(),
                  builder: (_, context) => DropdownMenu(
                    onSelected: (value) =>
                        value != null ? currentClassId = value.key : null,
                    dropdownMenuEntries: [
                      for (final classEntry
                          in widget.classesDataCache.registry.entries)
                        DropdownMenuEntry(
                          value: classEntry,
                          label: ClassData.fromJson(
                            classEntry.value.data()!,
                          ).name,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: sessionCountController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
