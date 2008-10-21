== Versionomy

Versionomy is a generalized version number library.
It provides tools to represent, manipulate, parse, and compare version
numbers in the wide variety of versioning schemes in use.

=== Some examples

 v1 = Versionomy.parse('1.3.2')
 v1.major                       # => 1
 v1.minor                       # => 3
 v1.tiny                        # => 2
 
 v2 = Versionomy.parse('1.4a3')
 v2.major                       # => 1
 v2.minor                       # => 4
 v2.tiny                        # => 0
 v2.release_type                # => :alpha
 v2.alpha_version               # => 3
 v2 > v1                        # => true
 
 v3 = Versionomy.parse('1.4.0b2')
 v3.major                       # => 1
 v3.minor                       # => 4
 v3.tiny                        # => 0
 v3.release_type                # => :beta
 v3.alpha_version               # raises NameError
 v3.beta_version                # => 2
 v3 > v2                        # => true
 v3.to_s                        # => '1.4.0b2'
 
 v4 = v3.bump(:beta_version)
 v4.to_s                        # => '1.4.0b3'
 
 v5 = v3.bump(:release_type)
 v5.to_s                        # => '1.4.0rc1'
 
 v6 = v3.bump(:tiny)
 v6.to_s                        # => '1.4.1'
 
 v7 = v3.bump(:major)
 v7.to_s                        # => '2.0.0'
 v7.parse_params[:required_fields] = 2
 v7.to_s                        # => '2.0'
 
 v8 = Versionomy.parse('2.0.0.0')
 v8.to_s                        # => '2.0.0.0'
 v8 == v7                       # => true
 
 v9 = v7.bump(:patchlevel)
 v9.to_s                        # => '2.0-1'
 
 v10 = Versionomy.parse('2008 SP2', :patchlevel_separator => ' SP')
 v10.major                      # => 2008
 v10.minor                      # => 0
 v10.patchlevel                 # => 2
 v10.to_s                       # => '2008 SP2'
 v10.unparse(:patchlevel_separator => 'p', :required_fields => 2)   # => '2008.0p2'

=== Feature list

Versionomy's default versioning scheme handles four primary fields (labeled
+major+, +minor+, +tiny+, and +tiny2+). It also supports prerelease versions
such as "pre", development, alpha, beta, and release candidate. Finally, it
supports patchlevel numbers for released versions.

Versionomy can compare any two version numbers, and "bump" versions at any
level. It supports parsing and unparsing in most commonly-used formats, and
allows you to extend the parsing to include custom formats.

Finally, Versionomy also lets you to specify any arbitrary versioning
"schema". You can define any number of version number fields, and provide
your own semantics and behavior for comparing, parsing, and modifying
version numbers.

=== Requirements

* Ruby 1.8.7 or later.
* Rubygems
* mixology gem.
* blockenspiel gem.

=== Installation

 gem install versionomy

=== Known issues and limitations

* Not yet compatible with Ruby 1.9 due to issues with the mixology gem.
* JRuby status not yet known.

=== Development and support

Documentation is available at http://virtuoso.rubyforge.org/versionomy

Source code is hosted by Github at http://github.com/dazuma/versionomy/tree

Report bugs on RubyForge at http://rubyforge.org/projects/virtuoso

Contact the author at dazuma at gmail dot com.

=== Author / Credits

Versionomy is written by Daniel Azuma (http://www.daniel-azuma.com).

== LICENSE:

Copyright 2008 Daniel Azuma.

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* Neither the name of the copyright holder, nor the names of any other
  contributors to this software, may be used to endorse or promote products
  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
