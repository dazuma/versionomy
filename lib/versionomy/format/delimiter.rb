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
    # Every field must be of the form "(pre)(value)(post)"
    # where (pre) and (post) are delimiters preceding and
    # following the value. Either or both delimiters may be the empty string.
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
    # Versionomy::Formats#_create_standard.
    
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
          @field_handlers = orig_.instance_variable_get(:@field_handlers).dup
          builder_ = Delimiter::Builder.new(@schema, @field_handlers,
            @default_parse_params, @default_unparse_params)
          ::Blockenspiel.invoke(block_, builder_)
          return
        end
        
        @schema = schema_
        @field_handlers = {}
        @default_parse_params = {}
        @default_unparse_params = {}
        builder_ = Delimiter::Builder.new(@schema, @field_handlers,
          @default_parse_params, @default_unparse_params)
        ::Blockenspiel.invoke(block_, builder_)
        @schema.names.each do |name_|
          @field_handlers[name_] ||= Delimiter::FieldHandler.new(@schema.field_named(name_), default_opts_)
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
          handler_ = @field_handlers[field_.name]
          v_ = handler_.parse(parse_params_, unparse_params_)
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
            unparse_params_["#{f_}_required".to_sym] = true
          end
        end
        fields_ = unparse_params_.delete(:optional_fields)
        if fields_
          fields_.each do |f_|
            unparse_params_["#{f_}_required".to_sym] = false
          end
        end
        string_ = ''
        value_.each_field_object do |field_, val_|
          handler_ = @field_handlers[field_.name]
          fragment_ = handler_.unparse(val_, unparse_params_)
          if fragment_
            list_ = unparse_params_.delete(:skipped_handler_list)
            if list_ && handler_.requires_previous_field && !unparse_params_[:required_for_later]
              unparse_params_[:required_for_later] = true
              list_.each do |pair_|
                frag_ = pair_[0].unparse(pair_[1], unparse_params_)
                unless frag_
                  raise Errors::UnparseError, "Field #{field_.name} empty although a prerequisite for a later field"
                end
                string_ << frag_
              end
              unparse_params_[:required_for_later] = false
            end
            string_ << fragment_
          else
            if handler_.requires_previous_field
              (unparse_params_[:skipped_handler_list] ||= []) << [handler_, val_]
            else
              unparse_params_[:skipped_handler_list] = [[handler_, val_]]
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
      # provided block. You can call methods of Versionomy::Format::Delimiter::Builder
      # in the block. Field handlers that you specify in that block will
      # override and change the field handlers from the original. Any fields
      # not specified in this block will use the handlers from the original.
      
      def modified_copy(&block_)
        Delimiter.new(self, &block_)
      end
      
      
      # This class defines methods that you can call within the DSL block
      # passed to Versionomy::Format::Delimiter#new.
      # 
      # Generally, you call the field method of this class a number of times
      # to define the formatting for each field.
      
      class Builder
        
        include ::Blockenspiel::DSL
        
        def initialize(schema_, field_handlers_, default_parse_params_, default_unparse_params_)  # :nodoc:
          @schema = schema_
          @field_handlers = field_handlers_
          @default_parse_params = default_parse_params_
          @default_unparse_params = default_unparse_params_
        end
        
        
        # Specify how to handle a given field.
        # You must pass the name of the field, a hash of options, and a
        # block defining the handling of the field.
        # 
        # Within the block, you set up "recognizers" for various regular
        # expression patterns. These recognizers are tested in order when
        # parsing a version number.
        # 
        # The methods that can be called from the block are determined by
        # the type of field. If the field is an integer field, the methods
        # of Versionomy::Format::Delimiter::IntegerFieldBuilder can be
        # called from the block. If the field is a string field, the methods
        # of Versionomy::Format::Delimiter::StringFieldBuilder can be
        # called. If the field is a symbolic field, the methods of
        # Versionomy::Format::Delimiter::SymbolFieldBuilder can be called.
        # 
        # === Options
        # 
        # The opts hash includes a number of options that control how the
        # field is parsed.
        # 
        # Some of these are regular expressions that indicate what patterns
        # are recognized by the parser. Regular expressions should be passed
        # in as the string representation of the regular expression, not a
        # Regexp object itself. For example, use the string '-' rather than
        # the Regexp /-/ to recognize a hyphen delimiter.
        # 
        # The following options are recognized:
        # 
        # <tt>:default_value_optional</tt>::
        #   If set to true, this the field may be omitted in the unparsed
        #   (formatted) version number, if the value is the default value
        #   for this field. However, if the following field is present and
        #   set as <tt>:requires_previous_field</tt>, then this field is
        #   still unparsed even if it is its default value.
        #   For example, for a version number like "2.0.0", often the third
        #   field is optional, but the first and second are required, so it
        #   will often be unparsed as "2.0".
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
        # <tt>:default_style</tt>::
        #   The default style for this field. This is the style used for
        #   unparsing if the value was not constructed by a parser or is
        #   otherwise missing the style for this field.
        # 
        # === Styles
        # 
        # A field may have different representation "styles". For example,
        # you could represent a patchlevel of 1 as "1.0-1" or "1.0a".
        # When a version number string is parsed, the parser and unparser
        # work together to remember which style was parsed, and that style
        # is used when the version number is unparsed.
        # 
        # Specify styles as options to the calls made within the block that
        # is passed to this method. In the above case, you could define the
        # patchlevel field with a block that has two calls, one that uses
        # Delimiter::IntegerFieldBuilder#recognize_number and passes the
        # option <tt>:style => :number</tt>, and another that uses
        # Delimiter::IntegerFieldBuilder#recognize_letter and passes the
        # option <tt>:style => :letter</tt>.
        # 
        # The standard format uses styles to preserve the different
        # syntaxes for the release_type field. See the source code in
        # Versionomy::Formats#_create_standard for this example.
        
        def field(name_, opts_={}, &block_)
          name_ = name_.to_sym
          field_ = @schema.field_named(name_)
          if !field_
            raise Errors::FormatCreationError, "Unknown field name #{name_.inspect}"
          end
          @field_handlers[name_] = Delimiter::FieldHandler.new(field_, opts_, &block_)
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
      
      
      # This class defines methods that can be called from the block passed
      # to Versionomy::Format::Delimiter::Builder#field if the field is
      # of integer type.
      
      class IntegerFieldBuilder
        
        include ::Blockenspiel::DSL
        
        def initialize(recognizers_, field_, default_opts_)  # :nodoc:
          @recognizers = recognizers_
          @field = field_
          @default_opts = default_opts_
        end
        
        
        # Recognize a numeric-formatted integer field.
        # Using the opts parameter, you can override any of the field's
        # overall parsing options.
        
        def recognize_number(opts_={})
          @recognizers << Delimiter::BasicIntegerRecognizer.new(@field, @default_opts.merge(opts_))
        end
        
        
        # Recognize a letter-formatted integer field. That is, the value is
        # formatted as an alphabetic letter where "a" represents 1, up to
        # "z" representing 26.
        # 
        # Using the opts parameter, you can override any of the field's
        # overall parsing options. You may also set the following additional
        # options:
        # 
        # <tt>:case</tt>::
        #   Case-sensitivity of the letter. Possible values are
        #   <tt>:upper</tt>, <tt>:lower</tt>, and <tt>:either</tt>.
        #   Default is <tt>:either</tt>.
        
        def recognize_letter(opts_={})
          @recognizers << Delimiter::AlphabeticIntegerRecognizer.new(@field, @default_opts.merge(opts_))
        end
        
      end
      
      
      # This class defines methods that can be called from the block passed
      # to Versionomy::Format::Delimiter::Builder#field if the field is
      # of string type.
      
      class StringFieldBuilder
        
        include ::Blockenspiel::DSL
        
        def initialize(recognizers_, field_, default_opts_)  # :nodoc:
          @recognizers = recognizers_
          @field = field_
          @default_opts = default_opts_
        end
        
        
        # Recognize a string field whose value matches a regular expression.
        # The regular expression must be passed as a string. E.g. use
        # "[a-z]+" instead of /[a-z]+/.
        # Using the opts parameter, you can override any of the field's
        # overall parsing options.
        
        def recognize_regexp(regexp_, opts_={})
          @recognizers << Delimiter::RegexpStringRecognizer.new(@field, regexp_, @default_opts.merge(opts_))
        end
        
      end
      
      
      # This class defines methods that can be called from the block passed
      # to Versionomy::Format::Delimiter::Builder#field if the field is
      # of symbolic type.
      
      class SymbolFieldBuilder
        
        include ::Blockenspiel::DSL
        
        def initialize(recognizers_, field_, default_opts_)  # :nodoc:
          @recognizers = recognizers_
          @field = field_
          @default_opts = default_opts_
        end
        
        
        # Recognize a symbolic value represented by a particular regular
        # expression. The regular expression must be passed as a string.
        # E.g. use "[a-z]+" instead of /[a-z]+/.
        # The "canonical" parameter indicates the canonical syntax for the
        # value, for use in unparsing.
        # 
        # Using the opts parameter, you can override any of the field's
        # overall parsing options.
        
        def recognize_regexp(value_, regexp_, canonical_, opts_={}, &block_)
          @recognizers << Delimiter::RegexpSymbolRecognizer.new(@field, value_, regexp_, canonical_, @default_opts.merge(opts_))
        end
        
        
        # Recognize a set of symbolic values, each represented by a
        # particular regular expression, but all sharing the same delimiters
        # and options. Use this instead of repeated calls to recognize_regexp
        # for better performance.
        # 
        # Using the opts parameter, you can override any of the field's
        # overall parsing options.
        # 
        # In the block, you should call methods of
        # Versionomy::Format::Delimiter::MappingSymbolBuilder to map values
        # to regular expression representations.
        
        def recognize_regexp_map(opts_={}, &block_)
          @recognizers << Delimiter::MappingSymbolRecognizer.new(@field, @default_opts.merge(opts_), &block_)
        end
        
      end
      
      
      # Methods in this class can be called from the block passed to
      # Versionomy::Format::Delimiter::SymbolFieldBuilder#recognize_regexp_map
      # to define the mapping between the values of a symbolic field and
      # the string representations of those values.
      
      class MappingSymbolBuilder
        
        include ::Blockenspiel::DSL
        
        def initialize(mappings_in_order_, mappings_by_value_)  # :nodoc:
          @mappings_in_order = mappings_in_order_
          @mappings_by_value = mappings_by_value_
        end
        
        
        # Map a value to a string representation.
        # The optional regexp field, if specified, provides a regular
        # expression pattern for matching the value representation. If it
        # is omitted, the representation is used as the regexp.
        
        def map(value_, representation_, regexp_=nil)
          regexp_ ||= representation_
          array_ = [regexp_, representation_, value_]
          @mappings_by_value[value_] ||= array_
          @mappings_in_order << array_
        end
        
      end
      
      
      class FieldHandler  # :nodoc:
        
        def initialize(field_, default_opts_={}, &block_)
          @field = field_
          @recognizers = []
          @requires_previous_field = default_opts_.fetch(:requires_previous_field, true)
          @default_style = default_opts_.fetch(:default_style, nil)
          @style_unparse_param_key = "#{field_.name}_style".to_sym
          if block_
            builder_ = case field_.type
              when :integer
                Delimiter::IntegerFieldBuilder.new(@recognizers, field_, default_opts_)
              when :string
                Delimiter::StringFieldBuilder.new(@recognizers, field_, default_opts_)
              when :symbol
                Delimiter::SymbolFieldBuilder.new(@recognizers, field_, default_opts_)
            end
            ::Blockenspiel.invoke(block_, builder_)
          end
        end
        
        
        def requires_previous_field
          @requires_previous_field
        end
        
        
        def parse(parse_params_, unparse_params_)
          previous_field_missing_ = parse_params_[:previous_field_missing]
          pair_ = nil
          @recognizers.each do |recog_|
            parse_params_[:previous_field_missing] = previous_field_missing_
            pair_ = recog_.parse(parse_params_, unparse_params_)
            break if pair_
          end
          pair_ ||= [@field.default_value, @default_style]
          if pair_[1] && pair_[1] != @default_style
            unparse_params_[@style_unparse_param_key] = pair_[1]
          end
          pair_[0]
        end
        
        
        def unparse(value_, unparse_params_)
          style_ = unparse_params_[@style_unparse_param_key] || @default_style
          @recognizers.each do |recog_|
            if recog_.should_unparse?(value_, style_)
              return recog_.unparse(value_, style_, unparse_params_)
            end
          end
          unparse_params_[:required_for_later] ? '' : nil
        end
        
      end
      
      
      class RecognizerBase  # :nodoc:
        
        def setup(field_, value_regexp_, opts_)
          @style = opts_[:style]
          @default_value_optional = opts_[:default_value_optional]
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
          name_ = field_.name
          @default_field_value = field_.default_value
          @delim_unparse_param_key = "#{name_}_delim".to_sym
          @post_delim_unparse_param_key = "#{name_}_postdelim".to_sym
          @required_unparse_param_key = "#{name_}_required".to_sym
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
          if delim_ != @default_delimiter
            unparse_params_[@delim_unparse_param_key] = delim_
          end
          if post_delim_ && post_delim_ != @default_post_delimiter
            unparse_params_[@post_delim_unparse_param_key] = post_delim_
          end
          unparse_params_[@required_unparse_param_key] = true if @default_value_optional
          [value_, @style]
        end
        
        
        def unparse(value_, style_, unparse_params_)
          str_ = nil
          if !@default_value_optional || value_ != @default_field_value ||
              unparse_params_[:required_for_later] ||
              unparse_params_[@required_unparse_param_key]
          then
            str_ = unparsed_value(value_, style_, unparse_params_)
            if str_
              delim_ = unparse_params_[@delim_unparse_param_key]
              if !delim_ || @delimiter_regexp && @delimiter_regexp !~ delim_
                delim_ = @default_delimiter
              end
              post_delim_ = unparse_params_[@post_delim_unparse_param_key]
              if !post_delim_ || @post_delimiter_regexp && @post_delimiter_regexp !~ post_delim_
                post_delim_ = @default_post_delimiter
              end
              str_ = delim_ + str_ + post_delim_
            end
            str_
          else
            nil
          end
        end
        
        
        def should_unparse?(value_, style_)
          style_ == @style
        end
        
      end
      
      
      class BasicIntegerRecognizer < RecognizerBase  #:nodoc:
        
        def initialize(field_, opts_={})
          setup(field_, '\d+', opts_)
        end
        
        def parsed_value(value_, parse_params_, unparse_params_)
          value_.to_i
        end
        
        def unparsed_value(value_, style_, unparse_params_)
          value_.to_s
        end
        
      end
      
      
      class AlphabeticIntegerRecognizer < RecognizerBase  # :nodoc:
        
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
          setup(field_, value_regexp_, opts_)
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
        
        def unparsed_value(value_, style_, unparse_params_)
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
      
      
      class RegexpStringRecognizer < RecognizerBase  # :nodoc:
        
        def initialize(field_, regexp_='[a-zA-Z0-9]+', opts_={})
          setup(field_, regexp_, opts_)
        end
        
        def parsed_value(value_, parse_params_, unparse_params_)
          value_
        end
        
        def unparsed_value(value_, style_, unparse_params_)
          value_
        end
        
      end
      
      
      class RegexpSymbolRecognizer < RecognizerBase  # :nodoc:
        
        def initialize(field_, value_, regexp_, canonical_, opts_={})
          setup(field_, regexp_, opts_)
          @value = value_
          @canonical = canonical_
        end
        
        def parsed_value(value_, parse_params, unparse_params_)
          @value
        end
        
        def unparsed_value(value_, style_, unparse_params_)
          @canonical
        end
        
        def should_unparse?(value_, style_)
          style_ == @style && value_ == @value
        end
        
      end
      
      
      class MappingSymbolRecognizer < RecognizerBase  # :nodoc:
        
        def initialize(field_, opts_={}, &block_)
          @mappings_in_order = []
          @mappings_by_value = {}
          builder_ = Delimiter::MappingSymbolBuilder.new(@mappings_in_order, @mappings_by_value)
          ::Blockenspiel.invoke(block_, builder_)
          regexps_ = @mappings_in_order.map{ |map_| "(#{map_[0]})" }
          setup(field_, regexps_.join('|'), opts_)
          @mappings_in_order.each do |map_|
            map_[0] = ::Regexp.new("^(#{map_[0]})", @regexp_options)
          end
        end
        
        def parsed_value(value_, parse_params, unparse_params_)
          @mappings_in_order.each do |map_|
            return map_[2] if map_[0].match(value_)
          end
          nil
        end
        
        def unparsed_value(value_, style_, unparse_params_)
          @mappings_by_value[value_][1]
        end
        
        def should_unparse?(value_, style_)
          style_ == @style && @mappings_by_value.include?(value_)
        end
        
      end
      
      
    end
    
    
  end
  
end
