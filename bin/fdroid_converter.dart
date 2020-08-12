import 'dart:convert';
import 'dart:io';

const keyMap = {
  'packageName': 'packageName',
  'name': 'name',
  'summary': 'summary',
  'description': 'description',
  'license': 'license',
  'webSite': 'webSite',
  'sourceCode': 'sourceCode',
  'issueTracker': 'issueTracker',
  'suggestedVersionName': 'currentVersionName',
  'suggestedVersionCode': 'currentVersionCode',
  'authorName': 'authorName',
  'authorEmail': 'authorEmail',
  'antiFeatures': 'antiFeatures',
  'donate': 'donate',
  'bitcoin': 'bitcoin',
  'litecoin': 'litecoin',
  'liberapay': 'liberapay',
  'flattr': 'flattr',
  'openCollective': 'openCollective',
  'requirements': 'requirements',
  'categories': 'categories',
  'changelog': 'changelog',
  'added': 'added',
  'lastUpdated': 'lastUpdated',
  'translation': 'translation',
  'localized': 'localized',
};

main(List<String> args) {
  final str = File('data/fdroid/index-v1.json').readAsStringSync();


  final data = json.decode(
      str 
      );


  for (var app in data['apps']) {
    print(app['packageName']);

    if (['org.fdroid.fdroid.privileged.ota'].contains(app['packageName']))
      continue;

    Map<String, dynamic> newData = {};
    for (var key in app.keys) {
      if (['suggestedVersionCode' ].contains(key)) {
        final otherKey = keyMap[key];
        newData[otherKey] = int.parse(app[key]);
      } else {
        final otherKey = keyMap[key];

        if (otherKey != null && app[key] != null) {
          newData[otherKey] = app[key];
        }
      }
    }

    if (newData['localized'] != null) {
      for (var localKey in newData['localized'].keys) {
        if (newData['localized'][localKey].containsKey('phoneScreenshots')) {
          newData['localized'][localKey]['phoneScreenshotsBaseUrl'] =
              'https://f-droid.org/repo/${newData["packageName"]}/${localKey}/phoneScreenshots/';
        }
      }
    }


    if (app['icon'] != null && !app['icon'].endsWith('.xml'))
      newData['icon'] = 'https://f-droid.org/repo/icons-640/' + app['icon'];

    newData['builds'] = [];

    var packages = data['packages'][app['packageName']];

    for (var release in packages) {
      var build = {};

      build['versionName'] = release['versionName'];
      build['versionCode'] = release['versionCode'];

      if (release['hashType'] != 'sha256')
        throw Exception('Only sha256 is supported');

      build['sha256'] = release['hash'];
      build['apkLink'] = 'https://f-droid.org/repo/' + release['apkName'];

      build['size'] = release['size'];

      build['minSdkVersion'] = release['minSdkVersion'];

      build['targetSdkVersion'] = release['targetSdkVersion'];

      build['added'] = release['added'];

      if ((release['uses-permission'] ?? '').isNotEmpty) {
        build['permissions'] =
            release['uses-permission'].map((m) => m[0]).toList();
      }

      newData['builds'].add(build);
    }

    if (!newData.containsKey('currentVersionCode')) {
      throw Exception('No currentVersionCode');
    }

    final currentBuild = newData['builds'].firstWhere(
        (b) => b['versionCode'] == newData['currentVersionCode'],
        orElse: () => null);

    if (currentBuild == null) {
      List<int> codes =
          newData['builds'].map<int>((b) => b['versionCode'] as int).toList();

      codes.sort();

      newData['currentVersionName'] = null;
      newData['currentVersionCode'] = codes.last;
    }

    // currentVersionCode

    if (newData['currentVersionName'] == null) {
      newData['currentVersionName'] = newData['builds'].firstWhere((b) =>
          b['versionCode'] == newData['currentVersionCode'])['versionName'];
    }

    final file = File('data/out/${newData['packageName']}.yaml');
    file.createSync(recursive: true);
    file.writeAsStringSync(json.encode(newData));
  }

  return;
}
