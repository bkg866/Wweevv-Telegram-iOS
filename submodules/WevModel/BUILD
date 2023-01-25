load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "WevModel",
    module_name = "WevModel",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/HandyJSON:HandyJSON",
    ],
    visibility = [
        "//visibility:public",
    ],
)
