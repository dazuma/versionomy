# -----------------------------------------------------------------------------
# 
# Versionomy schema
# 
# -----------------------------------------------------------------------------
# Copyright 2008 Daniel Azuma
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
  
  
  # === Version number schema.
  # 
  # A schema is a set of field specifications that specify how a version
  # number is structured. Each field has a name, a type, an initial value,
  # and other properties.
  # 
  # Schema fields may be integer-valued, string-valued, or symbolic.
  # Symbolic fields are useful, for example, if you want a field to specify
  # the type of prerelease (e.g. "alpha", "beta", or "release candidate").
  # 
  # The Schema object itself actually represents only a single field, the
  # "most significant" field. The next most significant field is specified
  # by a child of this object, the next by a child of that child, and so
  # forth down the line. You could therefore think of a simple schema as a
  # chain of cons-cells.
  # 
  # For example, you could construct a schema for versions numbers of
  # the form "major.minor.tiny" like this:
  # 
  #  Schema(major) -> Schema(minor) -> Schema(tiny) -> nil
  # 
  # Some schemas may be more complex than that, however. It is possible for
  # the form of a schema's child to depend on the value of the field.
  # For example, suppose we wanted a schema in which if the value of the
  # "minor" field is 0, then the "tiny" field doesn't exist. It's possible
  # to construct a schema of this form:
  # 
  #  Schema(major) -> Schema(minor) -> [value == 0] : nil
  #                                    [otherwise]  : Schema(tiny) -> nil
  
  class Schema
    
    
    # Create a version number schema, with the given field name.
    # 
    # Recognized options include:
    # 
    # <tt>:type</tt>::
    #   Type of field. This should be <tt>:integer</tt>, <tt>:string</tt>, or <tt>:symbol</tt>.
    #   Default is <tt>:integer</tt>.
    # <tt>:initial</tt>::
    #   Initial value. Default is 0 for an integer field, the empty string for a string field,
    #   or the first symbol added for a symbol field.
    # 
    # You may provide an optional block. Within the block, you may call methods of
    # Versionomy::Schema::Builder to further customize the field, or add subschemas.
    # 
    # Raises Versionomy::Errors::IllegalValueError if the given initial value is not legal.
    
    def initialize(name_, opts_={}, &block_)
      @name = name_.to_sym
      @type = opts_[:type] || :integer
      @initial_value = opts_[:initial]
      @symbol_info = nil
      @symbol_order = nil
      if @type == :symbol
        @symbol_info = Hash.new
        @symbol_order = Array.new
      end
      @bump_proc = nil
      @compare_proc = nil
      @canonicalize_proc = nil
      @ranges = nil
      @default_subschema = nil
      @formats = Hash.new
      @default_format_name = nil
      Blockenspiel.invoke(block_, Versionomy::Schema::Builder.new(self)) if block_
      @initial_value = canonicalize_value(@initial_value)
    end
    
    
    def _set_initial_value(value_)  # :nodoc:
      @initial_value = value_
    end
    
    def _add_symbol(symbol_, opts_={})  # :nodoc:
      if @type != :symbol
        raise Versionomy::Errors::TypeMismatchError
      end
      if @symbol_info.has_key?(symbol_)
        raise Versionomy::Errors::SymbolRedefinedError
      end
      @symbol_info[symbol_] = [@symbol_order.size, opts_[:bump]]
      @symbol_order << symbol_
      if @initial_value.nil?
        @initial_value = symbol_
      end
    end
    
    def _set_bump_proc(block_)  # :nodoc:
      @bump_proc = block_
    end
    
    def _set_canonicalize_proc(block_)  # :nodoc:
      @canonicalize_proc = block_
    end
    
    def _set_compare_proc(block_)  # :nodoc:
      @compare_proc = block_
    end
    
    
    def inspect   # :nodoc:
      to_s
    end
    
    def to_s   # :nodoc:
      "#<#{self.class}:0x#{object_id.to_s(16)} name=#{@name}>"
    end
    
    
    # The name of the field.
    
    def name
      @name
    end
    
    
    # The type of the field.
    # Possible values are <tt>:integer</tt>, <tt>:string</tt>, or <tt>:symbol</tt>.
    
    def type
      @type
    end
    
    
    # The initial value of the field
    
    def initial_value
      @initial_value
    end
    
    
    # Given a value, bump it to the "next" value.
    # Utilizes a bump procedure if given;
    # otherwise uses default behavior depending on the type.
    
    def bump_value(value_)
      if @bump_proc
        nvalue_ = @bump_proc.call(value_)
        nvalue_ || value_
      elsif @type == :integer || @type == :string
        value_.next
      else
        info_ = @symbol_info[value_]
        info_ ? info_[1] || value_ : nil
      end
    end
    
    
    # Perform a standard comparison on two values.
    # Returns an integer that may be positive, negative, or 0.
    # Utilizes a comparison procedure if given;
    # otherwise uses default behavior depending on the type.
    
    def compare_values(val1_, val2_)
      if @compare_proc
        @compare_proc.call(val1_, val2_)
      elsif @type == :integer || @type == :string
        val1_ <=> val2_
      else
        info1_ = @symbol_info[val1_]
        info2_ = @symbol_info[val2_]
        info1_ && info2_ ? info1_[0] <=> info2_[0] : nil
      end
    end
    
    
    # Given a value, return a "canonical" value for this field.
    # Utilizes a canonicalization procedure if given;
    # otherwise uses default behavior depending on the type.
    # 
    # Raises Versionomy::Errors::IllegalValueError if the given value is not legal.
    
    def canonicalize_value(value_)
      if @canonicalize_proc
        value_ = @canonicalize_proc.call(value_)
      else
        case @type
        when :integer
          value_ = value_.to_i
        when :string
          value_ = value_.to_s
        when :symbol
          value_ = value_.to_sym
        end
      end
      if value_.nil? || (@type == :symbol && !@symbol_info.has_key?(value_))
        raise Versionomy::Errors::IllegalValueError
      end
      value_
    end
    
    
    # Define a format for this schema.
    # 
    # You may either:
    # 
    # * pass a format, or
    # * pass a name and provide a block that calls methods in
    #   Versionomy::Format::Builder.
    
    def define_format(format_=nil, &block_)
      format_ = Versionomy::Format::Base.new(format_, &block_) if block_
      @formats[format_.name] = format_
      @default_format_name ||= format_.name
    end
    
    
    # Get the formatter with the given name.
    # If the name is nil, returns the default formatter.
    # If the name is not recognized, returns nil.
    
    def get_format(name_)
      @formats[name_ || @default_format_name]
    end
    
    
    # Returns the current default format name.
    
    def default_format_name
      @default_format_name
    end
    
    
    # Sets the default format by name.
    
    def default_format_name=(name_)
      if @formats[name_]
        @default_format_name = name_
      else
        nil
      end
    end
    
    
    # Create a new value with this schema.
    # 
    # The values should either be a hash of field names and values, or an array
    # of values that will be interpreted in field order.
    
    def create(values_=nil)
      Versionomy::Value._new(self, values_)
    end
    
    
    # Create a new value by parsing the given string.
    # 
    # The optional parameters may include a <tt>:format</tt> parameter that
    # specifies a format name. If no format is specified, the default format is used.
    # The remaining parameters are passed into the formatter's parse method.
    # 
    # Raises Versionomy::Errors::UnknownFormatError if the given format name is not recognized.
    # 
    # Raises Versionomy::Errors::ParseError if parsing failed.
    
    def parse(str_, params_={})
      format_ = get_format(params_[:format])
      if format_.nil?
        raise Versionomy::Errors::UnknownFormatError
      end
      value_ = format_.parse(self, str_, params_)
    end
    
    
    # Returns the subschema associated with the given value.
    
    def _subschema(value_)  # :nodoc:
      if @ranges
        @ranges.each do |r_|
          if !r_[0].nil?
            cmp_ = compare_values(r_[0], value_)
            next if cmp_.nil? || cmp_ > 0
          end
          if !r_[1].nil?
            cmp_ = compare_values(r_[1], value_)
            next if cmp_.nil? || cmp_ < 0
          end
          return r_[2]
        end
      end
      @default_subschema
    end
    
    
    # Appends the given subschema for the given range
    
    def _append_schema(schema_, ranges_=nil)  # :nodoc:
      if ranges_.nil?
        if @default_subschema
          raise Versionomy::Errors::RangeOverlapError
        end
        @default_subschema = schema_
        return
      end
      if !ranges_.is_a?(Array) || range_.size == 2 &&
          (range_[0].nil? || range_[0].is_a?(Symbol) ||
           range_[0].kind_of?(Integer) || range_[0].is_a?(String)) &&
          (range_[1].nil? || range_[1].is_a?(Symbol) ||
           range_[1].kind_of?(Integer) || range_[1].is_a?(String))
      then
        ranges_ = [ranges_]
      else
        ranges_ = ranges_.dup
      end
      ranges_.each do |range_|
        normalized_range_ = nil
        if range_.kind_of?(Array) && range_.size != 2
          raise Versionomy::Errors::RangeSpecificationError
        end
        case @type
        when :integer
          case range_
          when Array
            normalized_range_ = range_.map{ |elem_| elem_.nil? ? nil : elem_.to_i }
          when Range
            normalized_range_ = [range_.first, range_.exclude_end? ? range_.last-1 : range_.last]
          when String, Symbol, Integer
            range_ = range_.to_i
            normalized_range_ = [range_, range_]
          else
            raise Versionomy::Errors::RangeSpecificationError
          end
        when :string
          case range_
          when Array
             normalized_range_ = range_.map{ |elem_| elem_.nil? ? nil : elem_.to_s }
          when Range
            normalized_range_ = [range_.first.to_s,
                                 range_.exclude_end? ? (range_.last-1).to_s : range_.last.to_s]
          else
            range_ = range_.to_s
            normalized_range_ = [range_, range_]
          end
        when :symbol
          case range_
          when Array
            normalized_range_ = range_.map do |elem_|
              case elem_
              when nil
                nil
              when Integer
                elem_.to_s.to_sym
              else
                elem_.to_sym
              end
            end
          when String, Integer
            range_ = range_.to_s.to_sym
            normalized_range_ = [range_, range_]
          when Symbol
            normalized_range_ = [range_, range_]
          else
            raise Versionomy::Errors::RangeSpecificationError
          end
        end
        normalized_range_ << schema_
        @ranges ||= Array.new
        insert_index_ = @ranges.size
        @ranges.each_with_index do |r_, i_|
          if normalized_range_[0] && r_[1]
            cmp_ = compare_values(normalized_range_[0], r_[1])
            if cmp_.nil?
              raise Versionomy::Errors::RangeSpecificationError
            end
            if cmp_ > 0
              next
            end
          end
          if normalized_range_[1] && r_[0]
            cmp_ = compare_values(normalized_range_[1], r_[0])
            if cmp_.nil?
              raise Versionomy::Errors::RangeSpecificationError
            end
            if cmp_ < 0
              insert_index_ = i_
              break
            end
          end
          raise Versionomy::Errors::RangeOverlapError
        end
        @ranges.insert(insert_index_, normalized_range_)
      end
    end
    
    
    # These methods are available in a schema definition block.
    
    class Builder
      
      include Blockenspiel::DSL
      
      def initialize(schema_)  # :nodoc:
        @schema = schema_
      end
      
      
      # Define the given symbol.
      # 
      # Recognized options include:
      # 
      # <tt>:bump</tt>::
      #   The symbol to transition to when "bump" is called.
      #   Default is to remain on the same value.
      # 
      # Raises Versionomy::Errors::TypeMismatchError if called when the current schema
      # is not of type <tt>:symbol</tt>.
      # 
      # Raises Versionomy::Errors::SymbolRedefinedError if the given symbol name is
      # already defined.
      
      def symbol(symbol_, opts_={})
        @schema._add_symbol(symbol_, opts_)
      end
      
      
      # Provide an initial value.
      
      def initial_value(value_)
        @schema._set_initial_value(value_)
      end
      
      
      # Provide a "bump" procedure.
      # The given block should take a value, and return the value to transition to.
      # If you return nil, the value will remain the same.
      
      def to_bump(&block_)
        @schema._set_bump_proc(block_)
      end
      
      
      # Provide a "compare" procedure.
      # The given block should take two values and compare them.
      # It should return a negative integer if the first is less than the second,
      # a positive integer if the first is greater than the second, or 0 if the
      # two values are equal. If the values cannot be compared, return nil.
      
      def to_compare(&block_)
        @schema._set_compare_proc(block_)
      end
      
      
      # Provide a "canonicalize" procedure.
      # The given block should take a value and return a canonicalized value.
      # Return nil if the given value is illegal.
      
      def to_canonicalize(&block_)
        @schema._set_canonicalize_proc(block_)
      end
      
      
      # Add a subschema.
      # 
      # Recognized options include:
      # 
      # <tt>:only</tt>::
      #   This subschema should be available only for the given values of this schema.
      #   See below for ways to specify this constraint.
      # <tt>:type</tt>::
      #   Type of field. This should be <tt>:integer</tt>, <tt>:string</tt>, or <tt>:symbol</tt>.
      #   Default is <tt>:integer</tt>.
      # <tt>:initial</tt>::
      #   Initial value. Default is 0 for an integer field, the empty string for a string field,
      #   or the first symbol added for a symbol field.
      # 
      # You may provide an optional block. Within the block, you may call methods of this
      # class again to customize the subschema.
      # 
      # Raises Versionomy::Errors::IllegalValueError if the given initial value is not legal.
      # 
      # The <tt>:only</tt> constraint may be specified in one of the following ways:
      # 
      # * A single value (integer, string, or symbol)
      # * A Range object defining a range of integers
      # * A two-element array indicating a range of integers, strings, or symbols, inclusive.
      #   In this case, the ordering of symbols is defined by the order in which the symbols
      #   were added to this schema.
      #   If either element is nil, it is considered an open end of the range.
      # * An array of arrays in the above form.
      
      def schema(name_, opts_={}, &block_)
        @schema._append_schema(Versionomy::Schema.new(name_, opts_, &block_), opts_.delete(:only))
      end
      
      
      # Define a format for this schema.
      # 
      # You may either:
      # 
      # * pass a format, or
      # * pass a name and provide a block that calls methods in
      #   Versionomy::Format::Builder.
      
      def define_format(format_=nil, &block_)
        @schema.define_format(format_, &block_)
      end
      
      
      # Sets the default format by name.
      
      def set_default_format_name(name_)
        @schema.default_format_name = name_
      end
      
      
    end
    
    
  end
  
end
