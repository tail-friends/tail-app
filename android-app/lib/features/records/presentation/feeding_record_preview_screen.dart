import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../auth/presentation/login_screen.dart';
import '../../home/presentation/home_screen.dart';
import 'feeding_record_sheet.dart';

/// Independent Debug route. No authentication, record storage or home rewrite.
class FeedingRecordPreviewScreen extends StatefulWidget {
  const FeedingRecordPreviewScreen({super.key});

  @override
  State<FeedingRecordPreviewScreen> createState() =>
      _FeedingRecordPreviewScreenState();
}

class _FeedingRecordPreviewScreenState
    extends State<FeedingRecordPreviewScreen> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showFeedingRecordSheet(context, designPreview: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      kDebugMode ? const HomeScreen.preview() : const LoginScreen();
}
