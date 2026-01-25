part of axis_dashboard;

class TermDetailsPage extends StatefulWidget {
  const TermDetailsPage({super.key});

  @override
  State<StatefulWidget> createState() => TermDetailsPageState();
}

class TermDetailsPageState extends State<TermDetailsPage> {
  GlobalState? globalState;

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        return (globalState == null)
            ? globalState = GlobalState.fromJson(
                (await firestore.collection('global').doc('state').get())
                    .data()!,
              )
            : globalState;
      }(),
      builder: (context, snapshot) => Navbar(
        pageTitle:
            'Term Details (${DateTime.now().year} T${globalState!.currentTermNum})',
        actions: [
          if (globalState!.hasEndDateSet &&
              DateTime.now().isAfter(
                DateTime.fromMillisecondsSinceEpoch(
                  globalState!.currentTermEndDate,
                ).subtract(const Duration(days: 7)),
              ))
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                "${DateTime.fromMillisecondsSinceEpoch(
                  globalState!.currentTermEndDate,
                ).difference(DateTime.now()).inDays} days to term end",
              ),
            ),
        ],
        body: (context) => SingleChildScrollView(
          child: Column(
            key: ValueKey(globalState!.currentTermEndDate),

            children: [
              const SizedBox(height: 30),
              Text(
                'Current Term Start Date:\n${DateTime.fromMillisecondsSinceEpoch(globalState!.currentTermStartDate).toTimestampStringShort()}',
              ),
              const SizedBox(height: 20),
              Text(
                'Current Term End Date: ${globalState!.hasEndDateSet ? DateTime.fromMillisecondsSinceEpoch(globalState!.currentTermEndDate).toTimestampStringShort() : 'No date set.'}',
              ),
              TextButton(
                onPressed: () async {
                  final endDate = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (endDate != null) {
                    await firestore.collection('global').doc('state').update({
                      'currentTermEndDate': endDate.millisecondsSinceEpoch,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text('Term end date set successfully!'),
                        ),
                      );
                      globalState = globalState = GlobalState.fromJson(
                        (await firestore
                                .collection('global')
                                .doc('state')
                                .get())
                            .data()!,
                      );
                    }

                    setState(() {});
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text('No date set'),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  globalState!.currentTermEndDate == 0
                      ? 'Set Date'
                      : 'Modify Date',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
