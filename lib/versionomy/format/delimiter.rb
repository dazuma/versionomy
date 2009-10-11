# -----------------------------------------------------------------------------
# 
# Versionomy delimiter format
# 
# -----------------------------------------------------------------------------
# Copyright 2008-2009 Daniel Azuma
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------
;


module Versionomy
  
  module Format
    
    
    # The Delimiter format class provides a DSL for building formats that
    # can handle most cases where the fields of a version number appear
    # consecutively in order in the string formatting. We expect most
    # version number schemes should fall into this category.
    # 
    # In general, the strategy is to provide, for each field, a set of
    # regular expressions that recognize different formats for that field.
    # Every field must be of the form "<pre><value><post>" where <pre> and
    # <post> are delimiters preceding and following the value. Either or
    # both delimiters may be the empty string.
    # 
    # To parse a string, the string is scanned from left to right and
    # matched against the format for the fields in order. If the string
    # matches, that part of the string is consumed and the field value is
    # interpreted from it. If the string does not match, and the field is
    # not marked as "required", then the field is set to its default value
    # and the next field is tried.
    # 
    # During parsing, the actual delimiters, along with other information
    # such as whether or not fields are required, are saved into a default
    # set of parameters for unparsing. These are saved in the unparse_params
    # of the version value, so that the version number can be unparsed in
    # generally the same form. If the version number value is modified, this
    # allows the unparsing of the new value to generally follow the format
    # of the original string.
    # 
    # For a usage example, see the definition of the standard format in
    # Versionomy::Format#_create_standard.
    
    class Delimiter
      
      
      # Create a format using delimiter tools.
      # You should provide the version number schema, a set of default
      # options, and a block. 
      # 
      # Within the block, you can call methods of
      # Versionomy::Format::Delimiter::Builder
      # to provide parsers for the fields of the schema. Any fields you do
      # not explicitly configure will get parsed in a default manner.
      
      def initialize(schema_, default_opts_={}, &block_)
        # Special case used by modified_copy
        if schema_.kind_of?(Delimiter)
          orig_ = schema_
          @schema = orig_.schema
          @default_parse_params = orig_.default_parse_params
          @default_unparse_params = orig_.default_unparse_params
          @nodes = orig_.instance_variable_get(:@nodes).dup
          builder_ = Delimiter::Builder.new(@schema, @nodes,
            @default_parse_params, @default_unparse_params)
          ::Blockenspiel.invoke(block_, builder_)
          return
        end
        
        @schema = schema_
        @nodes = {}
        @default_parse_params = {}
        @default_unparse_params = {}
        builder_ = Delimiter::Builder.new(@schema, @nodes,
          @default_parse_params, @default_unparse_params)
        ::Blockenspiel.invoke(block_, builder_)
        @schema.names.each do |name_|
          field_ = @schema.field_named(name_)
          @nodes[name_] ||=
            case field_.type
            when :integer
              Delimiter::BasicIntegerNode.new(field_, default_opts_)
            when :string
              Delimiter::BasicStringNode.new(field_, default_opts_)
            when :symbol
              Delimiter::DefaultSymbolNode.new(field_, default_opts_)
            end
        end
      end
      
      
      # Returns the schema understood by this format.
      # This method is required by the Format contract.
      
      def schema
        @schema
      end
      
      
      # Parse the given string and return a value.
      # This method is required by the Format contract.
      
      def parse(string_, params_=nil)
        values_ = {}
        parse_params_ = default_parse_params
        parse_params_.merge!(params_) if params_
        parse_params_[:string] = string_
        parse_params_[:previous_field_missing] = false
        unparse_params_ = {}
        field_ = @schema.root_field
        while field_
          node_ = @nodes[field_.name]
          v_ = node_.parse(parse_params_, unparse_params_) || field_.initial_value
          values_[field_.name] = v_
          field_ = field_.child(v_)
        end
        if parse_params_[:strict] && parse_params_[:string].length > 0
          raise Errors::ParseError, "Extra characters: #{parse_params_[:string].inspect}"
        end
        Value.new(values_, self, unparse_params_)
      end
      
      
      # Unparse the given value and return a string.
      # This method is required by the Format contract.
      
      def unparse(value_, params_=nil)
        unparse_params_ = value_.unparse_params || default_unparse_params
        unparse_params_.merge!(params_) if params_
        fields_ = unparse_params_.delete(:required_fields)
        if fields_
          fields_.each do |f_|
            node_ = @nodes[f_]
            if node_
              delimiters_ = node_.default_delimiters
              unparse_params_["#{f_}_delim".to_sym] ||= delimiters_[0]
              unparse_params_["#{f_}_postdelim".to_sym] ||= delimiters_[1]
              unparse_params_["#{f_}_optional".to_sym] = false
            end
          end
        end
        fields_ = unparse_params_.delete(:optional_fields)
        if fields_
          fields_.each do |f_|
            unparse_params_["#{f_}_optional".to_sym] = true
          end
        end
        string_ = ''
        value_.each_field_object do |field_, val_|
          node_ = @nodes[field_.name]
          fragment_ = node_.unparse(val_, unparse_params_)
          if fragment_
            list_ = unparse_params_.delete(:skipped_node_list)
            if list_ && node_.requires_previous_field && !unparse_params_[:required_for_later]
              unparse_params_[:required_for_later] = true
              list_.each do |n_|
                frag_ = n_[0].unparse(n_[1], unparse_params_)
                unless frag_
                  raise Errors::UnparseError, "Field #{field_.name} empty although a prerequisite for a later field"
                end
                string_ << frag_
              end
              unparse_params_[:required_for_later] = false
            end
            string_ << fragment_
          else
            if node_.requires_previous_field
              (unparse_params_[:skipped_node_list] ||= []) << [node_, val_]
            else
              unparse_params_[:skipped_node_list] = [[node_, val_]]
            end
          end
        end
        string_
      end
      
      
      # Return a copy of the default parsing parameters used by this format.
      # This hash cannot be edited in place. To modify the default parsing
      # parameters, use modified_copy and call
      # Versionomy::Format::Delimiter::Builder#default_parse_params in the block.
      
      def default_parse_params
        @default_parse_params.dup
      end
      
      
      # Return a copy of the default unparsing parameters used by this format.
      # This hash cannot be edited in place. To modify the default unparsing
      # parameters, use modified_copy and call
      # Versionomy::Format::Delimiter::Builder#default_unparse_params in the block.
      
      def default_unparse_params
        @default_unparse_params.dup
      end
      
      
      # Create a copy of this format, with the modifications given in the
      # provided block. You can call methods of Versionomy::Format::Buidler
      # in the block. Field handlers that you specify in that block will
      # override and change the field handlers from the original. Any fields
      # not specified in this block will use the handlers from the original.
      
      def modified_copy(&block_)
        Delimiter.new(self, &block_)
      end
      
      
      # This class defines methods that you can call within the DSL block
      # passed to Versionomy::Format::Delimiter#new.
      # 
      # Most methods of this class specify the formatting for a particular
      # named field-- you pass the name of the field and a hash of
      # formatting options. Many parameters are common to these methods;
      # these are listed below.
      # 
      # Some of these are regular expressions that indicate what patterns
      # are recognized by the parser. Regular expressions should be passed
      # in as the string representation of the regular expression, not a
      # Regexp object itself. For example, use the string '\.' rather than
      # the Regexp /\./ to recognize a period delimiter.
      # 
      # The following are common parameters:
      # 
      # <tt>:required_unparse</tt>::
      #   If set to true, this field must be present in the formatted
      #   version number value. If false, the field may be omitted if it
      #   is set to its default value.
      #   For example, for a version number like "2.0.0", often the third
      #   field is optional, but the first and second are required.
      #   Default is false.
      # <tt>:case_sensitive</tt>::
      #   If set to true, the regexps are case-sensitive. Default is false.
      # <tt>:delimiter_regexp</tt>::
      #   The regular expression string for the pre-delimiter. This pattern
      #   must appear before the current value in the string, and is
      #   consumed when the field is parsed, but is not part of the value
      #   itself. Default is '\.' to recognize a period.
      # <tt>:post_delimiter_regexp</tt>::
      #   The regular expression string for the post-delimiter. This pattern
      #   must appear before the current value in the string, and is
      #   consumed when the field is parsed, but is not part of the value
      #   itself. Default is '' to indicate no post-delimiter.
      # <tt>:expected_follower_regexp</tt>::
      #   The regular expression string for what characters are expected to
      #   follow this field in the string. These characters are not part
      #   of the field itself, and are *not* consumed when the field is
      #   parsed; however, they must be present immediately after this
      #   field in order for the field to be recognized. Default is '' to
      #   indicate that we aren't testing for any particular characters.
      # <tt>:default_delimiter</tt>::
      #   The default delimiter string. This is the string that is used
      #   to unparse a field value if the field was not present when the
      #   value was originally parsed. For example, if you parse the string
      #   "2.0", bump the tiny version so that the value is "2.0.1", and
      #   unparse, the unparsing won't receive the second period from
      #   parsing the original string, so its delimiter will use the default.
      #   Default value is '.'
      # <tt>:default_post_delimiter</tt>::
      #   The default post-delimiter string. Default value is '' indicating
      #   no post-delimiter.
      # <tt>:requires_previous_field</tt>::
      #   If set to true, this field's presence in a formatted version string
      #   requires the presence of the previous field. For example, in a
      #   typical version number "major.minor.tiny", tiny should appear in
      #   the string only if minor also appears, so tiny should have this
      #   parameter set to true. The default is true, so you must specify
      #   <tt>:requires_previous_field => false</tt> explicitly if you want
      #   a field not to require the previous field.
      
      class Builder
        
        include ::Blockenspiel::DSL
        
        def initialize(schema_, nodes_, default_parse_params_, default_unparse_params_)  # :nodoc:
          @schema = schema_
          @nodes = nodes_
          @default_parse_params = default_parse_params_
          @default_unparse_params = default_unparse_params_
        end
        
        
        # Specify the formatting for an integer-type field where the value
        # is formatted numerically.
        # You must pass the name of the field, and a hash of parameters.
        # Only the common parameters described above are recognized.
        
        def basic_integer_field(name_, opts_={})
          name_ = name_.to_sym
          field_ = @schema.field_named(name_)
          if field_.type != :integer
            raise Errors::FormatCreationError, "Type mismatch"
          end
          @nodes[name_] = Delimiter::BasicIntegerNode.new(field_, opts_)
        end
        
        
        # Specify the formatting for an integer-type field where the value
        # is formatted as a letter value, where "a" represents 1, up to
        # "z" representing 26.
        # You must pass the name of the field, and a hash of parameters.
        # In addition to the common parameters described above, the following
        # parameters are recognized:
        # 
        # <tt>:case</tt>::
        #   Case-sensitivity of the letter. Possible values are
        #   <tt>:upper</tt>, <tt>:lower</tt>, and <tt>:either</tt>.
        #   Default is <tt>:either</tt>.
        
        def alphabetic_integer_field(name_, opts_={})
          name_ = name_.to_sym
          field_ = @schema.field_named(name_)
          if field_.type != :integer
            raise Errors::FormatCreationError, "Type mismatch"
          end
          @nodes[name_] = Delimiter::AlphabeticIntegerNode.new(field_, opts_)
        end
        
        
        # Specify the formatting for a string-type field.
        # You must pass the name of the field, and a hash of parameters.
        # Only the common parameters described above are recognized.
        
        def basic_string_field(name_, opts_={})
          name_ = name_.to_sym
          field_ = @schema.field_named(name_)
          if field_.type != :string
            raise Errors::FormatCreationError, "Type mismatch"
          end
          @nodes[name_] = Delimiter::BasicStringNode.new(field_, opts_)
        end
        
        
        # Specify the formatting for a symbolic-type field.
        # You must pass the name of the field, a hash of parameters,
        # and a block defining the mapping of string patterns to
        # values.
        # Only the common parameters described above are recognized.
        # See Versionomy::Format::Delimiter::MappingSymbolBuilder for the
        # methods that can be called from the block.
        
        def mapping_symbol_field(name_, opts_={}, &block_)
          name_ = name_.to_sym
          field_ = @schema.field_named(name_)
          if field_.type != :symbol
            raise Errors::FormatCreationError, "Type mismatch"
          end
          @nodes[name_] = Delimiter::BasicSymbolNode.new(field_, opts_, &block_)
        end
        
        
        # Specify multiple possible forms for a field, which may be of
        # any type (integer, string, symbolic).
        # You must pass the name of the field, a hash of parameters,
        # and a block defining the different forms for the field.
        # The parameters are used as the default parameter values for the
        # individual forms specified in the block.
        # 
        # If the field is an integer field, the methods in
        # Versionomy::Format::Delimiter::MultiIntegerBuilder may be called
        # in the block. If the field is a string field, use the methods in
        # Versionomy::Format::Delimiter::MultiStringBuilder. Otherwise, for
        # a symbolic field use the methods in
        # Versionomy::Format::Delimiter::MultiSymbolBuilder.
        # 
        # The methods called from the block generally take the same hash
        # parameters as the corresponding methods in Builder, except that
        # they take one extra optional parameter: <tt>:form</tt>, which
        # specifies the name of the form. Normally, each method called in
        # the block specifies a separate form, but in some cases, especially
        # when defining mapping symbol parsing, you may need several calls
        # to refer to the same form. In this case, you should define a form
        # name for that form and pass it to both calls.
        
        def multi_format_field(name_, default_opts_={}, &block_)
          name_ = name_.to_sym
          field_ = @schema.field_named(name_)
          @nodes[name_] = Delimiter::MultiNode.new(field_, default_opts_, &block_)
        end
        
        
        # Set or modify the default parameters used when parsing a value.
        
        def default_parse_params(params_)
          @default_parse_params.merge!(params_)
        end
        
        
        # Set or modify the default parameters used when unparsing a value.
        
        def default_unparse_params(params_)
          @default_unparse_params.merge!(params_)
        end
        
      end
      
      
      class MultiNode  # :nodoc:
        
        def initialize(field_, default_opts_={}, &block_)
          @nodes = []
          @forms = {}
          @default_form = default_opts_.delete(:form)
          @requires_previous_field = default_opts_.fetch(:requires_previous_field, true)
          @form_unparse_param_key = "#{field_.name}_form".to_sym
          case field_.type
          when :integer
            builder_ = Delimiter::MultiIntegerBuilder.new(@nodes, @forms, field_, default_opts_)
          when :string
            builder_ = Delimiter::MultiStringBuilder.new(@nodes, @forms, field_, default_opts_)
          when :symbol
            builder_ = Delimiter::MultiSymbolBuilder.new(@nodes, @forms, field_, default_opts_)
          end
          ::Blockenspiel.invoke(block_, builder_)
          @default_form = @nodes.first[1] unless @forms[@default_form]
        end
        
        
        def requires_previous_field
          @requires_previous_field
        end
        
        
        def default_delimiters
          @forms[@default_form].first.default_delimiters
        end
        
        
        def parse(parse_params_, unparse_params_)
          previous_field_missing_ = parse_params_[:previous_field_missing]
          @nodes.each do |node_info_|
            parse_params_[:previous_field_missing] = previous_field_missing_
            value_ = node_info_[0].parse(parse_params_, unparse_params_)
            if value_
              unparse_params_[@form_unparse_param_key] = node_info_[1]
              return value_
            end
          end
          nil
        end
        
        
        def unparse(value_, unparse_params_)
          form_ = unparse_params_[@form_unparse_param_key] || @default_form
          case form_
          when ::Integer
            node_ = @nodes[form_]
            return nil unless node_
            node_.unparse(value_, unparse_params_)
          else
            nodes_ = @forms[form_]
            return nil unless nodes_
            nodes_.each do |node_|
              str_ = node_.unparse(value_, unparse_params_)
              return str_ if str_
            end
            nil
          end
        end
        
        
      end
      
      
      class MultiBuilderBase  # :nodoc:
        
        def initialize(nodes_, forms_, field_, default_opts_)  # :nodoc:
          @nodes = nodes_
          @forms = forms_
          @field = field_
          @default_opts = default_opts_
        end
        
        def _create_node(opts_)  # :nodoc:
          form_ = opts_.delete(:form) || @nodes.size
          opts_.delete(:requires_previous_field)
          node_ = yield(@field, @default_opts.merge(opts_))
          @nodes << [node_, form_]
          (@forms[form_] ||= []) << node_
        end
        
      end
      
      
      # This class defines methods that can be called from the block passed
      # to Versionomy::Filter::Builder#multi_format_field if the field is
      # of integer type.
      
      class MultiIntegerBuilder < MultiBuilderBase
        
        include ::Blockenspiel::DSL
        
        
        # Define a form which parses the field value as a number.
        # See Versionomy::Format::Delimiter::Builder#basic_integer_field
        # for more information.
        
        def basic_parser(opts_={})
          _create_node(opts_) do |field_, real_opts_|
            Delimiter::BasicIntegerNode.new(field_, real_opts_)
          end
        end
        
        
        # Define a form which parses the field value as a letter.
        # See Versionomy::Format::Delimiter::Builder#alphabetic_integer_field
        # for more information.
        
        def alphabetic_parser(opts_={})
          _create_node(opts_) do |field_, real_opts_|
            Delimiter::AlphabeticIntegerNode.new(field_, real_opts_)
          end
        end
        
        
      end
      
      
      # This class defines methods that can be called from the block passed
      # to Versionomy::Filter::Builder#multi_format_field if the field is
      # of string type.
      
      class MultiStringBuilder < MultiBuilderBase
        
        include ::Blockenspiel::DSL
        
        
        # Define a form which parses the field value as a string.
        # See Versionomy::Format::Delimiter::Builder#basic_string_field
        # for more information.
        
        def basic_parser(opts_={})
          _create_node(opts_) do |field_, real_opts_|
            Delimiter::BasicStringNode.new(field_, real_opts_)
          end
        end
        
        
      end
      
      
      # This class defines methods that can be called from the block passed
      # to Versionomy::Filter::Builder#multi_format_field if the field is
      # of symbolic type.
      
      class MultiSymbolBuilder < MultiBuilderBase
        
        include ::Blockenspiel::DSL
        
        
        # Define a form which maps string representations to values.
        # See Versionomy::Format::Delimiter::Builder#mapping_symbol_field
        # for more information.
        
        def mapping_parser(opts_={}, &block_)
          _create_node(opts_) do |field_, real_opts_|
            Delimiter::MappingSymbolNode.new(field_, real_opts_, &block_)
          end
        end
        
        
      end
      
      
      module BasicNodeMethods  # :nodoc:
        
        def setup(name_, value_regexp_, opts_)
          @required_unparse = opts_[:required_unparse]
          @regexp_options = opts_[:case_sensitive] ? nil : ::Regexp::IGNORECASE
          @value_regexp = ::Regexp.new("^(#{value_regexp_})", @regexp_options)
          regexp_ = opts_.fetch(:delimiter_regexp, '\.')
          @delimiter_regexp = regexp_.length > 0 ? ::Regexp.new("^(#{regexp_})", @regexp_options) : nil
          regexp_ = opts_.fetch(:post_delimiter_regexp, '')
          @post_delimiter_regexp = regexp_.length > 0 ? ::Regexp.new("^(#{regexp_})", @regexp_options) : nil
          regexp_ = opts_.fetch(:expected_follower_regexp, '')
          @follower_regexp = regexp_.length > 0 ? ::Regexp.new("^(#{regexp_})", @regexp_options) : nil
          @default_delimiter = opts_.fetch(:default_delimiter, '.')
          @default_post_delimiter = opts_.fetch(:default_post_delimiter, '')
          @requires_previous_field = opts_.fetch(:requires_previous_field, true)
          @delim_unparse_param_key = "#{name_}_delim".to_sym
          @post_delim_unparse_param_key = "#{name_}_postdelim".to_sym
          @optional_unparse_param_key = "#{name_}_optional".to_sym
        end
        
        
        def requires_previous_field
          @requires_previous_field
        end
        
        
        def default_delimiters
          [@default_delimiter, @default_post_delimiter]
        end
        
        
        def parse(parse_params_, unparse_params_)
          return nil if @requires_previous_field && parse_params_[:previous_field_missing]
          string_ = parse_params_[:string]
          parse_params_[:previous_field_missing] = true
          if @delimiter_regexp
            match_ = @delimiter_regexp.match(string_)
            return nil unless match_
            delim_ = match_[0]
            string_ = match_.post_match
          else
            delim_ = ''
          end
          match_ = @value_regexp.match(string_)
          return nil unless match_
          value_ = match_[0]
          string_ = match_.post_match
          if @post_delimiter_regexp
            match_ = @post_delimiter_regexp.match(string_)
            return nil unless match_
            post_delim_ = match_[0]
            string_ = match_.post_match
          else
            post_delim_ = nil
          end
          if @follower_regexp
            match_ = @follower_regexp.match(string_)
            return nil unless match_
          end
          value_ = parsed_value(value_, parse_params_, unparse_params_)
          return nil unless value_
          parse_params_[:string] = string_
          parse_params_[:previous_field_missing] = false
          unparse_params_[@delim_unparse_param_key] = delim_
          unparse_params_[@post_delim_unparse_param_key] = post_delim_ if post_delim_
          value_
        end
        
        
        def unparse(value_, unparse_params_)
          str_ = nil
          if @required_unparse || value_ != 0 || unparse_params_[:required_for_later] ||
              unparse_params_[@delim_unparse_param_key] && !unparse_params_[@optional_unparse_param_key]
          then
            str_ = unparsed_value(value_, unparse_params_)
            if str_
              str_ = (unparse_params_[@delim_unparse_param_key] || @default_delimiter) + str_ +
                (unparse_params_[@post_delim_unparse_param_key] || @default_post_delimiter)
            end
          else
            nil
          end
        end
        
      end
      
      
      class BasicIntegerNode  # :nodoc:
        
        include Delimiter::BasicNodeMethods
        
        def initialize(field_, opts_={})
          setup(field_.name, '\d+', opts_)
        end
        
        def parsed_value(value_, parse_params_, unparse_params_)
          value_.to_i
        end
        
        def unparsed_value(value_, unparse_params_)
          value_.to_s
        end
        
      end
      
      
      class AlphabeticIntegerNode  # :nodoc:
        
        include Delimiter::BasicNodeMethods
        
        def initialize(field_, opts_={})
          @case_unparse_param_key = "#{field_.name}_case".to_sym
          @case = opts_[:case]
          case @case
          when :upper
            value_regexp_ = '[A-Z]'
          when :lower
            value_regexp_ = '[a-z]'
          else #either
            value_regexp_ = '[a-zA-Z]'
          end
          setup(field_.name, value_regexp_, opts_)
        end
        
        def parsed_value(value_, parse_params_, unparse_params_)
          value_ = value_.unpack('c')[0]  # Compatible with both 1.8 and 1.9
          if value_ >= 97 && value_ <= 122
            unparse_params_[@case_unparse_param_key] = :lower
            value_ - 96
          elsif value_ >= 65 && value_ <= 90
            unparse_params_[@case_unparse_param_key] = :upper
            value_ - 64
          else
            0
          end
        end
        
        def unparsed_value(value_, unparse_params_)
          case (value_ >= 1 && value_ <= 26) ? unparse_params_[@case_unparse_param_key] : nil
          when :lower
            (value_+96).chr
          when :upper
            (value_+64).chr
          else
            value_.to_s
          end
        end
        
      end
      
      
      class BasicStringNode  # :nodoc:
        
        include Delimiter::BasicNodeMethods
        
        def initialize(field_, opts_={})
          @chars = opts_[:chars] || '[a-zA-Z0-9]'
          @length = opts_[:length]
          case @length
          when ::Integer
            length_clause_ = '{#{@length}}'
          when ::Range
            length_clause_ = '{#{@length.first},#{@length.last}}'
          when ::Array
            if @length[0] && @length[1]
              length_clause_ = '{#{@length[0]},#{@length[1]}}'
            elsif @length[0]
              length_clause_ = '{#{@length[0]},}'
            elsif @length[1]
              length_clause_ = '{,#{@length[1]}}'
            end
          else
            length_clause_ = '+'
          end
          setup(field_.name, "#{@chars}#{length_clause_}", opts_)
        end
        
        def parsed_value(value_, parse_params_, unparse_params_)
          value_
        end
        
        def unparsed_value(value_, unparse_params_)
          value_
        end
        
      end
      
      
      class MappingSymbolNode  # :nodoc:
        
        include Delimiter::BasicNodeMethods
        
        def initialize(field_, opts_={}, &block_)
          @mappings = {}
          builder_ = Delimiter::MappingSymbolBuilder.new(@mappings)
          ::Blockenspiel.invoke(block_, builder_)
          regexps_ = @mappings.values.map{ |r_| "(#{r_[0]})" }
          setup(field_.name, regexps_.join('|'), opts_)
          @mappings.each do |v_, r_|
            r_[0] = ::Regexp.new("^(#{r_[0]})", @regexp_options)
          end
        end
        
        def parsed_value(value_, parse_params, unparse_params_)
          @mappings.each do |v_, r_|
            return v_ if r_[0].match(value_)
          end
          nil
        end
        
        def unparsed_value(value_, unparse_params_)
          r_ = @mappings[value_]
          r_ ? r_[1] : nil
        end
        
      end
      
      
      # Methods in this class can be called from the block passed to either
      # Versionomy::Filter::Delimiter::Builder#mapping_symbol_field or
      # Versionomy::Filter::Delimiter::MultiSymbolBuilder##mapping_parser.
      # They define the mapping between the values of a symbolic field
      # and the string representations of those values.
      
      class MappingSymbolBuilder
        
        include ::Blockenspiel::DSL
        
        def initialize(mappings_)  # :nodoc:
          @mappings = mappings_
        end
        
        
        # Map a value to a string representation.
        # The optional regexp field, if specified, provides a regular
        # expression pattern for matching the value representation. If it
        # is omitted, the representation is used as the regexp.
        
        def map(value_, representation_, regexp_=nil)
          regexp_ ||= representation_
          @mappings[value_] = [regexp_, representation_]
        end
        
      end
      
      
      class DefaultSymbolNode < MappingSymbolNode  # :nodoc:
        
        def initialize(field_, opts_={})
          super(field_, opts_) do
            field_.possible_values.each do |v_|
              map(v_, v_.to_s)
            end
          end
        end
        
      end
      
      
    end
    
    
  end
  
end
