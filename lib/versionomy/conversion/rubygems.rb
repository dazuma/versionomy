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
  
  module Conversion
    
    
    # This is a namespace for the implementation of the conversion between
    # the rubygems and standard formats.
    
    module Rubygems
      
      
      # Create the conversion from standard to rubygems format.
      # This method is called internally when Versionomy initializes itself,
      # and you should not need to call it again. It is documented, however,
      # so that you can inspect its source code from RDoc, since the source
      # contains useful examples of how to use the conversion DSLs.
      
      def self.create_standard_to_rubygems
        
        # We'll use a parsing conversion.
        Conversion::Parsing.new do
          
          # We're going to modify how the standard format version is
          # unparsed, so the rubygems format will have a better chance
          # of parsing it.
          to_modify_unparse_params do |params_, convert_params_|
            
            params_ ||= {}
            
            # If the standard format version has a prerelease notation,
            # make sure it is set off using a delimiter that the rubygems
            # format can recognize. So instead of "1.0b2", we force the
            # unparsing to generate "1.0.b.2".
            params_[:release_type_delim] = '.'
            params_[:development_version_delim] = '.'
            params_[:alpha_version_delim] = '.'
            params_[:beta_version_delim] = '.'
            params_[:release_candidate_version_delim] = '.'
            params_[:preview_version_delim] = '.'
            
            # If the standard format version has a patchlevel notation,
            # force it to use the default number rather than letter style.
            # So instead of "1.2c", we force the unparsing to generate
            # "1.2-3".
            params_[:patchlevel_style] = nil
            
            # If the standard format version has a patchlevel notation,
            # force it to use the default delimiter of "-" so the rubygems
            # format will recognize it. So instead of "1.9.1p243", we force
            # the unparsing to generate "1.9.1-243".
            params_[:patchlevel_delim] = nil
            
            params_
          end
          
          # Standard formats sometimes allow hyphens and spaces in field
          # delimiters, but the rubygems format requires periods. So modify
          # the unparsed string to conform to rubygems's expectations.
          to_modify_string do |str_, convert_params_|
            str_.gsub(/[\.\s-]+/, '.')
          end
          
        end
        
      end
      
      
      # Create the conversion from rubygems to standard format.
      # This method is called internally when Versionomy initializes itself,
      # and you should not need to call it again. It is documented, however,
      # so that you can inspect its source code from RDoc, since the source
      # contains useful examples of how to use the conversion DSLs.
      
      def self.create_rubygems_to_standard
        
        # We'll use a parsing conversion.
        Conversion::Parsing.new do
          
          # Handle the case where the rubygems version ends with a string
          # field, e.g. "1.0.b". We want to treat this like "1.0b0" rather
          # than "1.0-2" since the rubygems semantic states that this is a
          # prerelease version. So we add 0 to the end of the parsed string
          # if it ends in a letter.
          to_modify_string do |str_, convert_params_|
            str_.gsub(/([[:alpha:]])\z/, '\10')
          end
          
        end
        
      end
      
      
      unless Conversion.get(:standard, :rubygems)
        Conversion.register(:standard, :rubygems, create_standard_to_rubygems)
      end
      unless Conversion.get(:rubygems, :standard)
        Conversion.register(:rubygems, :standard, create_rubygems_to_standard)
      end
      
      
    end
    
    
  end
  
end
