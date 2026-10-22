import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerDesignSystemLicenses() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/licenses/GowunDodum-OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['Gowun Dodum'], license);
  });
}
