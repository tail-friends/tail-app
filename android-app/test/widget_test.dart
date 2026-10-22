import 'package:flutter_test/flutter_test.dart';
import 'package:tail_friends/main.dart';

void main() {
  testWidgets('초기 화면에 앱 이름과 준비 상태를 표시한다', (tester) async {
    await tester.pumpWidget(const TailFriendsApp());

    expect(find.text('Tail Friends'), findsOneWidget);
    expect(find.text('Android 개발 환경이 준비되었습니다.'), findsOneWidget);
  });
}
