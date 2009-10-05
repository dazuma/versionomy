# -----------------------------------------------------------------------------
# 
# Versionomy standard schema and formats
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
  
  module Schemas
    
    
    # === The standard schema
    # 
    # The standard schema is designed to handle most commonly-used version
    # number forms, and allow parsing and comparison between them.
    # 
    # It begins with four numeric fields: "major.minor.tiny.tiny2".
    # 
    # The next field, "release_type", defines the remaining structure.
    # The release type can be one of these symbolic values:
    # <tt>:development</tt>, <tt>:alpha</tt>, <tt>:beta</tt>,
    # <tt>:preview</tt>, <tt>:release_candidate</tt>, or <tt>:release</tt>.
    # 
    # Depending on that value, additional fields become available. For example,
    # the <tt>:alpha</tt> value enables the fields "alpha_version"
    # and "alpha_minor", which represent version numbers after the "a" alpha
    # specifier. i.e. "2.1a30" has an alpha_version of 30. "2.1a30.2" also
    # has an alpha_minor of 2. Similarly, the <tt>:beta</tt> release_type
    # value enables the fields "beta_version" and "beta_minor". A release_type
    # of <tt>:release</tt> enables "patchlevel" and "patchlevel_minor", to
    # support versions like "1.8.7p72".
    # 
    # The full definition of the standard schema is as follows:
    # 
    #  field(:major, :initial => 1) do
    #    field(:minor) do
    #      field(:tiny) do
    #        field(:tiny2) do
    #          field(:release_type, :type => :symbol) do
    #            symbol(:development, :bump => :alpha)
    #            symbol(:alpha, :bump => :beta)
    #            symbol(:beta, :bump => :release_candidate)
    #            symbol(:preview, :bump => :release)
    #            symbol(:release_candidate, :bump => :release)
    #            symbol(:release, :bump => :release)
    #            initial_value(:release)
    #            field(:development_version, :only => :development, :initial => 1) do
    #              field(:development_minor)
    #            end
    #            field(:alpha_version, :only => :alpha, :initial => 1) do
    #              field(:alpha_minor)
    #            end
    #            field(:beta_version, :only => :beta, :initial => 1) do
    #              field(:beta_minor)
    #            end
    #            field(:preview_version, :only => :preview, :initial => 1) do
    #              field(:preview_minor)
    #            end
    #            field(:release_candidate_version, :only => :release_candidate, :initial => 1) do
    #              field(:release_candidate_minor)
    #            end
    #            field(:patchlevel, :only => :release) do
    #              field(:patchlevel_minor)
    #            end
    #          end
    #        end
    #      end
    #    end
    #  end
    
    module Standard
      
      
      def self._create_schema  # :nodoc:
        @schema = Schema.new do
          field(:major, :initial => 1) do
            field(:minor) do
              field(:tiny) do
                field(:tiny2) do
                  field(:release_type, :type => :symbol) do
                    symbol(:development, :bump => :alpha)
                    symbol(:alpha, :bump => :beta)
                    symbol(:beta, :bump => :release_candidate)
                    symbol(:preview, :bump => :release)
                    symbol(:release_candidate, :bump => :release)
                    symbol(:release, :bump => :release)
                    initial_value(:release)
                    field(:development_version, :only => :development, :initial => 1) do
                      field(:development_minor)
                    end
                    field(:alpha_version, :only => :alpha, :initial => 1) do
                      field(:alpha_minor)
                    end
                    field(:beta_version, :only => :beta, :initial => 1) do
                      field(:beta_minor)
                    end
                    field(:preview_version, :only => :preview, :initial => 1) do
                      field(:preview_minor)
                    end
                    field(:release_candidate_version, :only => :release_candidate, :initial => 1) do
                      field(:release_candidate_minor)
                    end
                    field(:patchlevel, :only => :release) do
                      field(:patchlevel_minor)
                    end
                  end
                end
              end
            end
          end
        end
        @schema.default_format = Format::Delimiter.new(@schema) do
          basic_integer_field(:major, :required_unparse => true, :delimiter_regexp => '', :default_delimiter => '')
          basic_integer_field(:minor)
          basic_integer_field(:tiny)
          basic_integer_field(:tiny2)
          multi_format_field(:release_type, :requires_previous_field => false) do
            mapping_parser(:form => :short, :delimiter_regexp => '-|\.|\s?', :default_delimiter => '', :expected_follower_regexp => '\d') do
              map(:development, 'd')
              map(:alpha, 'a')
              map(:beta, 'b')
              map(:release_candidate, 'rc')
            end
            mapping_parser(:form => :short, :delimiter_regexp => '-|\.|\s?', :post_delimiter_regexp => '\s?|-', :default_delimiter => '', :expected_follower_regexp => '\d') do
              map(:preview, 'pre')
            end
            mapping_parser(:form => :long, :delimiter_regexp => '-|\.|\s?', :post_delimiter_regexp => '\s?|-', :default_delimiter => '', :expected_follower_regexp => '\d') do
              map(:development, 'dev')
              map(:alpha, 'alpha')
              map(:beta, 'beta')
              map(:release_candidate, 'rc')
              map(:preview, 'preview')
            end
            mapping_parser(:form => :short, :delimiter_regexp => '', :default_delimiter => '') do
              map(:release, '')
            end
            mapping_parser(:form => :long, :delimiter_regexp => '', :default_delimiters => '') do
              map(:release, '')
            end
          end
          basic_integer_field(:development_version, :required_unparse => true, :delimiter_regexp => '', :default_delimiter => '')
          basic_integer_field(:development_minor)
          basic_integer_field(:alpha_version, :required_unparse => true, :delimiter_regexp => '', :default_delimiter => '')
          basic_integer_field(:alpha_minor)
          basic_integer_field(:beta_version, :required_unparse => true, :delimiter_regexp => '', :default_delimiter => '')
          basic_integer_field(:beta_minor)
          basic_integer_field(:preview_version, :required_unparse => true, :delimiter_regexp => '', :default_delimiter => '')
          basic_integer_field(:preview_minor)
          basic_integer_field(:release_candidate_version, :required_unparse => true, :delimiter_regexp => '', :default_delimiter => '')
          basic_integer_field(:release_candidate_minor)
          multi_format_field(:patchlevel, :requires_previous_field => false) do
            basic_parser(:form => :numeric, :delimiter_regexp => '-|(-|\.|\s?)p', :default_delimiter => '-')
            alphabetic_parser(:form => :alphabetic, :delimiter_regexp => '-|\.|\s?', :default_delimiter => '', :expected_follower_regexp => '$')
          end
          basic_integer_field(:patchlevel_minor)
          default_unparse_params(:required_fields => [:minor])
        end
      end
      
      
      # Get the standard schema
      
      def self.schema
        _create_schema unless @schema
        @schema
      end
      
      
      # Get the standard format
      
      def self.default_format
        self.schema.default_format
      end
      
      
    end
    
  end
  
end
