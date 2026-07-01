class Mcmobsheet < Formula
  desc "Translate Minecraft /summon and /setblock data into readable info"
  homepage "https://github.com/chrisjniles/mcmobsheet"
  url "https://github.com/chrisjniles/mcmobsheet/archive/refs/tags/v1.0.4.tar.gz"
  sha256 "e196c3937c1379fc69afa305ed4f3dadc8e026c91bd251aaad5b775b647e8397"
  license "GPL-3.0-or-later"

  # mcmobsheet has zero Python runtime dependencies, so rather than pulling in
  # a Homebrew Python (and the openssl/sqlite/readline chain that comes with
  # it), it builds against the Python 3 already provided by the Xcode Command
  # Line Tools. This requirement confirms that interpreter is present, new
  # enough, and has a working pip before the build starts, so a missing or
  # broken Command Line Tools install fails with a clear, actionable message
  # instead of a confusing build error.
  class SystemPython3Requirement < Requirement
    fatal true

    SYSTEM_PYTHON = "/usr/bin/python3".freeze
    MIN_VERSION = Version.new("3.9").freeze

    satisfy(build_env: false) do
      python3_ok?
    end

    def python3_ok?
      return false unless File.executable?(SYSTEM_PYTHON)

      version_out = Utils.safe_popen_read(SYSTEM_PYTHON, "--version")
      match = version_out.match(/Python (\d+\.\d+(?:\.\d+)?)/)
      return false unless match
      return false if Version.new(match[1]) < MIN_VERSION

      Utils.safe_popen_read(SYSTEM_PYTHON, "-m", "pip", "--version")
      true
    rescue
      false
    end

    def message
      <<~EOS
        mcmobsheet builds against the system Python 3 normally provided by the
        Xcode Command Line Tools (#{SYSTEM_PYTHON}), instead of a Homebrew
        Python, so it has no extra runtime dependencies (no openssl, etc.).

        That interpreter is missing, older than #{MIN_VERSION}, or its pip is
        broken. To install or repair the Command Line Tools:
          xcode-select --install

        If they already report as installed but this still fails, reinstall them:
          sudo rm -rf /Library/Developer/CommandLineTools
          xcode-select --install
      EOS
    end
  end

  depends_on SystemPython3Requirement => :build

  def install
    system_python = SystemPython3Requirement::SYSTEM_PYTHON

    # Seed the venv with its own pip rather than using Language::Python::Virtualenv's
    # helpers, which invoke the *outer* interpreter's pip with a `--python=<venv>`
    # cross-install flag. That flag requires pip >= 22.3; the Xcode Command Line
    # Tools' bundled pip is much older (21.2.4 as of writing) and rejects it.
    system system_python, "-m", "venv", libexec
    system libexec/"bin/pip", "install", "--upgrade", "pip"
    system libexec/"bin/pip", "install", buildpath

    bin.install_symlink libexec/"bin/mcmobsheet"
    man1.install "man/mcmobsheet.1"
  end

  test do
    output = shell_output("#{bin}/mcmobsheet '/summon minecraft:donkey 0 64 0 {CustomName: \"Test\"}'")
    assert_match "Donkey", output
    assert_match "Location: 0, 64, 0", output
    assert_path_exists man1/"mcmobsheet.1"
  end
end
