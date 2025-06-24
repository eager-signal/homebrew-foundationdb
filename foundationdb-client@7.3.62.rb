class FoundationdbClientAT7362 < Formula
  desc "FoundationDB - the open source, distributed, transactional key-value store"
  homepage "https://apple.github.io/foundationdb/"
  url "https://github.com/apple/foundationdb/archive/refs/tags/7.3.62.tar.gz"
  sha256 "60b763743cd2100714eacfc67bd87ce44612125c7d8f94810f0061f7653c3e31"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "mono" => :build
  depends_on "ninja" => :build
  depends_on "java" => :build

  depends_on "fmt" => :build

  def install

    # Fix C++14 for Boost
    inreplace "cmake/CompileBoost.cmake",
            "set(BOOST_COMPILER_FLAGS -fvisibility=hidden -fPIC -std=c++17 -w)",
            "set(BOOST_COMPILER_FLAGS -fvisibility=hidden -fPIC -std=c++14 -w)"

    # Fix toml11 not supporting cmake >= 3.5
    inreplace "cmake/FDBComponents.cmake" do |s|
      s.gsub!(/URL\s+"https:\/\/github\.com\/ToruNiina\/toml11\/archive\/[^"]+"/,
            'URL "https://github.com/ToruNiina/toml11/archive/refs/tags/v3.8.1.tar.gz"')
      s.gsub!(/URL_HASH\s+SHA256=[a-f0-9]+/,
            'URL_HASH SHA256=6a3d20080ecca5ea42102c078d3415bef80920f6c4ea2258e87572876af77849')
    end

    # Build with Java bindings
    java = Formula["java"]
    ENV["JAVA_HOME" ] = "#{java.libexec}/openjdk.jdk/Contents/Home"

    args = [
        # Use the embedded fmt, to avoid discovering newer versions with breaking header changes
        "-DCMAKE_DISABLE_FIND_PACKAGE_fmt=ON",
        # Fix ARM64 Mac issue https://forums.foundationdb.org/t/building-on-macos/4491/2
        "-DCMAKE_CXX_FLAGS=-Wl,-ld_classic"
    ]

    system "mkdir", "build"
    system "cmake", "-G", "Ninja", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "ninja", "-C", "build", "fdb_c", "fdbclient"

    # Install just the client library
    lib.install "build/lib/libfdb_c.dylib"
    include.install Dir["fdbclient/include/*"]
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test foundationdb`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system bin/"program", "do", "something"`.
    system "ctest", " -L", "fast"
  end
end
