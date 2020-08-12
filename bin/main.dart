import 'dart:io';

import 'package:http/http.dart' as http;

import 'fdroid_converter.dart' as fdroid_converter;
import 'upload_to_skynet.dart' as upload_to_skynet;

final eTagFile = File('data/last_eTag');

void main(List<String> arguments) async {
  print('Checking F-Droid Repo for changes...');

  var res = await http.head('https://f-droid.org/repo/index-v1.jar');

  final eTag = res.headers['etag'];
  if (eTag == null) throw Exception('ETag is null');

  if (eTagFile.existsSync()) {
    final lastETag = eTagFile.readAsStringSync();

    if (lastETag == eTag) {
      print('Same ETag, exiting.');
      return;
    }
  }
  try {
    print('Updating repo...');

    await Process.runSync('sh', ['fetch_fdroid_repo.sh'],);

    print('Running F-Droid converter...');
    await fdroid_converter.main([]);

    print('Uploading new metadata to Skynet and updating DNS Records...');
    await upload_to_skynet.main([]);

    await eTagFile.createSync(recursive: true);
    eTagFile.writeAsStringSync(eTag);
  } catch (e, st) {
    print(e);
    print(st);
  }
}
