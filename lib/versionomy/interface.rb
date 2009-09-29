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
  
  @default_schema = nil
  @default_format = nil
  
  
  class << self
    
    
    # Gets the current default schema.
    # Usually this is Versionomy::Schemas::Standard.schema.
    
    def default_schema
      @default_schema ||= Versionomy::Schemas::Standard.schema
    end
    
    
    # Sets the default schema.
    # Usually this should be left as Versionomy::Schemas::Standard.schema.
    # To reset to this value, pass nil.
    
    def default_schema=(schema_)
      @default_schema = schema_
    end
    
    
    # Gets the current default format.
    # Usually this is Versionomy::Schemas::Standard.default_format.
    
    def default_format
      @default_format ||= Versionomy::Schemas::Standard.default_format
    end
    
    
    # Sets the default format.
    # Usually this should be left as Versionomy::Schemas::Standard.default_format.
    # To reset to this value, pass nil.
    
    def default_format=(format_)
      @default_format = format_
    end
    
    
    # Create a new version number given a hash or array of values, and an
    # optional schema.
    # 
    # The values should either be a hash of field names and values, or an array
    # of values that will be interpreted in field order.
    # 
    # If schema is omitted, the default_schema will be used.
    
    def create(values_=[], schema_=nil)
      (schema_ || default_schema).create(values_)
    end
    
    
    # Create a new version number given a string to parse, and an optional format.
    # 
    # If format is omitted or set to nil, the default_format will be used.
    # 
    # The params, if present, will be passed as parsing parameters to the format.
    
    def parse(str_, format_=nil, params_=nil)
      (format_ || default_format).parse(str_, params_)
    end
    
  end
  
end
