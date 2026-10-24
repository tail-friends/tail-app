import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerDesignSystemLicenses() {
  LicenseRegistry.addLicense(() async* {
    const licenses = {
      'Gowun Dodum': 'assets/licenses/GowunDodum-OFL.txt',
      'Jua': 'assets/licenses/Jua-OFL.txt',
    };

    for (final entry in licenses.entries) {
      final license = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], license);
    }
  });
}
