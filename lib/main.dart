import 'package:flutter/material.dart';

import 'app/pip_app.dart';
import 'core/api/api_client.dart';
import 'core/api/api_config.dart';
import 'data/api_studio_repository.dart';
import 'data/studio_repository.dart';

void main() => runApp(const PipBootstrap());

/// Composition root: selects the data source and owns its network connection.
class PipBootstrap extends StatefulWidget {
  const PipBootstrap({
    super.key,
    this.useDemoData = const bool.fromEnvironment('USE_DEMO_DATA'),
  });

  final bool useDemoData;

  @override
  State<PipBootstrap> createState() => _PipBootstrapState();
}

class _PipBootstrapState extends State<PipBootstrap> {
  ApiClient? _client;
  late final StudioRepository _repository;

  @override
  void initState() {
    super.initState();
    if (widget.useDemoData) {
      _repository = const DemoStudioRepository();
    } else {
      final client = ApiClient(config: ApiConfig.fromEnvironment());
      _client = client;
      _repository = ApiStudioRepository(client);
    }
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PipApp(repository: _repository);
}
