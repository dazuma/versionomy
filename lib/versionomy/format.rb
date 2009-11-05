# -----------------------------------------------------------------------------
# 
# Versionomy format namespace
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
  
  
  # === Version number format.
  # 
  # A format controls the parsing and unparsing of a version number.
  # Any time a version number is parsed from a string, a format is provided
  # to parse it. Similarly, every version number value references a format
  # that is used to unparse it back into a string.
  # 
  # A format is always tied to a particular schema and knows how to parse
  # only that schema's version numbers.
  # 
  # Under many circumstances, you should use the standard format, which
  # can be retrieved by calling Versionomy::Format#standard. This format
  # understands most common version numbers, including prerelease
  # (e.g. alpha, beta, release candidate, etc.) forms and patchlevels.
  # 
  # You may also create your own formats, either by implementing the
  # format contract (see Versionomy::Format::Base) or by using the
  # Versionomy::Format::Delimiter tool, which can be used to construct
  # parsers for many version number formats.
  # 
  # Formats may be registered with Versionomy and given a name using the
  # methods of this module. This allows version numbers to be serialized
  # with their format.
  # 
  # Finally, this module serves as a namespace for format implementations.
  
  module Format
    
    @names_to_formats = ::Hash.new
    @formats_to_names = ::Hash.new
    
    class << self
      
      
      # Get the format with the given name.
      # 
      # If the given name has not been defined, and strict is set to true,
      # raises Versionomy::Errors::UnknownFormatError. If strict is set to
      # false, returns nil if the given name has not been defined.
      
      def get(name_, strict_=false)
        format_ = @names_to_formats[name_.to_s]
        if format_.nil? && strict_
          raise Errors::UnknownFormatError, name_
        end
        format_
      end
      
      
      # Register the given format under the given name.
      # 
      # Raises Versionomy::Errors::FormatRedefinedError if the name has
      # already been defined.
      
      def register(name_, format_)
        name_ = name_.to_s
        if @names_to_formats.include?(name_)
          raise Errors::FormatRedefinedError, name_
        end
        @names_to_formats[name_] = format_
        @formats_to_names[format_.object_id] = name_
      end
      
      
      # Get the canonical name for the given format, as a string.
      # This is the first name the format was registered under.
      # Returns nil if this format was never registered.
      
      def canonical_name_for(format_)
        @formats_to_names[format_.object_id]
      end
      
      
    end
    
  end
  
  
  # Versionomy::Formats is an alias for Versionomy::Format, for backward
  # compatibility with version 0.1.0 code. It is deprecated; use
  # Versionomy::Format instead.
  Formats = Format
  
  
end
