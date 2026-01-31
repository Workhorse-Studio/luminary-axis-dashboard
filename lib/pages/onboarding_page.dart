part of axis_dashboard;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<StatefulWidget> createState() => OnboardingPageState();
}

class OnboardingPageState extends State<OnboardingPage> {
  List<QueryDocumentSnapshot<JSON>> classesDocs = [];
  final Map<String, bool> selections = {};
  final TextEditingController nameController = TextEditingController(),
      hpController = TextEditingController(),
      parentsNameController = TextEditingController(),
      parentsHpController = TextEditingController(),
      teachersNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        child: FutureBuilderTemplate(
          future: () async {
            if (classesDocs.isEmpty) {
              classesDocs = (await firestore.collection('classes').get()).docs;
              selections.addAll({for (final cl in classesDocs) cl.id: false});
            }
            return classesDocs;
          }(),
          builder: (context, snapshot) => Column(
            children: [
              Text('Student Onboarding Form'),
              const SizedBox(height: 60),
              TextField(controller: nameController),
              const SizedBox(height: 15),
              TextField(controller: hpController),
              const SizedBox(height: 15),
              TextField(controller: parentsNameController),
              const SizedBox(height: 15),
              TextField(controller: parentsHpController),
              const SizedBox(height: 15),
              TextField(controller: teachersNameController),
              const SizedBox(height: 15),
              Text('Select your class(es):'),
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
                      Text(ClassData.fromJson(cl.data()).name),
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
    );
  }
}
