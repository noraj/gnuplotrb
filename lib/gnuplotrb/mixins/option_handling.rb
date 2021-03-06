module GnuplotRB
  ##
  # This module contains methods which are mixed into several classes
  # to set, get and convert their options.
  module OptionHandling
    class << self
      # Some values of options should be quoted to be read by gnuplot properly
      #
      # @todo update list with data from gnuplot documentation !!!
      QUOTED_OPTIONS = %w(
        title
        output
        xlabel
        x2label
        ylabel
        y2label
        clabel
        cblabel
        zlabel
        rgb
        font
        background
        format
        format_x
        format_y
        format_xy
        format_x2
        format_y2
        format_z
        format_cb
        timefmt
        dt
        dashtype
      )

      private_constant :QUOTED_OPTIONS

      ##
      # Replace '_' with ' ' is made to allow passing several options
      # with the same first word of key. See issue #7 for more info.
      # @param key [Symbol, String] key to modify
      # @return [String] given key with '_' replaced with ' '
      def string_key(key)
        key.to_s.gsub(/_/) { ' ' } + ' '
      end

      ##
      # Recursive function that converts Ruby option to gnuplot string
      #
      # @param key [Symbol] name of option in gnuplot
      # @param option an option that should be converted
      # @example
      #   option_to_string(['png', size: [300, 300]])
      #   #=> 'png size 300,300'
      #   option_to_string(xrange: 0..100)
      #   #=> 'xrange [0:100]'
      #   option_to_string(multiplot: true)
      #   #=> 'multiplot'
      def option_to_string(key = nil, option)
        return string_key(key) if !!option == option # check for boolean
        value = ruby_class_to_gnuplot(option)
        value = "\"#{value}\"" if QUOTED_OPTIONS.include?(key.to_s)
        ## :+ here is necessary, because using #{value} will remove quotes
        value = string_key(key) + value if key
        value
      end

      ##
      # @private
      # Method for inner use.
      # Needed to convert several ruby classes into
      # value that should be piped to gnuplot.
      def ruby_class_to_gnuplot(option_object)
        case option_object
        when Array
          option_object.map { |el| option_to_string(el) }
                       .join(option_object[0].is_a?(Numeric) ? ',' : ' ')
        when Hash
          option_object.map { |i_key, i_val| option_to_string(i_key, i_val) }
                       .join(' ')
        when Range
          "[#{option_object.begin}:#{option_object.end}]"
        else
          option_object.to_s
        end
      end

      ##
      # Check if given terminal available for use.
      #
      # @param terminal [String] terminal to check (e.g. 'png', 'qt', 'gif')
      # @return [Boolean] true or false
      def valid_terminal?(terminal)
        Settings.available_terminals.include?(terminal)
      end

      ##
      # Check if given options are valid for gnuplot.
      # Raises ArgumentError if invalid options found.
      # Now checks only terminal name.
      #
      # @param options [Hash] options to check (e.g. "{ term: 'qt', title: 'Plot title' }")
      def validate_terminal_options(options)
        terminal = options[:term]
        return unless terminal
        terminal = terminal[0] if terminal.is_a?(Array)
        message = 'Seems like your Gnuplot does not ' \
                  "support that terminal (#{terminal}), please see " \
                  'supported terminals with Settings::available_terminals'
        fail(ArgumentError, message) unless valid_terminal?(terminal)
      end
    end

    ##
    # @private
    # You should implement #initialize in classes that use OptionsHelper
    def initialize(*_)
      fail NotImplementedError, 'You should implement #initialize' \
                                ' in classes that use OptionsHelper!'
    end

    ##
    # @private
    # You should implement #new_with_options in classes that use OptionsHelper
    def new_with_options(*_)
      fail NotImplementedError, 'You should implement #new_with_options' \
                                ' in classes that use OptionsHelper!'
    end

    ##
    # Create new Plot (or Dataset or Splot or Multiplot) object where current
    # options are merged with given. If no options
    # given it will just return existing set of options.
    #
    # @param options [Hash] options to add
    # @return [Dataset, Splot, Multiplot] new object created with given options
    # @return [Hamster::Hash] current options if given options empty
    # @example
    #   sin_graph = Plot.new(['sin(x)', title: 'Sin'], title: 'Sin on [0:3]', xrange: 0..3)
    #   sin_graph.plot
    #   sin_graph_update = sin_graph.options(title: 'Sin on [-10:10]', xrange: -10..10)
    #   sin_graph_update.plot
    #   # sin_graph IS NOT affected
    def options(**options)
      @options ||= Hamster::Hash.new
      if options.empty?
        @options
      else
        new_with_options(@options.merge(options))
      end
    end

    ##
    # Update existing Plot (or Dataset or Splot or Multiplot) object with given options.
    #
    # @param options [Hash] options to add
    # @return [Dataset, Splot, Multiplot] self
    # @example
    #   sin_graph = Plot.new(['sin(x)', title: 'Sin'], title: 'Sin on [0:3]', xrange: 0..3)
    #   sin_graph.plot
    #   sin_graph.options!(title: 'Sin on [-10:10]', xrange: -10..10)
    #   sin_graph.plot
    #   # second #plot call will plot not the same as first, sin_graph IS affected
    def options!(**options)
      @options = @options ? @options.merge(options) : Hamster::Hash.new(options)
      self
    end

    private

    ##
    # Return current option value if no value given. Create new
    # object with given option set if value given.
    def option(key, *value)
      if value.empty?
        value = options[key]
        value = value[0] if value && value.size == 1
        value
      else
        options(key => value)
      end
    end

    ##
    # Just set an option.
    def option!(key, *value)
      options!(key => value)
    end
  end
end
