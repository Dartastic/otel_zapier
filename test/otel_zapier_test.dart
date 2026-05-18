// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_zapier/otel_zapier.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_zapier-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('catch-hook records PRODUCER span', () async {
    await tracedZapierCatchHook<String>(
      hookId: 'abc-123',
      payloadSize: 100,
      zapName: 'Order to Slack',
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('zapier catch-hook abc-123');
    expect(span!.kind, SpanKind.producer);
    final a = attrsOf(span);
    expect(a['messaging.system'], 'zapier_hook');
    expect(a['zapier.hook.id'], 'abc-123');
    expect(a['zapier.zap.name'], 'Order to Slack');
  });

  test('NLA action records CLIENT span', () async {
    await tracedZapierNlaAction<String>(
      action: 'gmail_send_email',
      instructions: 'Send to ada@example.com about lunch',
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('zapier nla gmail_send_email')!);
    expect(a['zapier.api'], 'nla');
    expect(a['zapier.action'], 'gmail_send_email');
    expect(a['zapier.instructions'], 'Send to ada@example.com about lunch');
  });

  test('suppression skips spans', () async {
    await runWithoutZapierInstrumentationAsync(() async {
      await tracedZapierCatchHook<String>(
        hookId: 'h',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('zapier '), isEmpty);
  });
}
