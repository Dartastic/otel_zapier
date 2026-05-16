// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_zapier_suppression.dart';

const _tracerName = 'dartastic_otel_libs_zapier';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Zapier "Catch Hook" POST in a PRODUCER span. [hookId]
/// is the trailing identifier in `hooks.zapier.com/hooks/catch/<...>/...`.
Future<T> tracedZapierCatchHook<T>({
  required String hookId,
  required Future<T> Function() invoke,
  int? payloadSize,
  String? zapName,
}) async {
  if (zapierInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'messaging.system': 'zapier_hook',
    'messaging.operation': 'publish',
    'messaging.destination.name': hookId,
    'zapier.hook.id': hookId,
  };
  if (payloadSize != null) m['messaging.message.body.size'] = payloadSize;
  if (zapName != null) m['zapier.zap.name'] = zapName;

  final span = _tracer().startSpan(
    'zapier catch-hook $hookId',
    kind: SpanKind.producer,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a Zapier NLA (Natural Language Actions) call in a CLIENT
/// span.
Future<T> tracedZapierNlaAction<T>({
  required String action,
  required Future<T> Function() invoke,
  String? instructions,
}) async {
  if (zapierInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'zapier.api': 'nla',
    'zapier.action': action,
  };
  if (instructions != null) {
    final clipped = instructions.length > 512
        ? instructions.substring(0, 512)
        : instructions;
    m['zapier.instructions'] = clipped;
  }

  final span = _tracer().startSpan(
    'zapier nla $action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
