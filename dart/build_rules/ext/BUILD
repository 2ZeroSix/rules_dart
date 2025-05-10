package(default_visibility = ["//visibility:public"])

filegroup(
    name = "dart_vm",
    srcs = select({
        "//dart:darwin_arm64": ["@dart_darwin_arm64//:dart_vm"],
        "//dart:darwin": ["@dart_darwin_x86_64//:dart_vm"],
        "//dart:k8": ["@dart_linux_x86_64//:dart_vm"],
    }),
)

filegroup(
    name = "dart_compile_js",
    srcs = select({
        "//dart:darwin_arm64": ["@dart_darwin_arm64//:dart_compile_js"],
        "//dart:darwin": ["@dart_darwin_x86_64//:dart_compile_js"],
        "//dart:k8": ["@dart_linux_x86_64//:dart_compile_js"],
    }),
)

filegroup(
    name = "dart_compile_js_support",
    srcs = select({
        "//dart:darwin_arm64": ["@dart_darwin_arm64//:dart_compile_js_support"],
        "//dart:darwin": ["@dart_darwin_x86_64//:dart_compile_js_support"],
        "//dart:k8": ["@dart_linux_x86_64//:dart_compile_js_support"],
    }),
)
