load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "RESegmentedControl",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/WevConfig:WevConfig",
        "//submodules/SnapKit:SnapKit"
    ],
    module_name = "RESegmentedControl",
    visibility = ["//visibility:public"],
)
