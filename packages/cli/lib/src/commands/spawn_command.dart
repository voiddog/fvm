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
    final project = await FlutterProjectRepo.findAncestor();

    final version = argResults.arguments[0];

    if (project != null && project.pinnedVersion != null || version != null) {
      await installWorkflow(version);
      FvmLogger.info('FVM: Running version ${project.pinnedVersion}');
      final spawnId = Uuid().v4();
      final refVersionPath = join(kVersionsDir.path, version);
      final spawnVersionDir = Directory(join(kSpawnDir.path, spawnId));
      try {
        final progress = logger.progress('Preparing...');
        await copyPath(refVersionPath, spawnVersionDir.path);
        progress.finish(showTiming: true);
        // Remove version for the args
        argResults.arguments.remove(version);
        await runFlutterCmd(spawnId, argResults.arguments, spawn: true);
      } on Exception catch (err) {
        logger.trace(err.toString());
        throw const InternalError('Spawn Flutter process failed');
      } finally {
        if (await spawnVersionDir.exists()) {
          await spawnVersionDir.delete(recursive: true);
        }
      }
    } else {
      throw Exception('To run Spawn pin the version in the project');
    }
  }
}
