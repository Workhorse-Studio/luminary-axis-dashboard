part of digistore;

class SyllabusPage extends StatefulWidget {
  const SyllabusPage({super.key});

  @override
  State<StatefulWidget> createState() => SyllabusPageState();
}

class SyllabusPageState extends State<SyllabusPage> {
  Iterable<Map> snapshots = [];
  bool hasLoaded = false;
  bool isAdmin = false;

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Syllabus',
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              hasLoaded = false;
            });
          },
          child: Wrap(
            children: [
              Icon(Icons.refresh),
              const SizedBox(width: 10),
              Text('Refresh'),
            ],
          ),
        ),
        TextButton(
          onPressed: () async {
            final Map<String, dynamic>? res = await showDialog(
              context: context,
              builder: (_) => AddStoreEntryDialog(),
            );

            String msg;

            if (res != null) {
              try {
                await firestore.collection('store').add(res);
                msg = 'Entry created successfully';
              } catch (e, st) {
                print(e);
                print(st);
                msg = 'Something went wrong. See logs for details';
              }
            } else {
              msg = 'Entry discarded';
            }

            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(msg)));
              setState(() {
                hasLoaded = false;
              });
            }
          },
          child: Text('Add Entry'),
        ),
      ],
      body: (ctx) => Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsetsGeometry.all(20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }
}

class AddStoreEntryDialog extends StatelessWidget {
  final TextEditingController idController = TextEditingController(),
      nameController = TextEditingController(),
      typeController = TextEditingController(),
      categoryController = TextEditingController(),
      qtyController = TextEditingController(),
      statusController = TextEditingController(),
      descController = TextEditingController(),
      remarksController = TextEditingController();

  AddStoreEntryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final double padSides = MediaQuery.of(context).size.width * 0.1;
    return Dialog.fullscreen(
      child: Form(
        child: Padding(
          padding: EdgeInsetsGeometry.only(left: padSides, right: padSides),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                TextField(
                  controller: idController,
                  decoration: InputDecoration(label: Text('ID')),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(label: Text('Item Name')),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: typeController,
                  decoration: InputDecoration(label: Text('Item Type')),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(label: Text('Category')),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(label: Text('Quantity')),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: statusController,
                  decoration: InputDecoration(label: Text('Status')),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(label: Text('Description')),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: remarksController,
                  decoration: InputDecoration(label: Text('Remarks')),
                ),

                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text('Cancel'),
                    ),
                    const SizedBox(width: 30),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop({
                        'id': idController.text,
                        'name': nameController.text,
                        'category': categoryController.text,
                        'itemtype': typeController.text,
                        'quantity': int.parse(qtyController.text),
                        'description': descController.text,
                        'remarks': remarksController.text,
                        'status': statusController.text,
                      }),
                      child: Text('Submit'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
