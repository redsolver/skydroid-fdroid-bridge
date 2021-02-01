import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:crypto/crypto.dart';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:path/path.dart';
import 'package:skynet/skynet.dart';

main(List<String> args) async {
  dotenv.load();

  final bridgeDomain = dotenv.env['BRIDGE_DOMAIN'];

  final auth = base64.encode(
      '${dotenv.env["NAMEBASE_API_KEY"]}:${dotenv.env["NAMEBASE_API_SECRET"]}'
          .codeUnits);
  final authHeader = 'Basic $auth';

  var res2 = await http.get(
    'https://www.namebase.io/api/v0/dns/domains/$bridgeDomain/nameserver',
    headers: {'Authorization': authHeader},
  );

  List existingRecords = json.decode(res2.body)['records'];
  /* return; */

  List<Map> records = [];

  void setRecords() async {
    print(records);

    var res = await http.put(
      'https://www.namebase.io/api/v0/dns/domains/$bridgeDomain/nameserver',
      headers: {
        'Authorization': authHeader,
        'content-type': 'application/json'
      },
      body: json.encode(
        {
          'records': records,
          'deleteRecords': [],
        },
      ),
    );
    print(res.statusCode);
    print(res.body);
  }

  var collection = StringBuffer('''title: F-Droid Collection
description: Contains the latest apps bridged from F-Droid.
icon: https://f-droid.org/repo/icons-640/org.fdroid.fdroid.1010000.png

apps:
''');

  File('data/existing-records.json')
      .writeAsStringSync(json.encode(existingRecords));

  int i = 0;

  for (File file in Directory('data/out').listSync()) {
    final Map data = json.decode(file.readAsStringSync());

    final bool updatedRecently =
        data['lastUpdated'] > 1603050400000; //1565550400000;

    if (data['lastUpdated'] > 0 /* 1350550400000 */) {
      i++;
      final hash = sha256.convert(file.readAsBytesSync()).toString();

      String packageName = data['packageName'].toLowerCase();

      var exis = existingRecords.firstWhere((e) => e['host'] == packageName,
          orElse: () => null);


      if (exis != null && exis['value'].split('+')[2] == hash) {
        print('skipping ${packageName}');
        if (updatedRecently)
          collection.write('''  - name: ${packageName}.$bridgeDomain
    verifiedMetadataHashes:
      [$hash]
''');
        continue;
      }

      if (exis != null && exis['value'].split('+').length > 2) {
        if (updatedRecently)
          collection.write('''  - name: ${packageName}.$bridgeDomain
    verifiedMetadataHashes:
      [$hash,${exis['value'].split('+')[2]}]
''');
      } else {
        if (updatedRecently)
          collection.write('''  - name: ${packageName}.$bridgeDomain
    verifiedMetadataHashes:
      [$hash]
''');
      }

      print('doing ${packageName}');

      /*   var res = await Process.run('curl', [
        '-X',
        'POST',
        'https://siasky.net/skynet/skyfile',
        '-F',
        'file=@${file.path}'
      ]);
 */

      int skyTry = 0;

      String skylink;
      while (skylink == null) {
        skyTry++;
        print('try #$skyTry');
        try {
          skylink = await uploadFile(SkyFile(
            content: file.readAsBytesSync(),
            filename: basename(file.path),
            type: 'application/x-yaml',
          ));
        } catch (e, st) {
          print(e);
          print(st);
        }
      }

      //print(res.stdout);

      if (skylink != null) {
        records.add({
          'type': 'TXT',
          'host': packageName,
          'value': 'skydroid-app=1+$skylink+$hash',
          'ttl': 3600,
        });
      }

      if (records.length > 100) {
        await setRecords();
        records = [];
      }

      await Future.delayed(Duration(seconds: 1));
    }
  }

  final collFile = File('data/collection.yaml');
  collFile.createSync(recursive: true);
  collFile.writeAsStringSync(collection.toString());

  final hash = sha256.convert(collFile.readAsBytesSync()).toString();

  var res3 = await Process.run('curl', [
    '-X',
    'POST',
    'https://siasky.net/skynet/skyfile',
    '-F',
    'file=@${collFile.path}'
  ]);

  final skylink = json.decode(res3.stdout)['skylink'];

  records.add({
    'type': 'TXT',
    'host': '@',
    'value': 'skydroid-collection=1+$skylink+$hash',
    'ttl': 3600,
  });

  final dnsRecordsBackupFile = File('data/dns-records.json');

  dnsRecordsBackupFile.createSync(recursive: true);
  dnsRecordsBackupFile.writeAsStringSync(json.encode(records));

/*   return; */

  await setRecords();

  print('Total count: $i');
}
