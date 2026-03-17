part of axis_dashboard;

class ConfirmationDialog extends StatefulWidget {
  final String confirmationMsg;
  const ConfirmationDialog({
    required this.confirmationMsg,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => ConfirmationDialogState();
}

class ConfirmationDialogState extends State<ConfirmationDialog> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 340,
        height: 240,
        foregroundDecoration: dialogForegroundDecoration,
        decoration: BoxDecoration(
          color: AxisColors.blackPurple50,
        ),

        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  widget.confirmationMsg,
                  style: body2,
                ),
                const SizedBox(height: 50),
                Row(
                  children: [
                    AxisNMButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      label: 'Cancel',
                    ),
                    const Spacer(),
                    AxisNMButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      label: 'Continue',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
