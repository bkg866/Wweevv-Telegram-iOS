load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "YoutubeKit",
    module_name = "YoutubeKit",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    data = [
        "Sources/Resources/player.html",
     ],
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelegramCore:TelegramCore",
    ],
    visibility = [
        "//visibility:public",
    ],
)
