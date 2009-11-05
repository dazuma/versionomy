# -----------------------------------------------------------------------------
# 
# Versionomy standard format implementation
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
  
  module Conversions
    
    
    # This module contains methods that create conversions between the
    # standard and rubygems formats.
    
    module Rubygems
      
      class << self
        
        
        # Create and register the rubygems conversions.
        
        def create_and_register
          rubygems_ = Formats.get(:rubygems, true)
          standard_ = Formats.get(:standard, true)
          unless Conversions.get(standard_, rubygems_)
            conversion_ = Conversion::Parsing.new do
              to_modify_unparse_params do |params_|
                params_[:release_type_delim] = '.' if params_[:release_type_delim].to_s.length == 0
                params_[:release_type_postdelim] = '.' if params_[:release_type_postdelim].to_s.length == 0
                params_[:patchlevel_delim] = nil
                params_
              end
            end
            Conversions.register(standard_, rubygems_, conversion_)
          end
          unless Conversions.get(rubygems_, standard_)
            conversion_ = Conversion::Parsing.new do
              to_modify_string do |str_|
                str_.gsub(/[^0-9a-zA-Z\s-]+/, '.')
              end
              parse_params(:extra_characters => :error)
            end
            Conversions.register(rubygems_, standard_, conversion_)
          end
        end
        
        
      end
      
      
      create_and_register
      
    end
    
    
  end
  
end
