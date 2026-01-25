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
    return Dialog(
      child: Container(
        width: 200,
        height: 140,
        child: Column(
          children: [
            Text(widget.confirmationMsg),
            const SizedBox(height: 50),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
