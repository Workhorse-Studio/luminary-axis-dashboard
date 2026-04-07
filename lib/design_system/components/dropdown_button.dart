part of axis_dashboard;

class AxisDropdownButton<T> extends StatefulWidget {
  final double width;
  final T? initialSelection;
  final String? initalLabel;
  final List<(String, T)> entries;
  final void Function(T? newData)? onSelected;
  final Color Function(T data)? customBgColoring;
  final bool seaprateInitialSelectionEntry;

  const AxisDropdownButton({
    required this.width,
    required this.entries,
    required this.onSelected,
    this.customBgColoring,
    this.initialSelection,
    this.initalLabel,
    this.seaprateInitialSelectionEntry = true,
    super.key,
  });

  @override
  State<AxisDropdownButton<T>> createState() => AxisDropdownButtonState<T>();
}

class AxisDropdownButtonState<T> extends State<AxisDropdownButton<T>> {
  final MenuController menuController = MenuController();
  T? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    String currentLabel = widget.initalLabel ?? 'Select...';
    for (final e in widget.entries) {
      if (e.$2 == selectedValue) {
        currentLabel = e.$1;
        break;
      }
    }

    return GestureDetector(
      onTap: () {
        if (menuController.isOpen) {
          menuController.close();
        } else {
          menuController.open();
        }
      },
      child: MenuAnchor(
        controller: menuController,
        menuChildren: [
          if (widget.initalLabel != null && widget.initialSelection != null && widget.seaprateInitialSelectionEntry)
            MenuItemButton(
              onPressed: () {
                setState(() => selectedValue = widget.initialSelection);
                widget.onSelected?.call(widget.initialSelection);
              },
              child: Text(widget.initalLabel!, style: StakentTextStyles.bodyMedium),
            ),
          for (final e in widget.entries)
            MenuItemButton(
              onPressed: () {
                setState(() => selectedValue = e.$2);
                widget.onSelected?.call(e.$2);
              },
              child: Text(e.$1, style: StakentTextStyles.bodyMedium),
            ),
        ],
        builder: (context, controller, child) {
          return Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: StakentColors.surfaceInput,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: StakentColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    currentLabel,
                    style: StakentTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: StakentColors.textSecondary, size: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
