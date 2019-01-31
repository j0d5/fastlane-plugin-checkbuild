require 'fastlane/action'
require_relative '../helper/checkbuild_helper'

module Fastlane
  class BinaryChecker
    def initialize(file_path)
      UI.verbose("Initialized new checker")
      @file_path = file_path
    end

    def check_architectures(required_archs)
      UI.verbose("Checking architectures...")
      lipo = %x( command -v lipo ).strip
      if lipo != "" then
        command = lipo + " -info " + @file_path
        result = `#{command}`

        required_archs.chunk { |arch|
          result[arch] != nil
        }.each { |found, arch|
          if found == false then
            UI.error("Non fat file, missing #{arch}")
            return
          elsif found == true then
            UI.success("Found all necessary architectures! #{arch}")
            return
          end
        }
      else
        UI.error("Command lipo not found!")
      end
    end

    def check_coverage_symbols
      UI.verbose("Check for coverage symbols...")
      otool = %x( command -v otool ).strip
      if otool != "" then
        command = otool + " -l -arch all " + @file_path
        result = `#{command}`

        if result.include? "__llvm_cov" then
          UI.error("File contains coverage symbols!")
        else
          UI.success("File does not contain any coverage symbols!")
        end
      else
        UI.error("Command otool not found!")
      end
    end

    def check_profiling_data
      UI.verbose("Check profiling info...")
      otool = %x( command -v otool ).strip
      if otool != "" then
        command = otool + " -l -arch all " + @file_path
        result = `#{command}`

        if result.include? "__llvm_" then
          UI.error("File contains profiling data!")
        else
          UI.success("File does not contain any profiling data!")
        end
      else
        UI.error("Command otool not found!")
      end
    end

    def check_encryption
      UI.verbose("Check encryption info...")
      otool = %x( command -v otool ).strip
      if otool != "" then
        command = otool + " -l " + @file_path
        result = `#{command}`

        if result.include? "LC_ENCRYPTION_INFO" then
          UI.message("File contains encryption info!")
        else
          UI.message("File does not contain any encryption info!")
        end
      else
        UI.error("Command otool not found!")
      end
    end

    def check_bitcode_availability
      UI.verbose("Check if bitcode is available")
      otool = %x( command -v otool ).strip
      if otool != "" then
        command = otool + " -arch arm64 -l " + @file_path
        result = `#{command}`

        contains_llvm = false
        if result.include? "__LLVM" then
          contains_llvm = true
        end

        contains_filesize = false
        if result.include? "filesize"
        # TODO
        contains_filesize = true
      end

      if contains_llvm && contains_filesize then
        UI.message("Bitcode active!")
      else
        UI.message("Bitcode inactive!")
      end
    else
      UI.error("Command otool not found!")
    end
  end

  def check_for_assertion
    UI.verbose("Check for assertions...")
    nm = %x( command -v nm ).strip
    if nm != "" then
      command = nm + " " + @file_path
      result = `#{command}`

      if result.include? "NSAssertionHandler" then
        UI.error("File contains assertions!")
      else
        UI.success("File does not contain any assertions!")
      end
    else
      UI.error("Command nm not found!")
    end
  end

  def check_debug_symbols
    UI.verbose("Check for debug symbols")
    nm = %x( command -v nm ).strip
    if nm != "" then
      command1 = nm + " " + @file_path
      command2 = nm + " -a " + @file_path
      slimDump = `#{command1}`
      fatDump = `#{command2}`
      # TODO
    end
  end

  def check_for_flagged_tests
    UI.verbose("Check for flagged tests")

  end

end

module Actions
  class CheckbuildAction < Action
    def self.run(params)
      file_path = File.expand_path(params[:file_path])
      required_archs = params[:req_archs].gsub(/[[:space:]]/, '').split(pattern=',')
      checker = BinaryChecker.new(file_path)
      checker.check_architectures(required_archs)
      checker.check_for_assertion
      checker.check_debug_symbols
      checker.check_profiling_data
      checker.check_encryption
      checker.check_coverage_symbols
      checker.check_bitcode_availability
    end

    def self.description
      "This plugin will check any binary library for unwanted symbols and architectures."
    end

    def self.authors
      ["Johannes Steudle"]
    end

    def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        [
          "This plugin can be used if there should be a check of the given binary file for unwanted symbols and architectures. ",
          "Various checks will be executed and provide information about the symbols that are part of the binary file.\n\n",
          "Sample output:\n\n",
          " ------------------------\n",
          " --- Step: checkbuild ---\n",
          " ------------------------\n",
          " Non fat file, missing ['i386', 'x86_64']\n",
          " File does not contain any assertions!\n",
          " File does not contain any profiling data!\n",
          " File contains encryption info!\n",
          " File does not contain any coverage symbols!\n",
          " Bitcode inactive!\n"
        ].join
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :file_path,
           env_name: 'FILE_PATH',
           description: 'Path to the file that should be checked. This must point to a binary file, either a library or an app\'s binary',
           optional: false,
           type: String),
          FastlaneCore::ConfigItem.new(key: :req_archs,
           env_name: 'REQ_ARCHS',
           description: 'The architectures that are required, e.g. i386, x86_64, armv7, arm64',
           optional: false,
           type: String)
        ]
      end

      def self.example_code
        [
          'checkbuild(
          file_path: \'../build/DerivedData/Build/Products/Debug-iphoneos/<AppName>.app/<AppName>\',
          req_archs: \'i386, x86_64, armv7, arm64\'
          )'
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
