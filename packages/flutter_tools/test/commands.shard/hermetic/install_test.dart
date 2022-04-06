// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/application_package.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/install.dart';
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('install', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    FileSystem fileSystem;
    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fileSystem.file('pubspec.yaml').createSync(recursive: true);
    });

    testUsingContext('returns 0 when Android is connected and ready for an install', () async {
      final InstallCommand command = InstallCommand();
      command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

      final FakeAndroidDevice device = FakeAndroidDevice();
      testDeviceManager.addDevice(device);

      await createTestCommandRunner(command).run(<String>['install']);
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 1 when targeted device is not Android with --device-user', () async {
      final InstallCommand command = InstallCommand();
      command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

      final FakeIOSDevice device = FakeIOSDevice();
      testDeviceManager.addDevice(device);

      expect(() async => createTestCommandRunner(command).run(<String>['install', '--device-user', '10']),
        throwsToolExit(message: '--device-user is only supported for Android'));
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 0 when iOS is connected and ready for an install', () async {
      final InstallCommand command = InstallCommand();
      command.applicationPackages = FakeApplicationPackageFactory(FakeIOSApp());

      final FakeIOSDevice device = FakeIOSDevice();
      testDeviceManager.addDevice(device);

      await createTestCommandRunner(command).run(<String>['install']);
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('fails when prebuilt binary not found', () async {
      final InstallCommand command = InstallCommand();
      command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

      final FakeAndroidDevice device = FakeAndroidDevice();
      testDeviceManager.addDevice(device);

      expect(() async => createTestCommandRunner(command).run(<String>['install', '--use-application-binary', 'bogus']),
          throwsToolExit(message: 'Prebuilt binary bogus does not exist'));
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('succeeds using prebuilt binary', () async {
      final InstallCommand command = InstallCommand();
      command.applicationPackages = FakeApplicationPackageFactory(FakeAndroidApk());

      final FakeAndroidDevice device = FakeAndroidDevice();
      testDeviceManager.addDevice(device);
      fileSystem.file('binary').createSync(recursive: true);

      await createTestCommandRunner(command).run(<String>['install', '--use-application-binary', 'binary']);
    }, overrides: <Type, Generator>{
      Cache: () => Cache.test(processManager: FakeProcessManager.any()),
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class FakeApplicationPackageFactory extends Fake implements ApplicationPackageFactory {
  FakeApplicationPackageFactory(this.app);

  final ApplicationPackage app;

  @override
  Future<ApplicationPackage> getPackageForPlatform(TargetPlatform platform, {BuildInfo buildInfo, File applicationBinary}) async {
    return app;
  }
}
class FakeIOSApp extends Fake implements IOSApp { }
class FakeAndroidApk extends Fake implements AndroidApk { }

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class FakeIOSDevice extends Fake implements IOSDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  Future<bool> isAppInstalled(
    IOSApp app, {
    String userIdentifier,
  }) async => false;

  @override
  Future<bool> installApp(
    IOSApp app, {
    String userIdentifier,
  }) async => true;
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class FakeAndroidDevice extends Fake implements AndroidDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.android_arm;

  @override
  Future<bool> isAppInstalled(
    AndroidApk app, {
    String userIdentifier,
  }) async => false;

  @override
  Future<bool> installApp(
    AndroidApk app, {
    String userIdentifier,
  }) async => true;
}
