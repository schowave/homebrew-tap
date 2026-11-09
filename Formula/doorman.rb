class Doorman < Formula
  desc "Pick the browser, Chrome profile or Zen workspace for every link you open"
  homepage "https://github.com/schowave/doorman"
  url "https://github.com/schowave/doorman/archive/refs/tags/v0.2.5.tar.gz"
  sha256 "30dc509fcb094b6dee43f446cf62ded6dfdb8b90d0d78c8b48f3e59dba71f79b"
  license "MIT"
  head "https://github.com/schowave/doorman.git", branch: "main"

  bottle do
    root_url "https://github.com/schowave/doorman/releases/download/v0.2.5"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "79b10ca5564d60f309d02c2615fa66accffc93b94155aebd0976b2b0341dd385"
    sha256 cellar: :any_skip_relocation, sequoia:       "75205ef437536b9f168be4abeccf0c5c62c21f2f254fd49d5a4a0ec35a6b4fe9"
  end

  # Only when building from source; bottles need no Xcode.
  depends_on xcode: ["16.0", :build] # Swift 6
  depends_on macos: :sonoma

  def install
    # The repo's mise task is a plain shell script; no mise needed here.
    ENV["PREFIX"] = prefix.to_s
    ENV["VERSION"] = version.to_s
    # Homebrew's sandbox forbids SwiftPM's own sandbox.
    ENV["SWIFT_BUILD_FLAGS"] = "--disable-sandbox"
    # bin/doorman should start the app via the stable opt path, not this Cellar version.
    ENV["BIN_APP_PATH"] = (opt_prefix/"Doorman.app").to_s
    system ".mise/tasks/install"
  end

  def caveats
    <<~EOS
      Start Doorman once; it then offers to become your default browser,
      links itself to ~/Applications/Doorman.app and adds a login item:
        doorman

      After `brew upgrade doorman`, quit Doorman from the menu bar and run `doorman` again.
      Configuration: ~/.config/doorman/config.json (menu bar → Konfiguration öffnen…)
    EOS
  end

  test do
    assert_path_exists prefix/"Doorman.app/Contents/MacOS/Doorman"
    assert_path_exists prefix/"Doorman.app/Contents/Resources/AppIcon.icns"
    # A bottle must not break the app's (ad-hoc) signature when Homebrew relocates it.
    system "codesign", "--verify", prefix/"Doorman.app"
    assert_match "open -a \"#{opt_prefix}/Doorman.app\"", (bin/"doorman").read
    assert_equal version.to_s,
                 shell_output("/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' " \
                              "#{prefix}/Doorman.app/Contents/Info.plist").strip
    assert_equal "io.github.schowave.doorman",
                 shell_output("/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' " \
                              "#{prefix}/Doorman.app/Contents/Info.plist").strip
  end
end
