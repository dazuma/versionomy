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
  # can be retrieved by calling Versionomy::Formats#standard. This format
  # understands most common version numbers, including prerelease
  # (e.g. alpha, beta, release candidate, etc.) forms and patchlevels.
  # 
  # You may also create your own formats, either by implementing the
  # format contract (see Versionomy::Format::Base) or by using the
  # Versionomy::Format::Delimiter tool, which can be used to construct
  # parsers for many version number formats.
  # 
  # Formats may be registered with Versionomy and given a name using the
  # methods of this Versionomy::Formats. This allows version numbers to be
  # serialized with their format.
  
  module Format
  end
  
  
end
