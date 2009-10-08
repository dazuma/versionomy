# -----------------------------------------------------------------------------
# 
# Versionomy convenience interface
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


# == Versionomy
# 
# The Versionomy module contains some convenience methods for creating and
# parsing version numbers.

module Versionomy
  
  @default_format = nil
  
  
  class << self
    
    
    # Gets the current default format.
    # Usually this is the "standard" format returned by Versionomy::Format.standard.
    
    def default_format
      @default_format ||= Format.standard
    end
    
    
    # Sets the default format.
    # Usually this should be left as the "standard" format returned by
    # Versionomy::Format.standard. To reset to that value, pass nil.
    
    def default_format=(format_)
      @default_format = format_
    end
    
    
    # Create a new version number given a hash or array of values, and an
    # optional format.
    # 
    # The values should either be a hash of field names and values, or an array
    # of values that will be interpreted in field order.
    # 
    # If the format is omitted or set to nil, the default_format will be used.
    # 
    # You can also optionally provide default unparsing parameters for the value.
    
    def create(values_=[], format_=nil, unparse_params_=nil)
      Value.new(values_, format_ || default_format, unparse_params_)
    end
    
    
    # Create a new version number given a string to parse, and an optional format.
    # 
    # If the format is omitted or set to nil, the default_format will be used.
    # 
    # The params, if present, will be passed as parsing parameters to the format.
    
    def parse(str_, format_=nil, parse_params_=nil)
      (format_ || default_format).parse(str_, parse_params_)
    end
    
  end
  
end
