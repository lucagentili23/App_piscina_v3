import 'package:flutter/material.dart';

class BookingModalBottomSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _BottomSheetContent(),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  const _BottomSheetContent();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
