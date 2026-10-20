import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/studio_repository.dart';
import '../shared/studio_widgets.dart';

part 'home_screen.dart';
part 'services_screen.dart';
part 'portfolio_screen.dart';
part 'blog_screen.dart';
part 'contacts_screen.dart';
part 'brief_callout.dart';
part 'brief_screen.dart';

const _locale = ContentLocale.ru;

void openBrief(
  BuildContext context,
  StudioRepository repository, {
  String? serviceTitle,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BriefScreen(
        repository: repository,
        initialServiceTitle: serviceTitle,
      ),
    ),
  );
}

void _openProject(
  BuildContext context,
  StudioRepository repository,
  StudioProject project,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProjectScreen(repository: repository, project: project),
    ),
  );
}
