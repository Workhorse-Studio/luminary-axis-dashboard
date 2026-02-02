part of axis_dashboard;

class AxisDropdownButton<T> extends StatefulWidget {
  final double width;
  final T? initialSelection;
  final String? initalLabel;
  final List<(String, T)> entries;
  final void Function(T? newData)? onSelected;

  const AxisDropdownButton({
    required this.width,
    required this.entries,
    required this.onSelected,
    this.initialSelection,
    this.initalLabel,

    super.key,
  });

  @override
  State<AxisDropdownButton<T>> createState() => AxisDropdownButtonState<T>();
}

class AxisDropdownButtonState<T> extends State<AxisDropdownButton<T>> {
  bool isOpen = false;
  final MenuController menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      style: NeumorphicStyle(
        boxShape: NeumorphicBoxShape.stadium(),
        border: NeumorphicBorder(color: AxisColors.blackPurple20),
        color: AxisColors.blackPurple30.withValues(alpha: 0.3),
        shadowLightColor: AxisColors.blackPurple20.withValues(alpha: 0.7),
      ),
      padding: const EdgeInsets.all(0),
      onPressed: () {
        isOpen ? menuController.close() : menuController.open();
        isOpen = !isOpen;
      },
      child: IgnorePointer(
        ignoring: true,
        child: DropdownMenu<T>(
          width: widget.width,
          menuController: menuController,
          inputDecorationTheme: InputDecorationTheme(
            border: InputBorder.none,
            contentPadding: EdgeInsets.only(left: 20),
          ),
          menuStyle: MenuStyle(
            side: WidgetStatePropertyAll(
              BorderSide(color: AxisColors.blackPurple20),
            ),
            backgroundColor: WidgetStatePropertyAll(
              AxisColors.blackPurple30,
            ),
          ),
          textStyle: buttonLabel,
          initialSelection: widget.initialSelection,
          dropdownMenuEntries: [
            if (widget.initalLabel != null && widget.initialSelection != null)
              DropdownMenuEntry(
                value: widget.initialSelection!,
                style: menuEntryStyle,
                label: widget.initalLabel!,
              ),
            ...[
              for (final e in widget.entries)
                DropdownMenuEntry(
                  value: e.$2,
                  label: e.$1,
                  style: menuEntryStyle,
                ),
            ],
          ],
          onSelected: widget.onSelected,
        ),
      ),
    );
  }
}
