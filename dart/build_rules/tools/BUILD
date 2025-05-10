package(default_visibility = ["//visibility:public"])

filegroup(
    name = "dart_compile_js_helper",
    srcs = select({
        "//dart:darwin_arm64": ["dart_compile_js_helper.sh"],
        "//dart:darwin": ["dart_compile_js_helper.sh"],
        "//dart:k8": ["dart_compile_js_helper.sh"],
    }),
)
