import 'package:envied/envied.dart';

part 'environment_variables.g.dart';

@envied
abstract class Env {
  @EnviedField(varName: 'GCLOUD_API_KEY', obfuscate: true)
  static const String gcloudApiKey = _Env.gcloudApiKey;
}
