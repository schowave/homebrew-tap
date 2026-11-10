class Browserdoor < Formula
  desc "Pick the browser, Chrome profile or Zen workspace for every link you open"
  homepage "https://github.com/schowave/browserdoor"
  url "https://github.com/schowave/browserdoor/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "5137bcbcd9b9c650ccc5ec9e08543fc828048d189676135b87da052837455f76"
  license "MIT"
  head "https://github.com/schowave/browserdoor.git", branch: "main"

  bottle do
    root_url "https://github.com/schowave/browserdoor/releases/download/v0.3.0"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "e846f5e4e6dcdd1f43db74914ab66a94a8f1ee5b26a8af56637fc9344b2d9864"
    sha256 cellar: :any_skip_relocation, sequoia:       "1c881d1ba6ced8b57c7ef62884d1315b0e30521d674cd96d87ae4645cc19bc21"
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
    # bin/browserdoor should start the app via the stable opt path, not this Cellar version.
    ENV["BIN_APP_PATH"] = (opt_prefix/"Browserdoor.app").to_s
    system ".mise/tasks/install"
    # Up to 0.2.x the command was `doorman`; their update script restarts the app with it.
    bin.install_symlink "browserdoor" => "doorman"
  end

  def caveats
    <<~EOS
      Start Browserdoor once; it then offers to become your default browser,
      links itself to ~/Applications/Browserdoor.app and adds a login item:
        browserdoor

      After `brew upgrade browserdoor`, quit Browserdoor from the menu bar and run `browserdoor` again.
      Configuration: ~/.config/browserdoor/config.json (menu bar → Konfiguration öffnen…)
    EOS
  end

  test do
    assert_path_exists prefix/"Browserdoor.app/Contents/MacOS/Browserdoor"
    assert_path_exists prefix/"Browserdoor.app/Contents/Resources/AppIcon.icns"
    # A bottle must not break the app's (ad-hoc) signature when Homebrew relocates it.
    system "codesign", "--verify", prefix/"Browserdoor.app"
    assert_match "open -a \"#{opt_prefix}/Browserdoor.app\"", (bin/"browserdoor").read
    assert_equal "browserdoor", (bin/"doorman").readlink.to_s
    assert_equal version.to_s,
                 shell_output("/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' " \
                              "#{prefix}/Browserdoor.app/Contents/Info.plist").strip
    assert_equal "io.github.schowave.doorman",
                 shell_output("/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' " \
                              "#{prefix}/Browserdoor.app/Contents/Info.plist").strip
  end
end
