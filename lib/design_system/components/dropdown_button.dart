part of axis_dashboard;

class AxisDropdownButton<T> extends StatefulWidget {
  final double width;
  final T? initialSelection;
  final String? initalLabel;
  final List<(String, T)> entries;
  final void Function(T? newData)? onSelected;
  final Color Function(T data)? customBgColoring;

  const AxisDropdownButton({
    required this.width,
    required this.entries,
    required this.onSelected,
    this.customBgColoring,
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
                style: menuEntryStyle.copyWith(
                  backgroundColor: widget.customBgColoring != null
                      ? WidgetStatePropertyAll(
                          widget.customBgColoring!.call(
                            widget.initialSelection!,
                          ),
                        )
                      : null,
                ),
                label: widget.initalLabel!,
              ),
            ...[
              for (final e in widget.entries)
                DropdownMenuEntry(
                  value: e.$2,
                  label: e.$1,
                  style: menuEntryStyle.copyWith(
                    backgroundColor: widget.customBgColoring != null
                        ? WidgetStatePropertyAll(
                            widget.customBgColoring!.call(
                              e.$2,
                            ),
                          )
                        : null,
                  ),
                ),
            ],
          ],
          onSelected: widget.onSelected,
        ),
      ),
    );
  }
}
