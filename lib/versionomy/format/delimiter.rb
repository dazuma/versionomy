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
    
    
    # A delimiter-based format
    
    class Delimiter
      
      
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
      
      
      def schema
        @schema
      end
      
      
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
      
      
      def default_parse_params
        @default_parse_params.dup
      end
      
      
      def default_unparse_params
        @default_unparse_params.dup
      end
      
      
      def modified_copy(&block_)
        Delimiter.new(self, &block_)
      end
      
      
      class Builder
        
        include ::Blockenspiel::DSL
        
        def initialize(schema_, nodes_, default_parse_params_, default_unparse_params_)
          @schema = schema_
          @nodes = nodes_
          @default_parse_params = default_parse_params_
          @default_unparse_params = default_unparse_params_
        end
        
        
        def basic_integer_field(name_, opts_={})
          name_ = name_.to_sym
          field_ = @schema.field_named(name_)
          if field_.type != :integer
            raise Errors::FormatCreationError, "Type mismatch"
          end
          @nodes[name_] = Delimiter::BasicIntegerNode.new(field_, opts_)
        end
        
        
        def basic_string_field(name_, opts_={})
          name_ = name_.to_sym
          field_ = @schema.field_named(name_)
          if field_.type != :string
            raise Errors::FormatCreationError, "Type mismatch"
          end
          @nodes[name_] = Delimiter::BasicStringNode.new(field_, opts_)
        end
        
        
        def basic_symbol_field(name_, opts_={}, &block_)
          name_ = name_.to_sym
          field_ = @schema.field_named(name_)
          if field_.type != :symbol
            raise Errors::FormatCreationError, "Type mismatch"
          end
          @nodes[name_] = Delimiter::BasicSymbolNode.new(field_, opts_, &block_)
        end
        
        
        def multi_format_field(name_, default_opts_={}, &block_)
          name_ = name_.to_sym
          field_ = @schema.field_named(name_)
          @nodes[name_] = Delimiter::MultiNode.new(field_, default_opts_, &block_)
        end
        
        
        def default_parse_params(params_)
          @default_parse_params.merge!(params_)
        end
        
        
        def default_unparse_params(params_)
          @default_unparse_params.merge!(params_)
        end
        
      end
      
      
      class MultiNode
        
        def initialize(field_, default_opts_={}, &block_)
          @nodes = []
          @forms = {}
          @default_form = default_opts_.delete(:form)
          @requires_previous_field = default_opts_.fetch(:requires_previous_field, true)
          @form_unparse_param_key = "#{field_.name}_form".to_sym
          case field_.type
          when :integer
            builder_ = Delimiter::MultiNode::IntegerBuilder.new(@nodes, @forms, field_, default_opts_)
          when :string
            builder_ = Delimiter::MultiNode::StringBuilder.new(@nodes, @forms, field_, default_opts_)
          when :symbol
            builder_ = Delimiter::MultiNode::SymbolBuilder.new(@nodes, @forms, field_, default_opts_)
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
        
        
        class BuilderBase  # :nodoc:
          
          def initialize(nodes_, forms_, field_, default_opts_)
            @nodes = nodes_
            @forms = forms_
            @field = field_
            @default_opts = default_opts_
          end
          
          def _create_node(opts_)
            form_ = opts_.delete(:form) || @nodes.size
            opts_.delete(:requires_previous_field)
            node_ = yield(@field, @default_opts.merge(opts_))
            @nodes << [node_, form_]
            (@forms[form_] ||= []) << node_
          end
          
        end
        
        
        class IntegerBuilder < BuilderBase
          
          include ::Blockenspiel::DSL
          
          def basic_parser(opts_={})
            _create_node(opts_) do |field_, real_opts_|
              Delimiter::BasicIntegerNode.new(field_, real_opts_)
            end
          end
          
          def alphabetic_parser(opts_={})
            _create_node(opts_) do |field_, real_opts_|
              Delimiter::AlphabeticIntegerNode.new(field_, real_opts_)
            end
          end
          
        end
        
        
        class StringBuilder < BuilderBase
          
          include ::Blockenspiel::DSL
          
          def basic_parser(opts_={})
            _create_node(opts_) do |field_, real_opts_|
              Delimiter::BasicStringNode.new(field_, real_opts_)
            end
          end
          
        end
        
        
        class SymbolBuilder < BuilderBase
          
          include ::Blockenspiel::DSL
          
          def mapping_parser(opts_={}, &block_)
            _create_node(opts_) do |field_, real_opts_|
              Delimiter::MappingSymbolNode.new(field_, real_opts_, &block_)
            end
          end
          
        end
        
        
      end
      
      
      module BasicNodeMethods
        
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
      
      
      class BasicIntegerNode
        
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
      
      
      class AlphabeticIntegerNode
        
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
      
      
      class BasicStringNode
        
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
      
      
      class MappingSymbolNode
        
        include Delimiter::BasicNodeMethods
        
        def initialize(field_, opts_={}, &block_)
          @mappings = {}
          builder_ = Delimiter::MappingSymbolNode::Builder.new(@mappings)
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
        
        
        class Builder
          
          include ::Blockenspiel::DSL
          
          def initialize(mappings_)
            @mappings = mappings_
          end
          
          
          def map(value_, representation_, regexp_=nil)
            regexp_ ||= representation_
            @mappings[value_] = [regexp_, representation_]
          end
          
        end
        
      end
      
      
      class DefaultSymbolNode < MappingSymbolNode
        
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
