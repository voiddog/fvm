import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'package:fvm/constants.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/flutter_tools.dart';
import 'package:fvm/src/utils/logger.dart';
import 'package:fvm/src/workflows/install_version.workflow.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

/// Spawn Flutter Instances Commands
class SpawnCommand extends Command {
  // The [name] and [description] properties must be defined by every
  // subclass.

  @override
  final name = 'spawn';
  @override
  final description = 'Spawns Flutter instances';
  @override
  final argParser = ArgParser.allowAnything();

  /// Constructor
  SpawnCommand();

  @override
  Future<void> run() async {
    final version = argResults.arguments[0];

    if (version != null) {
      if (!await LocalVersionRepo.isInstalled(version)) {
        await installWorkflow(version);
      }
      FvmLogger.info('FVM: Running version $version');

      try {
        // Remove version for the args
        final args = argResults.arguments.toList()..remove(version);
        await runFlutterCmd(version, args);
      } on Exception catch (err) {
        logger.trace(err.toString());
        throw const InternalError('Spawn Flutter process failed');
      }
    } else {
      throw Exception('No version was provided');
    }
  }
}
