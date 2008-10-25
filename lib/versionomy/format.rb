# -----------------------------------------------------------------------------
# 
# Versionomy format
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
  
  
  # This module is a namespace for tools that may be used to build formatters.
  
  module Format
    
    
    # A simple base formatter.
    # 
    # Formats need not extend this base class, as long as they duck-type the
    # required methods name, parse, and unparse.
    
    class Base
      
      # Create the formatter.
      # If a block is provided, you may call methods of Versionomy::Format::Builder
      # within the block, to specify ways to parse and unparse.
      
      def initialize(name_, &block_)
        @name = name_.to_sym
        @parser = @unparser = nil
        Blockenspiel.invoke(block_, Versionomy::Format::Builder.new(self))
      end
      
      
      def _set_parser(block_)  # :nodoc:
        @parser = block_
      end
      
      def _set_unparser(block_)  # :nodoc:
        @unparser = block_
      end
      
      def _set_name(name_)  # :nodoc:
        @name = name_
      end
      
      
      # The format name
      
      def name
        @name
      end
      
      
      # A simple parse algorithm.
      # If a parser block was provided during initialization, calls that block.
      # Otherwise, attempts to parse using "." as a delimiter.
      
      def parse(schema_, string_, params_)
        if @parser
          @parser.call(schema_, string_, params_)
        else
          array_ = string_.split('.')
          Versionomy::Value.new(schema_, array_)
        end
      end
      
      
      # A simple parse algorithm.
      # If an unparser block was provided during initialization, calls that block.
      # Otherwise, attempts to unparse using "." as a delimiter.
      
      def unparse(schema_, value_, params_)
        if @unparser
          @unparser.call(schema_, value_, params_)
        else
          value_.values.join('.')
        end
      end
      
    end
    
    
    # These methods are available in an initializer block for Versionomy::Format::Base.
    
    class Builder < Blockenspiel::Base
      
      def initialize(format_)  # :nodoc:
        @format = format_
      end
      
      
      # Specify how to parse a string into a version value.
      # 
      # The block should take three parameters: a schema, a string, and a parameters hash.
      # The block should return an object of type Versionomy::Value.
      # You may raise Versionomy::Errors::ParseError if parsing failed.
      
      def to_parse(&block_)
        @format._set_parser(block_)
      end
      
      
      # Specify how to represent a version value as a string.
      # 
      # The block should take three parameters: a schema, a Versionomy::Value, and a parameters hash.
      # The block should return a string.
      # You may raise Versionomy::Errors::ParseError if unparsing failed.
      
      def to_unparse(&block_)
        @format._set_unparser(block_)
      end
      
      
      # Specify the format name
      
      def set_name(name_)
        @format._set_name(name_)
      end
      
    end
    
    
  end
  
end
