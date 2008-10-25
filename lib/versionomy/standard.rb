# -----------------------------------------------------------------------------
# 
# Versionomy standard schema and formats
# 
# -----------------------------------------------------------------------------
# Copyright 2008 Daniel Azuma
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
  
  
  # === The standard schema
  # 
  # The standard schema is designed to handle most commonly-used version
  # number forms, and allow parsing and comparison between them.
  # 
  # It begins with four numeric fields: "major.minor.tiny.tiny2".
  # 
  # The next field, "release_type", defines the remaining structure.
  # The release type can be one of these symbolic values: <tt>:prerelease</tt>,
  # <tt>:development</tt>, <tt>:alpha</tt>, <tt>:beta</tt>,
  # <tt>:release_candidate</tt>, or <tt>:release</tt>.
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
  #  Schema.new(:major, :initial => 1) do
  #    schema(:minor) do
  #      schema(:tiny) do
  #        schema(:tiny2) do
  #          schema(:release_type, :type => :symbol) do
  #            symbol(:prerelease, :bump => :release)
  #            symbol(:development, :bump => :alpha)
  #            symbol(:alpha, :bump => :beta)
  #            symbol(:beta, :bump => :release_candidate)
  #            symbol(:release_candidate, :bump => :release)
  #            symbol(:release, :bump => :release)
  #            initial_value(:release)
  #            schema(:prerelease_version, :only => :prerelease, :initial => 1) do
  #              schema(:prerelease_minor)
  #            end
  #            schema(:development_version, :only => :development, :initial => 1) do
  #              schema(:development_minor)
  #            end
  #            schema(:alpha_version, :only => :alpha, :initial => 1) do
  #              schema(:alpha_minor)
  #            end
  #            schema(:beta_version, :only => :beta, :initial => 1) do
  #              schema(:beta_minor)
  #            end
  #            schema(:release_candidate_version, :only => :release_candidate, :initial => 1) do
  #              schema(:release_candidate_minor)
  #            end
  #            schema(:patchlevel, :only => :release) do
  #              schema(:patchlevel_minor)
  #            end
  #          end
  #        end
  #      end
  #    end
  #  end
  
  module Standard
    
    
    # A formatter for the standard schema
    
    class StandardFormat
      
      
      # Create a new formatter
      
      def initialize(opts_={})
        @name = opts_[:name] || :standard
        @patchlevel_separator = opts_[:patchlevel_separator] || ['-', '\s?[Pp]']
        @prerelease_symbol = opts_[:prerelease_symbol] || '\s?(PRE|Pre|pre)'
        @development_symbol = opts_[:development_symbol] || '\s?[Dd]'
        @alpha_symbol = opts_[:alpha_symbol] || '\s?[Aa](LPHA|lpha)?'
        @beta_symbol = opts_[:beta_symbol] || '\s?[Bb](ETA|eta)?'
        @release_candidate_symbol = opts_[:release_candidate_symbol] || '\s?(RC|Rc|rc)'
        @patchlevel_separator_unparse = opts_[:patchlevel_separator_unparse] || '-'
        @prerelease_symbol_unparse = opts_[:prerelease_symbol_unparse] || 'pre'
        @development_symbol_unparse = opts_[:development_symbol_unparse] || 'd'
        @alpha_symbol_unparse = opts_[:alpha_symbol_unparse] || 'a'
        @beta_symbol_unparse = opts_[:beta_symbol_unparse] || 'b'
        @release_candidate_symbol_unparse = opts_[:release_candidate_symbol_unparse] || 'rc'
      end
      
      
      def _create_regex(given_, default_)  # :nodoc:
        if given_
          if given_.respond_to?(:join)
            given_.join('|')
          else
            given_.to_s
          end
        else
          if default_.respond_to?(:join)
            default_.join('|')
          else
            default_.to_s
          end
        end
      end
      private :_create_regex
      
      
      # The format name
      
      def name
        @name
      end
      
      
      # Parse a string for the standard schema.
      
      def parse(schema_, str_, params_)
        params_ = {:format => @name}.merge(params_)
        hash_ = Hash.new
        if str_ =~ /^(\d+)(.*)$/
          hash_[:major] = $1.to_i
          str_ = $2
        else
          hash_[:major] = 0
        end
        if str_ =~ /^\.(\d+)(.*)$/
          hash_[:minor] = $1.to_i
          str_ = $2
          if str_ =~ /^\.(\d+)(.*)$/
            hash_[:tiny] = $1.to_i
            str_ = $2
            if str_ =~ /^\.(\d+)(.*)$/
              hash_[:tiny2] = $1.to_i
              str_ = $2
              params_[:required_fields] = 4
            else
              hash_[:tiny2] = 0
              params_[:required_fields] = 3
            end
          else
            hash_[:tiny] = 0
            params_[:required_fields] = 2
          end
        else
          hash_[:minor] = 0
          params_[:required_fields] = 1
        end
        if str_ =~ /^(#{_create_regex(params_[:prerelease_symbol], @prerelease_symbol)})(\d+)(.*)$/
          matches_ = $~
          params_[:prerelease_symbol_unparse] = matches_[1]
          hash_[:release_type] = :prerelease
          hash_[:prerelease_version] = matches_[-2].to_i
          str_ =  matches_[-1]
          if str_ =~ /^\.(\d+)/
            hash_[:prerelease_minor] = $1.to_i
            params_[:prerelease_required_fields] = 2
          else
            params_[:prerelease_required_fields] = 1
          end
        elsif str_ =~ /^(#{_create_regex(params_[:development_symbol], @development_symbol)})(\d+)(.*)$/
          matches_ = $~
          params_[:development_symbol_unparse] = matches_[1]
          hash_[:release_type] = :development
          hash_[:development_version] = matches_[-2].to_i
          str_ = matches_[-1]
          if str_ =~ /^\.(\d+)/
            hash_[:development_minor] = $1.to_i
            params_[:development_required_fields] = 2
          else
            params_[:development_required_fields] = 1
          end
        elsif str_ =~ /^(#{_create_regex(params_[:alpha_symbol], @alpha_symbol)})(\d+)(.*)$/
          matches_ = $~
          params_[:alpha_symbol_unparse] = matches_[1]
          hash_[:release_type] = :alpha
          hash_[:alpha_version] = matches_[-2].to_i
          str_ = matches_[-1]
          if str_ =~ /^\.(\d+)/
            hash_[:alpha_minor] = $1.to_i
            params_[:alpha_required_fields] = 2
          else
            params_[:alpha_required_fields] = 1
          end
        elsif str_ =~ /^(#{_create_regex(params_[:beta_symbol], @beta_symbol)})(\d+)(.*)$/
          matches_ = $~
          params_[:beta_symbol_unparse] = matches_[1]
          hash_[:release_type] = :beta
          hash_[:beta_version] = matches_[-2].to_i
          str_ = matches_[-1]
          if str_ =~ /^\.(\d+)/
            hash_[:beta_minor] = $1.to_i
            params_[:beta_required_fields] = 2
          else
            params_[:beta_required_fields] = 1
          end
        elsif str_ =~ /^(#{_create_regex(params_[:release_candidate_symbol], @release_candidate_symbol)})(\d+)(.*)$/
          matches_ = $~
          params_[:release_candidate_symbol_unparse] = matches_[1]
          hash_[:release_candidate_version] = matches_[-2].to_i
          hash_[:release_type] = :release_candidate
          str_ = matches_[-1]
          if str_ =~ /^\.(\d+)/
            hash_[:release_candidate_minor] = $1.to_i
            params_[:release_candidate_required_fields] = 2
          else
            params_[:release_candidate_required_fields] = 1
          end
        else
          hash_[:release_type] = :release
          if str_ =~ /^(#{_create_regex(params_[:patchlevel_separator], @patchlevel_separator)})(\d+)(.*)$/
            matches_ = $~
            params_[:patchlevel_separator_unparse] = matches_[1]
            params_[:patchlevel_format] = :digit
            hash_[:patchlevel] = matches_[-2].to_i
            str_ = matches_[-1]
            if str_ =~ /^\.(\d+)/
              hash_[:patchlevel_minor] = $1.to_i
              params_[:patchlevel_required_fields] = 2
            else
              params_[:patchlevel_required_fields] = 1
            end
          elsif str_ =~ /^([a-z])/
            char_ = $1
            params_[:patchlevel_format] = :alpha_lower
            params_[:patchlevel_required_fields] = 1
            hash[:patchlevel] = (char_.bytes.next rescue char_[0]) - 96
          elsif str_ =~ /^([A-Z])/
            char_ = $1
            params_[:patchlevel_format] = :alpha_upper
            params_[:patchlevel_required_fields] = 1
            hash[:patchlevel] = (char_.bytes.next rescue char_[0]) - 64
          end
        end
        Versionomy::Value._new(schema_, hash_, params_)
      end
      
      
      # Unparse a value for the standard schema.
      
      def unparse(schema_, value_, params_)
        params_ = value_.parse_params.merge(params_)
        str_ = "#{value_.major}.#{value_.minor}.#{value_.tiny}.#{value_.tiny2}"
        (4 - (params_[:required_fields] || 2)).times{ str_.sub!(/\.0$/, '') }
        case value_.release_type
        when :prerelease
          prerelease_required_fields_ = params_[:prerelease_required_fields] || 1
          str_ << (params_[:prerelease_symbol_unparse] || @prerelease_symbol_unparse)
          str_ << value_.prerelease_version.to_s
          if value_.prerelease_minor > 0 || prerelease_required_fields_ > 1
            str_ << ".#{value_.prerelease_minor}"
          end
        when :development
          development_required_fields_ = params_[:development_required_fields] || 1
          str_ << (params_[:development_symbol_unparse] || @development_symbol_unparse)
          str_ << value_.development_version.to_s
          if value_.development_minor > 0 || development_required_fields_ > 1
            str_ << ".#{value_.development_minor}"
          end
        when :alpha
          alpha_required_fields_ = params_[:alpha_required_fields] || 1
          str_ << (params_[:alpha_symbol_unparse] || @alpha_symbol_unparse)
          str_ << value_.alpha_version.to_s
          if value_.alpha_minor > 0 || alpha_required_fields_ > 1
            str_ << ".#{value_.alpha_minor}"
          end
        when :beta
          beta_required_fields_ = params_[:beta_required_fields] || 1
          str_ << (params_[:beta_symbol_unparse] || @beta_symbol_unparse)
          str_ << value_.beta_version.to_s
          if value_.beta_minor > 0 || beta_required_fields_ > 1
            str_ << ".#{value_.beta_minor}"
          end
        when :release_candidate
          release_candidate_required_fields_ = params_[:release_candidate_required_fields] || 1
          str_ << (params_[:release_candidate_symbol_unparse] || @release_candidate_symbol_unparse)
          str_ << value_.release_candidate_version.to_s
          if value_.release_candidate_minor > 0 || release_candidate_required_fields_ > 1
            str_ << ".#{value_.release_candidate_minor}"
          end
        else
          patchlevel_required_fields_ = params_[:patchlevel_required_fields] || 0
          if value_.patchlevel > 0 || patchlevel_required_fields_ > 0
            if params_[:patchlevel_format] == :alpha_lower
              str_.concat(96 + value_.patchlevel)
            elsif params_[:patchlevel_format] == :alpha_upper
              str_.concat(64 + value_.patchlevel)
            else
              str_ << (params_[:patchlevel_separator_unparse] || @patchlevel_separator_unparse)
              str_ << value_.patchlevel.to_s
              if value_.patchlevel_minor > 0 || patchlevel_required_fields_ > 1
                str_ << ".#{value_.patchlevel_minor}"
              end
            end
          end
        end
        str_
      end
      
    end
    
    
    # Get the standard schema
    
    def self.schema
      @standard_schema ||= SchemaCreator._create_schema
    end
    
    
    module SchemaCreator  # :nodoc:
      
      def self._create_schema
        Schema.new(:major, :initial => 1) do
          schema(:minor) do
            schema(:tiny) do
              schema(:tiny2) do
                schema(:release_type, :type => :symbol) do
                  symbol(:prerelease, :bump => :release)
                  symbol(:development, :bump => :alpha)
                  symbol(:alpha, :bump => :beta)
                  symbol(:beta, :bump => :release_candidate)
                  symbol(:release_candidate, :bump => :release)
                  symbol(:release, :bump => :release)
                  initial_value(:release)
                  schema(:prerelease_version, :only => :prerelease, :initial => 1) do
                    schema(:prerelease_minor)
                  end
                  schema(:development_version, :only => :development, :initial => 1) do
                    schema(:development_minor)
                  end
                  schema(:alpha_version, :only => :alpha, :initial => 1) do
                    schema(:alpha_minor)
                  end
                  schema(:beta_version, :only => :beta, :initial => 1) do
                    schema(:beta_minor)
                  end
                  schema(:release_candidate_version, :only => :release_candidate, :initial => 1) do
                    schema(:release_candidate_minor)
                  end
                  schema(:patchlevel, :only => :release) do
                    schema(:patchlevel_minor)
                  end
                end
              end
            end
          end
          define_format(StandardFormat.new)
        end
      end
      
      
    end
    
  end
  
  
end
