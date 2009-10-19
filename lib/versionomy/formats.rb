# -----------------------------------------------------------------------------
# 
# Versionomy format module
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
  
  
  # === Version number format regsitry.
  # 
  # Use the methods of this module to register formats with a name. This
  # allows version numbers to be serialized with their format.
  # 
  # You may also access predefined formats such as the standard format from
  # this module. It also contains the implementations of these formats as
  # examples.
  
  module Formats
    
    
    @names = ::Hash.new
    
    
    # Get the format with the given name.
    # 
    # If the given name has not been defined, and strict is set to true,
    # raises Versionomy::Errors::UnknownFormatError. If strict is set to
    # false, returns nil if the given name has not been defined.
    
    def self.get(name_, strict_=false)
      format_ = @names[name_.to_s]
      if format_.nil? && strict_
        raise Errors::UnknownFormatError, name_
      end
      format_
    end
    
    
    # Register the given format under the given name.
    # 
    # Raises Versionomy::Errors::FormatRedefinedError if the name has
    # already been defined.
    
    def self.register(name_, format_)
      name_ = name_.to_s
      if @names.include?(name_)
        raise Errors::FormatRedefinedError, name_
      end
      @names[name_] = format_
    end
    
    
  end
  
  
end
