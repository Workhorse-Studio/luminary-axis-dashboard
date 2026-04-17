part of axis_dashboard;

class FutureBuilderTemplate<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext, AsyncSnapshot<T>) builder;
  final String Function(Object?)? errorMsg;

  FutureBuilderTemplate({
    required this.future,
    required this.builder,
    this.errorMsg,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (ctx, snapshot) {
        if (snapshot.hasData) {
          return builder(ctx, snapshot);
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          print(errorMsg?.call(snapshot.error) ?? 'An error occurred.');
          print(snapshot.error);
          print(snapshot.stackTrace);
          return Text(errorMsg?.call(snapshot.error) ?? 'An error occurred.');
        }
      },
    );
  }
}
