module Packtory
  module Packages
    PACKAGE_METHOD_MAP = {
      :deb => :build_deb,
      :rpm => :build_rpm,
      :tgz => :build_tgz,
      :brew => :build_brew
    }

    def self.build_package(opts = { })
      packages = Packtory.config[:packages]
      built = [ ]

      packages.each do |pack|
        build_method = PACKAGE_METHOD_MAP[pack]
        unless build_method.nil?
          built << send(build_method, opts)
        end
      end

      built
    end

    def self.build_deb(opts = { })
      DebPackage.build_package(opts)
    end

    def self.build_rpm(opts = { })
      RpmPackage.build_package(opts)
    end

    def self.build_tgz(opts = { })
      TgzPackage.build_package(opts)
    end

    def self.build_brew(opts = { })
      BrewPackage.build_package(opts)
    end
  end
end
