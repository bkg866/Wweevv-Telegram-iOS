load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "WevNetworkManager",
    module_name = "WevNetworkManager",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/WevModel:WevModel",
        "//submodules/WevConfig:WevConfig",
        "//third-party/Alamofire",
    ],
    visibility = [
        "//visibility:public",
    ],
)
