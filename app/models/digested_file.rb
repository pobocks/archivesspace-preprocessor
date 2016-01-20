# Module with common functionality for files represented by digests
#
# Delegates most operations to File object.
module DigestedFile

  # Methods to be defined in including classes and instances of same
  def self.included(base)
    base.extend(ClassMethods) #include class methods

    # Definitions for instance methods in including class
    base.class_eval do

      # @return [String] the SHA256 digest of the file's content in hex format
      attr_reader :digest

      # Looks up existing file of base type from filesystem or else creates a file
      #
      # @param obj [String, #read] file or file contents
      # @return [DigestedFile] Base class including DigestedFile
      def initialize(obj)
        content = if obj.respond_to?(:read)
                    obj.read
                  else
                    obj
                  end

        @digest = Digest::SHA256.hexdigest(content)

        @fname = File.join(self.class::FILE_DIR, "#{@digest}.xml")

        File.open(@fname, 'w', 0444) do |f|
          f.write(content)
        end unless File.exist? @fname

        @del_target = File.new(@fname, 'r')

        super(@del_target)
      end

      # Several methods to make DigestedFiles present as such in Pry et alia

      # @visibility private
      def inspect
        @del_target.inspect.insert(2, self.class::INSPECT_SLUG)
      end

      # @visibility private
      def to_s
        out = read
        rewind
        out
      end

      # @visibility private
      def pretty_print(pp)
        pp.text inspect
      end

    end
  end

  # Definitions for class methods in including class
  module ClassMethods
    # Convenience methods for interacting with the class as a file registry

    # @param [String] digest SHA256 digest in hex format
    # @return [DigestedFile, nil] the file or nil
    def [](digest)
      @fname = File.join(self::FILE_DIR, "#{digest}.xml")
      if File.exists? @fname
        new(File.open(@fname, 'r'))
      else
        nil
      end
    end

    # Filenames of all files in FILE_DIR
    #
    # @return [Array<String>] filenames
    def filenames
      Dir[File.join(self::FILE_DIR, '*.xml')].sort_by { |fn| File.ctime fn }
    end

    # SHA digests of all files in FILE_DIR
    #
    # @return [Array<String>] SHA256 digests
    def digests
      filenames.map {|f| File.basename(f).sub(/\.xml$/, '') }
    end

    # All Files in directory
    #
    # @return [Array<DigestedFile>] All known files in FILE_DIR
    def all
      digests.map {|d| self[d] }
    end
  end

end