#!/usr/bin/ruby -KU
#encoding:utf-8

module Rdoba
   module Mixin
      module CompareString
         def compare_to value, opts = {}
            if opts == :ignore_diacritics ||
               opts.class == Hash && opts.key?( :ignore_diacritics )
               # TODO verify composite range
               def crop_diacritics(x)
                  (x < 0x300 ||
                   x > 0x36f && x < 0x483 ||
                   x > 0x487 && x < 0xa67c ||
                   x > 0xa67d) && x || nil
               end

               ( self.unpack('U*').map do |x|
                  crop_diacritics(x) ; end.compact ) <=>
               ( value.unpack('U*').map do |x|
                  crop_diacritics(x) ; end.compact )
            else
               self <=> value ; end ; end ; end

      module ReverseString
         ByteByByte = 0

         Aliases = { 
            :__rdoba_mixin_reverse__ => :reverse
         }


         def reverse step = 1
            case step
            when ByteByByte
               arr = []
               self.each_byte do | byte |
                  arr << byte.chr ; end
               arr.reverse.join
            when 1
               __rdoba_mixin_reverse__
            else
               res = ''
               offset = (self.size + 1) / step * step - step
               ( 0..offset ).step( step ) do | shift |
                  res += self[ offset - shift..offset - shift + 1 ] ; end
               res ; end ; end ; end

      module CaseString
         FirstChar = 0

         Fixups = [ :upcase, :downcase ]

         Aliases = { 
            :__rdoba_mixin_upcase__ => :upcase,
            :__rdoba_mixin_downcase__ => :downcase 
         }

         ConvertTable = {
            :up => {
                :ranges => [ {
                     :ords => [ (0xE0..0xFF), (0x3B1..0x3CB),
                                (0x430..0x44F) ],
                     :change => proc { | chr, value | chr -= 0x20 },
                  }, {
                     :ords => [ (0x3AC..0x3AC) ],
                     :change => proc { | ord | ord -= 0x26 },
                  }, {
                     :ords => [ (0x3AD..0x3AF) ],
                     :change => proc { | ord | ord -= 0x25 },
                  }, {
                     :ords => [ (0x3B0..0x3B0) ],
                     :change => proc { | ord | ord -= 0x22 },
                  }, {
                     :ords => [ (0x1F00..0x1F07), (0x1F10..0x1F17),
                                (0x1F20..0x1F27), (0x1F30..0x1F37),
                                (0x1F40..0x1F47), (0x1F50..0x1F57),
                                (0x1F60..0x1F67), (0x1F80..0x1F87),
                                (0x1F90..0x1F97), (0x1Fa0..0x1Fa7),
                                (0x1Fb0..0x1Fb3), ],
                     :change => proc { | ord | ord += 0x8 },
                  }, {
                     :ords => [ (0x450..0x45F) ],
                     :change => proc { | ord | ord -= 0x50 },
                  }, {
                     :ords => [ (0x100..0x1B9), (0x1C4..0x233),
                                (0x460..0x481), (0x48A..0x523),
                                (0x1E00..0x1E95), (0x1EA0..0x1EFF), 
                                (0x0A642..0xA667), (0x0A680..0x0A697),
                                (0xA722..0xA7A9) ],
                     :change => proc { | ord | ord.odd? && ( ord - 1 ) || ord },
                  } ],
               :default => proc do | ord |
                     [ ord ].pack( 'U' ).__rdoba_mixin_upcase__ ; end },
            :down => {
               :ranges => [ {
                     :ords => [ (0xC0..0xDF), (0x391..0x3AB),
                                (0x410..0x42F) ],
                     :change => proc { |chr, value| chr += 0x20 },
                  }, {
                     :ords => [ (0x386..0x386) ],
                     :change => proc { | ord | ord += 0x26 },
                  }, {
                     :ords => [ (0x388..0x38A) ],
                     :change => proc { | ord | ord += 0x25 },
                  }, {
                     :ords => [ (0x38E..0x38E) ],
                     :change => proc { | ord | ord += 0x22 },
                  }, {
                     :ords => [ (0x1F08..0x1F0F), (0x1F18..0x1F1F),
                                (0x1F28..0x1F2F), (0x1F38..0x1F3F),
                                (0x1F48..0x1F4F), (0x1F58..0x1F5F),
                                (0x1F68..0x1F6F), (0x1F88..0x1F8F),
                                (0x1F98..0x1F9F), (0x1Fa8..0x1FaF),
                                (0x1Fb8..0x1FbA), ],
                     :change => proc { | ord | ord -= 0x8 },
                  }, {
                     :ords => [ (0x400..0x40F) ],
                     :change => proc { | ord | ord += 0x50 },
                  }, {
                     :ords => [ (0x100..0x1B9), (0x1C4..0x233),
                                (0x450..0x481), (0x48A..0x523),
                                (0x1E00..0x1E95), (0x1EA0..0x1EFF), 
                                (0x0A642..0xA667), (0x0A680..0x0A697),
                                (0xA722..0xA7A9) ],
                     :change => proc { | ord | ord.even? && ( ord + 1 ) || ord },
                  } ],
               :default => proc do | ord |
                     [ ord ].pack( 'U' ).__rdoba_mixin_downcase__ ; end } }

         def self.change_case_char dest, char
            ord = char.is_a?( String ) ? char.ord : char.to_i
            table = ConvertTable[ dest ]
            nord = table[ :ranges ].each do |range|
               c = range[ :ords ].each do |r|
                  if r.include?( ord )
                     break false ; end ; end
               if !c
                  break range[ :change ].call ord ; end ; end

            if !nord.is_a? Numeric
               return table[ :default ].call ord ; end

            [ nord ].pack( 'U' ) ; end

         def self.up_char char
            CaseString.change_case_char :up, char ; end

         def self.downcase_char char
            CaseString.change_case_char :down, char ; end

         if RUBY_VERSION < '1.9'
            alias :setbyte :[]=

            def encoding
               'UTF-8'
            end

            def force_encoding(*args)
               self
            end

            def ord
               a = nil
               self.each_byte do |b|
                  case ( b & 0xC0 )
                  when 0xc0
                     a = (b & 0x3F)
                  when 0x80
                     return (a << 6) + (b & 0x3F)
                  else
                     return b ; end ; end ; end ; end

         def self.downcase str, options = {}
            self.change_case :down, str, options
         end

         def self.upcase str, options = {}
            self.change_case :up, str, options
         end

         def self.change_case reg, str, options = {}
            if ![ :up, :down ].include? reg
               return str ; end

            re = Regexp.new '[\x80-\xFF]', nil, 'n'
            if options.include? :first_char
               r = str.dup
               r[0] = eval "CaseString.change_case_char :#{reg}, str.ord"
               r
            elsif str.force_encoding( 'ASCII-8BIT' ).match re
               str.unpack('U*').map do | chr |
                  eval "CaseString.change_case_char :#{reg}, chr"
               end.join
            else eval "str.__rdoba_mixin_#{reg}case__" ; end ; end ; end

      module To_hArray
         def to_h options = {}
            h = {}
            self.each do |v|
               if v.is_a? Array
                  if h.key? v[ 0 ]
                     if !h[ v[ 0 ] ].is_a? Array
                        h[ v[ 0 ] ] = [ h[ v[ 0 ] ] ] ; end

                     if v.size > 2
                        h[ v [ 0 ] ].concat v[ 1..-1 ]
                     else
                        h[ v [ 0 ] ] << v[ 1 ] ; end
                  else
                     h[ v[ 0 ] ] = v.size > 2 && v[ 1..-1] || v[ 1 ] ; end
               else
                  if h.key? v
                     if !h[ v ].is_a? Array
                        h[ v ] = [ h[ v ] ] ; end

                     h[ v ] << v
                  else
                     h[ v ] = nil ; end ; end ; end

            if options[ :save_unique ]
               h.each_pair do |k,v|
                  if v.is_a? Array
                     v.uniq! ; end ; end ; end

            h ; end ; end

      module EmptyObject
         def empty?
            false ; end ; end

      module EmptyNilClass
         def empty?
            true ; end ; end ; end

   def self.mixin options
      ( options || [] ).each do |value|
         case value
         when :case
            Mixin::CaseString::Aliases.each do |k,v|
               ::String.send :alias_method, k, v ; end
            Mixin::CaseString::Fixups.each do |e|
               ::String.class_eval "def #{e}(*args);Mixin::CaseString.#{e}(self,args);end"
            end # trap NameError
            ::String.send :include, Mixin::CaseString
         when :reverse
            Mixin::ReverseString::Aliases.each do |k,v|
               ::String.send :alias_method, k, v ; end
            String.send :include, Rdoba::Mixin::ReverseString
         when :compare
            String.send :include, Rdoba::Mixin::CompareString
         when :to_h
            Array.send :include, Rdoba::Mixin::To_hArray
         when :empty
            Object.send :include, Rdoba::Mixin::EmptyObject
            NilClass.send :include, Rdoba::Mixin::EmptyNilClass
         else
            Kernel.puts STDERR, "Invalid rdoba-mixin options key: #{value.to_s}"
            end ; end ; end ; end


