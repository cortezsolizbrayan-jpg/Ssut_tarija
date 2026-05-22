// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncLoginNotifier)
final asyncLoginProvider = AsyncLoginNotifierFamily._();

final class AsyncLoginNotifierProvider
    extends $AsyncNotifierProvider<AsyncLoginNotifier, Login> {
  AsyncLoginNotifierProvider._({
    required AsyncLoginNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'asyncLoginProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$asyncLoginNotifierHash();

  @override
  String toString() {
    return r'asyncLoginProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AsyncLoginNotifier create() => AsyncLoginNotifier();

  @override
  bool operator ==(Object other) {
    return other is AsyncLoginNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$asyncLoginNotifierHash() =>
    r'a924eeea41c8cc161a8d0beadcab949713e9bf3f';

final class AsyncLoginNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AsyncLoginNotifier,
          AsyncValue<Login>,
          Login,
          FutureOr<Login>,
          (String, String)
        > {
  AsyncLoginNotifierFamily._()
    : super(
        retry: null,
        name: r'asyncLoginProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AsyncLoginNotifierProvider call(String nombreUsuario, String claveUsuario) =>
      AsyncLoginNotifierProvider._(
        argument: (nombreUsuario, claveUsuario),
        from: this,
      );

  @override
  String toString() => r'asyncLoginProvider';
}

abstract class _$AsyncLoginNotifier extends $AsyncNotifier<Login> {
  late final _$args = ref.$arg as (String, String);
  String get nombreUsuario => _$args.$1;
  String get claveUsuario => _$args.$2;

  FutureOr<Login> build(String nombreUsuario, String claveUsuario);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Login>, Login>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Login>, Login>,
              AsyncValue<Login>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

