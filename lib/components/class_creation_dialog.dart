part of axis_dashboard;

class ClassCreationDialog extends StatelessWidget {
  ClassCreationDialog({super.key});

  String className = '';
  String teacherId = '';
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 500,
        height: MediaQuery.of(context).size.height * 0.6,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Name',
                    style: heading3,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (value) => className = value,
                    style: body2,
                  ),
                  const SizedBox(height: 30),

                  const SizedBox(height: 30),
                  const SizedBox(height: 50),
                  AxisButton.text(
                    label: 'Save',
                    onPressed: () {
                      if (className != '') {
                        Navigator.of(context).pop(
                          ClassTemplate(
                            className: className,
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
    );
  }
}
