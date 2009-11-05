# -----------------------------------------------------------------------------
# 
# Versionomy conversion base class
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
  
  
  module Conversion
    
    
    # A conversion strategy that relies on parsing.
    # Essentially, it unparses the value and then attempts to parse it with
    # the new format.
    
    class Parsing
      
      
      # Create an instance of this base conversion, with the given from and
      # to schemas.
      
      def initialize(opts_={}, &block_)
        @parse_params = opts_[:parse_params]
        if block_
          builder_ = Builder.new
          ::Blockenspiel.invoke(block_, builder_)
          @string_modifier = builder_._get_string_modifier
          @unparse_params_modifier = builder_._get_unparse_params_modifier
          @parse_params ||= builder_._get_parse_params
        end
      end
      
      
      # Convert the given value. The value must match the from_schema.
      # Returns an equivalent value in the to_schema.
      # 
      # Raises Versionomy::Errors::ConversionError if the conversion failed.
      
      def convert_value(value_, format_, convert_params_=nil)
        begin
          unparse_params_ = value_.unparse_params
          if @unparse_params_modifier
            unparse_params_ = @unparse_params_modifier.call(unparse_params_)
          end
          string_ = value_.unparse(unparse_params_)
          if @string_modifier
            string_ = @string_modifier.call(string_)
          end
          new_value_ = format_.parse(string_, @parse_params)
          return new_value_
        rescue Errors::UnparseError => ex_
          raise Errors::ConversionError, "Unparsing failed: #{ex_.inspect}"
        rescue Errors::ParseError => ex_
          raise Errors::ConversionError, "Parsing failed: #{ex_.inspect}"
        end
      end
      
      
      class Builder
        
        include ::Blockenspiel::DSL
        
        
        def initialize
          @string_modifier = nil
          @parse_params = nil
          @unparse_params_modifier = nil
        end
        
        
        def parse_params(params_)
          @parse_params = params_
        end
        
        
        def to_modify_string(&block_)
          @string_modifier = block_
        end
        
        
        def to_modify_unparse_params(&block_)
          @unparse_params_modifier = block_
        end
        
        
        def _get_string_modifier  # :nodoc:
          @string_modifier
        end
        
        def _get_unparse_params_modifier  # :nodoc:
          @unparse_params_modifier
        end
        
        def _get_parse_params  # :nodoc:
          @parse_params
        end
        
      end
      
      
    end
    
    
  end
  
end
