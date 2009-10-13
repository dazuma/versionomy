# -----------------------------------------------------------------------------
# 
# Versionomy format base class
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
    
    
    # The base format.
    # 
    # This format doesn't actually do anything useful. It causes all strings
    # to parse to the schema's default value, and unparses all values to the
    # empty string.
    # 
    # Instead, the purpose here is to define the API for a format. All
    # formats must define the methods +schema+, +parse+, and +unparse+.
    # Formats need not extend this base class, as long as they duck-type
    # these methods.
    
    class Base
      
      
      # Create an instance of this base format, with the given schema.
      
      def initialize(schema_)
        @schema = schema_
      end
      
      
      # Returns the schema understood by this format.
      
      def schema
        @schema
      end
      
      
      # Parse the given string and return a value.
      # The optional parameter hash can be used to pass parameters to the
      # parser to affect its behavior. The exact parameters supported are
      # defined by the format.
      
      def parse(string_, parse_params_=nil)
        Value.new([], self)
      end
      
      
      # Unparse the given value and return a string.
      # The optional parameter hash can be used to pass parameters to the
      # unparser to affect its behavior. The exact parameters supported
      # are defined by the format.
      
      def unparse(value_, unparse_params_=nil)
        ''
      end
      
      
    end
    
    
  end
  
end
