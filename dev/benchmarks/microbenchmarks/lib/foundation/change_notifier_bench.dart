// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../common.dart';

const int _kNumIterations = 65536;
const int _kNumWarmUp = 100;
const int _kScale = 1000;

void main() {
  assert(false, "Don't run benchmarks in checked mode! Use 'flutter run --release'.");

  // In the following benchmarks, we won't remove the listeners when we don't
  // want to measure removeListener because we know that everything will be
  // GC'ed in the end.
  // Not removing listeners would cause memory leaks in a real application.

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();

  void runAddListenerBenchmark(int iteration, {bool addResult = true}) {
    const String name = 'addListener';
    for (int listenerCount = 1; listenerCount <= 5; listenerCount += 1) {
      final List<_Notifier> notifiers = List<_Notifier>.generate(
        iteration,
        (_) => _Notifier(),
        growable: false,
      );

      final Stopwatch watch = Stopwatch();
      watch.start();
      for (int i = 0; i < iteration; i += 1) {
        for (int l = 0; l < listenerCount; l += 1) {
          notifiers[i].addListener(() {});
        }
      }
      watch.stop();
      final int elapsed = watch.elapsedMicroseconds;
      final double averagePerIteration = elapsed / iteration;
      if (addResult)
        printer.addResult(
          description: '$name ($listenerCount listeners)',
          value: averagePerIteration * _kScale,
          unit: 'ns per iteration',
          name: '$name${listenerCount}_iteration',
        );
    }
  }

  void runNotifyListenerBenchmark(int iteration, {bool addResult = true}) {
    const String name = 'notifyListener';

    for (int listenerCount = 0; listenerCount <= 5; listenerCount += 1) {
      final _Notifier notifier = _Notifier();
      for (int i = 1; i <= listenerCount; i += 1) {
        notifier.addListener(() {});
      }
      final Stopwatch watch = Stopwatch();
      watch.start();
      for (int i = 0; i < iteration; i += 1) {
        notifier.notify();
      }
      watch.stop();
      final int elapsed = watch.elapsedMicroseconds;
      final double averagePerIteration = elapsed / iteration;
      if (addResult)
        printer.addResult(
          description: '$name ($listenerCount listeners)',
          value: averagePerIteration * _kScale,
          unit: 'ns per iteration',
          name: '$name${listenerCount}_iteration',
        );
    }
  }

  void runRemoveListenerBenchmark(int iteration, {bool addResult = true}) {
    const String name = 'removeListener';
    final List<VoidCallback> listeners = <VoidCallback>[
      () {},
      () {},
      () {},
      () {},
      () {},
    ];
    for (int listenerCount = 1; listenerCount <= 5; listenerCount += 1) {
      final List<_Notifier> notifiers = List<_Notifier>.generate(
        iteration,
        (_) {
          final _Notifier notifier = _Notifier();
          for (int l = 0; l < listenerCount; l += 1) {
            notifier.addListener(listeners[l]);
          }
          return notifier;
        },
        growable: false,
      );

      final Stopwatch watch = Stopwatch();
      watch.start();
      for (int i = 0; i < iteration; i += 1) {
        for (int l = 0; l < listenerCount; l += 1) {
          notifiers[i].removeListener(listeners[l]);
        }
      }
      watch.stop();
      final int elapsed = watch.elapsedMicroseconds;
      final double averagePerIteration = elapsed / iteration;
      if (addResult)
        printer.addResult(
          description: '$name ($listenerCount listeners)',
          value: averagePerIteration * _kScale,
          unit: 'ns per iteration',
          name: '$name${listenerCount}_iteration',
        );
    }
  }

  void runRemoveListenerWhileNotifyingBenchmark(int iteration, {bool addResult = true}) {
    const String name = 'removeListenerWhileNotifying';

    final List<VoidCallback> listeners = <VoidCallback>[
      () {},
      () {},
      () {},
      () {},
      () {},
    ];
    for (int listenerCount = 1; listenerCount <= 5; listenerCount += 1) {
      final List<_Notifier> notifiers = List<_Notifier>.generate(
        iteration,
        (_) {
          final _Notifier notifier = _Notifier();
          notifier.addListener(() {
            // This listener will remove all other listeners. So that only this
            // one is called and measured.
            for (int l = 0; l < listenerCount; l += 1) {
              notifier.removeListener(listeners[l]);
            }
          });
          for (int l = 0; l < listenerCount; l += 1) {
            notifier.addListener(listeners[l]);
          }
          return notifier;
        },
        growable: false,
      );

      final Stopwatch watch = Stopwatch();
      watch.start();
      for (int i = 0; i < iteration; i += 1) {
        notifiers[i].notify();
      }
      watch.stop();
      final int elapsed = watch.elapsedMicroseconds;
      final double averagePerIteration = elapsed / iteration;
      if (addResult)
        printer.addResult(
          description: '$name ($listenerCount listeners)',
          value: averagePerIteration * _kScale,
          unit: 'ns per iteration',
          name: '$name${listenerCount}_iteration',
        );
    }
  }

  runAddListenerBenchmark(_kNumWarmUp, addResult: false);
  runAddListenerBenchmark(_kNumIterations, addResult: true);

  runNotifyListenerBenchmark(_kNumWarmUp, addResult: false);
  runNotifyListenerBenchmark(_kNumIterations, addResult: true);

  runRemoveListenerBenchmark(_kNumWarmUp, addResult: false);
  runRemoveListenerBenchmark(_kNumIterations, addResult: true);

  runRemoveListenerWhileNotifyingBenchmark(_kNumWarmUp, addResult: false);
  runRemoveListenerWhileNotifyingBenchmark(_kNumIterations, addResult: true);

  printer.printToStdout();
}

class _Notifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
