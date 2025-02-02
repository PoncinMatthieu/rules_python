""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

# Avoid a load from @bazel_skylib repository as users don't necessarily have it installed
load("//third_party/github.com/bazelbuild/bazel-skylib/lib:versions.bzl", "versions")

_RULE_DEPS = [
    (
        "pypi__click",
        "https://files.pythonhosted.org/packages/76/0a/b6c5f311e32aeb3b406e03c079ade51e905ea630fc19d1262a46249c1c86/click-8.0.1-py3-none-any.whl",
        "fba402a4a47334742d782209a7c79bc448911afe1149d07bdabdf480b3e2f4b6",
    ),
    (
        "pypi__colorama",
        "https://files.pythonhosted.org/packages/44/98/5b86278fbbf250d239ae0ecb724f8572af1c91f4a11edf4d36a206189440/colorama-0.4.4-py2.py3-none-any.whl",
        "9f47eda37229f68eee03b24b9748937c7dc3868f906e8ba69fbcbdd3bc5dc3e2",
    ),
    (
        "pypi__installer",
        "https://files.pythonhosted.org/packages/1b/21/3e6ebd12d8dccc55bcb7338db462c75ac86dbd0ac7439ac114616b21667b/installer-0.5.1-py3-none-any.whl",
        "1d6c8d916ed82771945b9c813699e6f57424ded970c9d8bf16bbc23e1e826ed3",
    ),
    (
        "pypi__pep517",
        "https://files.pythonhosted.org/packages/f4/67/846c08e18fefb265a66e6fd5a34269d649b779718d9bf59622085dabd370/pep517-0.12.0-py2.py3-none-any.whl",
        "dd884c326898e2c6e11f9e0b64940606a93eb10ea022a2e067959f3a110cf161",
    ),
    (
        "pypi__pip",
        "https://files.pythonhosted.org/packages/96/2f/caec18213f6a67852f6997fb0673ae08d2e93d1b81573edb93ba4ef06970/pip-22.1.2-py3-none-any.whl",
        "a3edacb89022ef5258bf61852728bf866632a394da837ca49eb4303635835f17",
    ),
    (
        "pypi__pip_tools",
        "https://files.pythonhosted.org/packages/fe/5c/8995799b0ccf832906b4968b4eb2045beb9b3de79e96e6b1a6e4fc4e6974/pip_tools-6.6.2-py3-none-any.whl",
        "6b486548e5a139e30e4c4a225b3b7c2d46942a9f6d1a91143c21b1de4d02fd9b",
    ),
    (
        "pypi__setuptools",
        "https://files.pythonhosted.org/packages/7c/5b/3d92b9f0f7ca1645cba48c080b54fe7d8b1033a4e5720091d1631c4266db/setuptools-60.10.0-py3-none-any.whl",
        "782ef48d58982ddb49920c11a0c5c9c0b02e7d7d1c2ad0aa44e1a1e133051c96",
    ),
    (
        "pypi__tomli",
        "https://files.pythonhosted.org/packages/97/75/10a9ebee3fd790d20926a90a2547f0bf78f371b2f13aa822c759680ca7b9/tomli-2.0.1-py3-none-any.whl",
        "939de3e7a6161af0c887ef91b7d41a53e7c5a1ca976325f429cb46ea9bc30ecc",
    ),
    (
        "pypi__wheel",
        "https://files.pythonhosted.org/packages/27/d6/003e593296a85fd6ed616ed962795b2f87709c3eee2bca4f6d0fe55c6d00/wheel-0.37.1-py2.py3-none-any.whl",
        "4bdcd7d840138086126cd09254dc6195fb4fc6f01c050a1d7236f2630db1d22a",
    ),
    (
        "pypi__importlib_metadata",
        "https://files.pythonhosted.org/packages/d2/a2/8c239dc898138f208dd14b441b196e7b3032b94d3137d9d8453e186967fc/importlib_metadata-4.12.0-py3-none-any.whl",
        "7401a975809ea1fdc658c3aa4f78cc2195a0e019c5cbc4c06122884e9ae80c23",
    ),
    (
        "pypi__zipp",
        "https://files.pythonhosted.org/packages/f0/36/639d6742bcc3ffdce8b85c31d79fcfae7bb04b95f0e5c4c6f8b206a038cc/zipp-3.8.1-py3-none-any.whl",
        "47c40d7fe183a6f21403a199b3e4192cca5774656965b0a4988ad2f8feb5f009",
    ),
    (
        "pypi__typing_extensions",
        "https://files.pythonhosted.org/packages/ed/d6/2afc375a8d55b8be879d6b4986d4f69f01115e795e36827fd3a40166028b/typing_extensions-4.3.0-py3-none-any.whl",
        "25642c956049920a5aa49edcdd6ab1e06d7e5d467fc00e0506c44ac86fbfca02",
    ),
]

_GENERIC_WHEEL = """\
package(default_visibility = ["//visibility:public"])

load("@rules_python//python:defs.bzl", "py_library")

py_library(
    name = "lib",
    srcs = glob(["**/*.py"]),
    data = glob(["**/*"], exclude=["**/*.py", "**/* *", "BUILD", "WORKSPACE"]),
    # This makes this directory a top-level in the python import
    # search path for anything that depends on this.
    imports = ["."],
)
"""

# Collate all the repository names so they can be easily consumed
all_requirements = [name for (name, _, _) in _RULE_DEPS]

def requirement(pkg):
    return "@pypi__" + pkg + "//:lib"

def pip_install_dependencies():
    """
    Fetch dependencies these rules depend on. Workspaces that use the pip_install rule can call this.

    (However we call it from pip_install, making it optional for users to do so.)
    """

    # We only support Bazel LTS and rolling releases.
    # Give the user an obvious error to upgrade rather than some obscure missing symbol later.
    # It's not guaranteed that users call this function, but it's used by all the pip fetch
    # repository rules so it's likely that most users get the right error.
    versions.check("4.0.0")

    for (name, url, sha256) in _RULE_DEPS:
        maybe(
            http_archive,
            name,
            url = url,
            sha256 = sha256,
            type = "zip",
            build_file_content = _GENERIC_WHEEL,
        )
