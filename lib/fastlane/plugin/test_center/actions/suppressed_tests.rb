module Fastlane
  module Actions
    class SuppressedTestsAction < Action
      require 'set'

      def self.run(params)
        scheme = params[:scheme]

        scheme_filepaths = schemes_from_project(params[:xcodeproj]) || schemes_from_workspace(params[:xcodeworkspace])
        if scheme_filepaths.length.zero?
          UI.user_error!("Error: cannot find any scheme named #{scheme}") unless scheme.nil?
          UI.user_error!("Error: cannot find any schemes in the Xcode project")
        end

        skipped_tests = Set.new
        scheme_filepaths.each do |scheme_filepath|
          xcscheme = Xcodeproj::XCScheme.new(scheme_filepath)
          xcscheme.test_action.testables.each do |testable|
            buildable_name = testable.buildable_references[0]
                                     .buildable_name

            buildable_name = File.basename(buildable_name, '.xctest')
            testable.skipped_tests.map do |skipped_test|
              skipped_tests.add("#{buildable_name}/#{skipped_test.identifier}")
            end
          end
        end
        skipped_tests.to_a
      end

      def self.schemes_from_project(project_path)
        Dir.glob("#{project_path}/{xcshareddata,xcuserdata}/**/xcschemes/#{scheme || '*'}.xcscheme")
      end

      def self.schemes_from_workspace(workspace_path)
        xcworkspace = Xcodeproj::Workspace.new(workspace_path)
        scheme_filepaths = []
        xcworkspace.file_references.each do |fire_reference|
          scheme_filepaths << schemes_from_project(file_reference.absolute_path(workspace_path))
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Retrieves a list of tests that are suppressed in a specific or all Xcode Schemes in a project"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :xcodeproj,
            env_name: "FL_SUPPRESSED_TESTS_XCODE_PROJECT",
            description: "The file path to the Xcode project file to read the skipped tests from",
            verify_block: proc do |path|
              UI.user_error!("Error: Xcode project file path not given!") unless path and !path.empty?
              UI.user_error!("Error: Xcode project '#{path}' not found!") unless Dir.exist?(path)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :scheme,
            optional: true,
            env_name: "FL_SUPPRESSED_TESTS_SCHEME_TO_UPDATE",
            description: "The Xcode scheme where the suppressed tests may be",
            verify_block: proc do |scheme_name|
              UI.user_error!("Error: Xcode Scheme '#{scheme_name}' is not valid!") if scheme_name and scheme_name.empty?
            end
          )
        ]
      end

      def self.example_code
        [
          "
          UI.important(
            'example: ' \\
            'get the tests that are suppressed in a Scheme in the Project'
          )
          tests = suppressed_tests(
            xcodeproj: 'AtomicBoy/AtomicBoy.xcodeproj',
            scheme: 'AtomicBoy'
          )
          UI.message(\"Suppressed tests for scheme: \#{tests}\")
          ",
          "
          UI.important(
            'example: ' \\
            'get the tests that are suppressed in all Schemes in the Project'
          )
          UI.message(
            \"Suppressed tests for project: \#{suppressed_tests(xcodeproj: 'AtomicBoy/AtomicBoy.xcodeproj')}\"
          )
          "
        ]
      end

      def self.authors
        ["lyndsey-ferguson/@lyndseydf"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
