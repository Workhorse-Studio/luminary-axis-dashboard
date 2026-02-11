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
    return Center(
      child: Container(
        width: 500,
        height: MediaQuery.of(context).size.height * 0.4,
        foregroundDecoration: dialogForegroundDecoration,
        child: Scaffold(
          backgroundColor: AxisColors.blackPurple50,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => ConfirmationDialog(
                              confirmationMsg: 'Confirm changes?',
                            ),
                          );
                          if (!confirm) return;
                          if (context.mounted) {
                            Navigator.of(context).pop<RegisterForClassData>((
                              classId: currentClassId,
                              sessionsCount:
                                  int.tryParse(sessionCountController.text) ??
                                  -1,
                            ));
                          }
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
                                        whereNotIn: widget
                                            .classesDataCache
                                            .registry
                                            .keys,
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
                  Text('Session Count', style: heading3),
                  const SizedBox(height: 20),

                  TextField(
                    controller: sessionCountController,
                    style: body2,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AxisColors.blackPurple20),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AxisColors.blackPurple20),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
