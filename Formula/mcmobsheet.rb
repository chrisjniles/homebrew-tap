class Mcmobsheet < Formula
  include Language::Python::Virtualenv

  desc "Translate Minecraft /summon and /setblock data into readable info"
  homepage "https://github.com/chrisjniles/mcmobsheet"
  url "https://github.com/chrisjniles/mcmobsheet/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "fa47527974c224047e5ba7bba9aafb743c2db989bb982ca8a618ff5e9d1a697a"
  license "GPL-3.0-or-later"

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  test do
    output = shell_output("#{bin}/mcmobsheet '/summon minecraft:donkey 0 64 0 {CustomName: \"Test\"}'")
    assert_match "Donkey", output
    assert_match "Location: 0, 64, 0", output
  end
end
