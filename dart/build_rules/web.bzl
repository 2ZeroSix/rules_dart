# Copyright 2016 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Dart rules targeting web clients."""


load(":internal.bzl", "collect_files", "layout_action", "make_dart_context", "package_spec_action")


def dart_compile_js_action(ctx, dart_ctx, script_file,
                   enable_asserts, csp, dump_info, minify, preserve_uris,
                   js_output, part_outputs, other_outputs):
  """dart compile js compile action."""
  # Create a build directory.
  build_dir = ctx.label.name + ".build/"

  # Emit package spec.
  package_spec_path = ctx.label.package + "/" + ctx.label.name + ".package_config.json"
  package_spec = ctx.actions.declare_file(build_dir + package_spec_path)
  package_spec_action(
      ctx=ctx,
      dart_ctx=dart_ctx,
      output=package_spec,
  )

  # Build a flattened directory of dart compile js inputs, including inputs from the
  # src tree, genfiles, and bin.
  all_srcs, _ = collect_files(dart_ctx)
  build_dir_files = layout_action(
      ctx=ctx,
      srcs=all_srcs,
      output_dir=build_dir,
  )
  out_script = build_dir_files[script_file.short_path]

  # Compute action inputs.
  inputs = (
      build_dir_files.values() + [package_spec]
  )
  tools = (
      ctx.files._dart_compile_js +
      ctx.files._dart_compile_js_support
  )

  # Compute dart compile js args.
  dart_compile_js_args = [
      "--packages=%s" % package_spec.path,
      "-o", js_output.path,
  ]
  if enable_asserts:
    dart_compile_js_args += ["--enable-asserts"]
  if csp:
    dart_compile_js_args += ["--csp"]
  if minify:
    dart_compile_js_args += ["-O2"]  # Use -O2 for production builds
  else:
    dart_compile_js_args += ["-O0"]  # Use -O0 for debug builds
  dart_compile_js_args += [out_script.path]
  ctx.actions.run(
      inputs=inputs,
      tools=tools,
      executable=ctx.executable._dart_compile_js_helper,
      arguments=[
          str(ctx.label),
          str(ctx.attr.deferred_lib_count),
          ctx.outputs.js.path,
          ctx.executable._dart_compile_js.path,
      ] + dart_compile_js_args,
      outputs=[js_output] + part_outputs + other_outputs,
      progress_message="Compiling with dart compile js %s" % ctx,
      mnemonic="DartCompileJs",
  )


def _dart_web_application_impl(ctx):
  """Implements the dart_web_application build rule."""
  dart_ctx = make_dart_context(ctx.label,
                               srcs=ctx.files.srcs,
                               data=ctx.files.data,
                               deps=ctx.attr.deps)

  # Compute outputs.
  js_output = ctx.outputs.js
  other_outputs = [
      ctx.outputs.deps_file,
      ctx.outputs.sourcemap,
  ]
  # TODO move back dump_info, behavior changed
  # if ctx.attr.dump_info:
  #   other_outputs += [ctx.outputs.info_json]

  part_outputs = []
  for i in range(1, ctx.attr.deferred_lib_count + 1):
    part_outputs += [getattr(ctx.outputs, "part_js%s" % i)]
    other_outputs += [getattr(ctx.outputs, "part_sourcemap%s" % i)]

  # Invoke dart compile js.
  dart_compile_js_action(
      ctx=ctx,
      dart_ctx=dart_ctx,
      script_file=ctx.file.script_file,
      enable_asserts=ctx.attr.enable_asserts,
      csp=ctx.attr.csp,
      dump_info=False, # TODO move back dump_info, behavior changed
      minify=ctx.attr.minify,
      preserve_uris=False,  # No longer supported
      js_output=js_output,
      part_outputs=part_outputs,
      other_outputs=other_outputs,
  )

  # TODO(cbracken) aggregate, inject licenses
  return struct()


def _dart_web_application_outputs(dump_info, deferred_lib_count):
  """Returns the expected output map for dart_web_application."""
  outputs = {
      "js": "%{name}.js",
      "deps_file": "%{name}.js.deps",
      "sourcemap": "%{name}.js.map",
  }
  # TODO move back dump_info, behavior changed
  # if dump_info:
  #   outputs["info_json"] = "%{name}.js.info.json"
  for i in range(1, deferred_lib_count + 1):
    outputs["part_js%s" % i] = "%%{name}.js_%s.part.js" % i
    outputs["part_sourcemap%s" % i] = "%%{name}.js_%s.part.js.map" % i
  return outputs


dart_web_application = rule(
    implementation=_dart_web_application_impl,
    attrs={
        "script_file": attr.label(allow_single_file=True, mandatory=True),
        "srcs": attr.label_list(allow_files=True, mandatory=True),
        "data": attr.label_list(allow_files=True),
        "deps": attr.label_list(providers=["dart"]),
        "deferred_lib_count": attr.int(default=0),
        # compiler flags
        "enable_asserts": attr.bool(default=False),
        "csp": attr.bool(default=False),
        # TODO move back dump_info, behavior changed
        "dump_info": attr.bool(default=False),  # Kept for backward compatibility
        "minify": attr.bool(default=True),
        "preserve_uris": attr.bool(default=False),  # Kept for backward compatibility
        # tools
        "_dart_compile_js": attr.label(
            allow_single_file=True,
            executable=True,
            cfg="host",
            default=Label("//dart/build_rules/ext:dart_compile_js")),
        "_dart_compile_js_support": attr.label(
            allow_files=True,
            default=Label("//dart/build_rules/ext:dart_compile_js_support")),
        "_dart_compile_js_helper": attr.label(
            allow_single_file=True,
            executable=True,
            cfg="host",
            default=Label("//dart/build_rules/tools:dart_compile_js_helper")),
    },
    outputs=_dart_web_application_outputs,
)
