import 'package:args/command_runner.dart';
import 'package:cli_dialog/cli_dialog.dart';

import 'package:fvm/constants.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/flutter_helpers.dart';
import 'package:fvm/src/local_versions/local_version.repo.dart';
import 'package:fvm/src/utils/confirm.dart';

import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/utils/pubdev.dart';

import 'package:fvm/src/workflows/install_version.workflow.dart';
import 'package:fvm/src/workflows/use_version.workflow.dart';

/// Use an installed SDK version
class UseCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.
  @override
  final name = 'use';

  @override
  final description = 'Which Flutter SDK Version you would like to use';

  /// Constructor
  UseCommand() {
    argParser
      ..addFlag(
        'global',
        help:
            'Sets version as the global version.\nMake sure Flutter PATH env is set to: $kDefaultFlutterPath',
        negatable: false,
      )
      ..addFlag(
        'force',
        help: 'Skips command guards that does Flutter project checks.',
        negatable: false,
      );
  }
  @override
  Future<void> run() async {
    String version;

    // If no version is provider show selection
    if (argResults.rest.isEmpty) {
      final installedSdks = await LocalVersionRepo.getAll();
      if (installedSdks.isEmpty) {
        throw Exception('Please install a version. fvm install <version>');
      }
      final listQuestions = [
        [
          {
            'question': 'Select version',
            'options': installedSdks.map((e) => e.name).toList(),
          },
          'version'
        ]
      ];
      final dialog = CLI_Dialog(listQuestions: listQuestions);
      final answer = dialog.ask();
      version = answer['version'] as String;
    }

    version ??= argResults.rest[0];

    final global = argResults['global'] == true;
    final force = argResults['force'] == true;

    // Get valid flutter version
    final validVersion = await inferFlutterVersion(version).catchError((error) {
      if (force) {
        return version;
      }
      throw error;
    });
    final isVersionInstalled = await LocalVersionRepo.isInstalled(validVersion);

    if (!isVersionInstalled) {
      // Make sure version is installed
      FvmLogger.info('Flutter $validVersion is not installed.');
      // Install if input is confirmed
      if (await confirm('Would you like to install it?')) {
        await installWorkflow(validVersion);
      }
    }
    await useVersionWorkflow(validVersion, global: global, force: force);

    await checkIfLatestVersion();
  }
}
