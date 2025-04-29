"""Dart SDK extension for Bzlmod."""

load("//dart/build_rules:repositories.bzl", "dart_repositories")

def _dart_impl(ctx):
    dart_repositories()

dart = module_extension(
    implementation = _dart_impl,
) 