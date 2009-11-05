# -----------------------------------------------------------------------------
# 
# Versionomy conversion interface and registry
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
  
  
  # === Version number conversions regsitry.
  # 
  # Use the methods of this module to register conversions with Versionomy.
  # 
  # This module also serves as a convenient namespace for implementations
  # of conversions.
  
  module Conversions
    
    @registry = ::Hash.new
    
    class << self
      
      
      # Get a conversion capable of converting between the given schemas.
      # Returns nil if no such conversion could be found.
      
      def get(from_schema_, to_schema_, strict_=false)
        key_ = _get_key(from_schema_, to_schema_)
        conversion_ = @registry[key_]
        if strict_ && conversion_.nil?
          raise Errors::UnknownConversionError
        end
        conversion_
      end
      
      
      # Register the given conversion.
      # 
      # Raises Versionomy::Errors::ConversionRedefinedError if a conversion
      # has already been registered for the given schemas.
      
      def register(from_schema_, to_schema_, conversion_)
        key_ = _get_key(from_schema_, to_schema_)
        if @registry.include?(key_)
          raise Errors::ConversionRedefinedError
        end
        @registry[key_] = conversion_
      end
      
      
      private
      
      def _get_key(from_schema_, to_schema_)  # :nodoc:
        [_get_schema(from_schema_), _get_schema(to_schema_)]
      end
      
      def _get_schema(schema_)  # :nodoc:
        schema_ = Formats.get(schema_, true) if schema_.kind_of?(::String) || schema_.kind_of?(::Symbol)
        schema_ = schema_.schema if schema_.respond_to?(:schema)
        schema_ = schema_.root_field if schema_.respond_to?(:root_field)
        schema_
      end
      
      
    end
    
  end
  
  
end
