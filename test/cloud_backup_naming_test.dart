import 'package:flutter_test/flutter_test.dart';
import 'package:packplan/services/cloud_backup_service.dart';

void main() {
  test('fileNameFor 產生帶時間戳的備份檔名', () {
    final name = CloudBackupNaming.fileNameFor(
      DateTime(2026, 9, 22, 10, 30, 45),
    );
    expect(name, 'packplan-backup-20260922-103045.json');
  });

  test('fileNameFor 對個位數月日時分秒補零', () {
    final name = CloudBackupNaming.fileNameFor(DateTime(2026, 1, 5, 3, 7, 9));
    expect(name, 'packplan-backup-20260105-030709.json');
  });

  test('isBackupFile 只認 PackPlan 備份檔', () {
    expect(
      CloudBackupNaming.isBackupFile('packplan-backup-20260922-103045.json'),
      isTrue,
    );
    expect(CloudBackupNaming.isBackupFile('note.txt'), isFalse);
    expect(CloudBackupNaming.isBackupFile('packplan-backup-x.csv'), isFalse);
    expect(CloudBackupNaming.isBackupFile('other-backup-1.json'), isFalse);
  });
}
