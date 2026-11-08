// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_zapier/otel_zapier.dart';

/// Traces Zapier NLA (Natural Language Actions) calls with OpenTelemetry.
///
/// `otel_zapier` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Zapier NLA (Natural Language Actions) call in
/// [tracedZapierCatchHook]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'zapier-example');

  // Wraps a Zapier "Catch Hook" POST in a PRODUCER span.
  final zapierCatchHookId = await tracedZapierCatchHook<String>(
    hookId: 'hook_8f3a2c',
    payloadSize: 512,
    zapName: 'example',
    invoke: () async {
      // Make the Zapier NLA (Natural Language Actions) call here, then report what it returned.
      return 'zapier_8f3a2c';
    },
  );
  OTelLog.info('tracedZapierCatchHook returned $zapierCatchHookId');

  // Wraps a Zapier NLA (Natural Language Actions) call in a CLIENT span.
  final zapierNlaActionId = await tracedZapierNlaAction<String>(
    action: 'example',
    instructions: 'example',
    invoke: () async {
      // Make the Zapier NLA (Natural Language Actions) call here, then report what it returned.
      return 'zapier_8f3a2c';
    },
  );
  OTelLog.info('tracedZapierNlaAction returned $zapierNlaActionId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutZapierInstrumentationAsync.
  await runWithoutZapierInstrumentationAsync(
    () => tracedZapierCatchHook<String>(
      hookId: 'hook_8f3a2c',
      payloadSize: 512,
      zapName: 'example',
      invoke: () async {
        return 'zapier_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
