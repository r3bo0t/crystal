require "../../spec_helper"

private def assert_format(input, output = input, strict = false, file = __FILE__, line = __LINE__)
  it "formats #{input.inspect}", file, line do
    output = "#{output}\n" unless strict
    Crystal::Formatter.format(input).should eq(output)
  end
end

describe Crystal::Formatter do
  assert_format "nil"

  assert_format "true"
  assert_format "false"

  assert_format "'\\n'"
  assert_format "'a'"
  assert_format "'\\u{0123}'"

  assert_format ":foo"
  assert_format ":\"foo\""

  assert_format "1"
  assert_format "1   ;    2", "1; 2"
  assert_format "1   ;\n    2", "1\n2"
  assert_format "1\n\n2", "1\n\n2"
  assert_format "1\n\n\n2", "1\n\n2"
  assert_format "1_234", "1_234"
  assert_format "0x1234_u32", "0x1234_u32"
  assert_format "0_u64", "0_u64"
  assert_format "0u64", "0u64"
  assert_format "0i64", "0i64"

  assert_format "   1", "1"
  assert_format "\n\n1", "1"
  assert_format "\n# hello\n1", "# hello\n1"
  assert_format "\n# hello\n\n1", "# hello\n\n1"
  assert_format "\n# hello\n\n\n1", "# hello\n\n1"
  assert_format "\n   # hello\n\n1", "# hello\n\n1"

  assert_format %("hello")
  assert_format %(%(hello))
  assert_format %(%<hello>)
  assert_format %(%[hello])
  assert_format %(%{hello})
  assert_format %("hel\\nlo")
  assert_format %("hel\nlo")

  assert_format "[] of Foo"
  assert_format "[\n]   of   \n   Foo  ", "[] of Foo"
  assert_format "[1, 2, 3]"
  assert_format "[1, 2, 3] of Foo"
  assert_format "  [   1  ,    2  ,    3  ]  ", "[1, 2, 3]"
  assert_format "[1, 2, 3,  ]", "[1, 2, 3]"
  assert_format "[1,\n2,\n3]", "[1,\n 2,\n 3,\n]"
  assert_format "[\n1,\n2,\n3]", "[\n  1,\n  2,\n  3,\n]"
  assert_format "if 1\n[   1  ,    2  ,    3  ]\nend", "if 1\n  [1, 2, 3]\nend"
  assert_format "    [   1,   \n   2   ,   \n   3   ]   ", "[1,\n 2,\n 3,\n]"
  assert_format "Set { 1 , 2 }", "Set{1, 2}"
  assert_format "[\n1,\n\n2]", "[\n  1,\n\n  2,\n]"

  assert_format "{1, 2, 3}"
  assert_format "{ {1, 2, 3} }"
  assert_format "{ {1 => 2} }"
  assert_format "{ {1, 2, 3} => 4 }"

  assert_format "{  } of  A   =>   B", "{} of A => B"
  assert_format "{ 1   =>   2 }", "{1 => 2}"
  assert_format "{ 1   =>   2 ,   3  =>  4 }", "{1 => 2, 3 => 4}"
  assert_format "{ 1   =>   2 ,\n   3  =>  4 }", "{1 => 2,\n 3 => 4,\n}"
  assert_format "{\n1   =>   2 ,\n   3  =>  4 }", "{\n  1 => 2,\n  3 => 4,\n}"
  assert_format "{ foo:  1 }", "{foo: 1}"
  assert_format "{ \"foo\":  1 }", "{\"foo\": 1}"
  assert_format "{ \"foo\" =>  1 }", "{\"foo\" => 1}"
  assert_format "HTTP::Headers { foo:  1 }", "HTTP::Headers{foo: 1}"
  assert_format "{ 1   =>   2 ,\n\n   3  =>  4 }", "{1 => 2,\n\n 3 => 4,\n}"
  assert_format "foo({\nbar: 1,\n})", "foo({\n      bar: 1,\n    })"

  assert_format "Foo"
  assert_format "Foo:: Bar", "Foo::Bar"
  assert_format "Foo:: Bar", "Foo::Bar"
  assert_format "::Foo:: Bar", "::Foo::Bar"
  assert_format "Foo( A , 1 )", "Foo(A, 1)"

  %w(if unless ifdef).each do |keyword|
    assert_format "#{keyword} a\n2\nend", "#{keyword} a\n  2\nend"
    assert_format "#{keyword} a\n2\nelse\nend", "#{keyword} a\n  2\nelse\nend"
    assert_format "#{keyword} a\nelse\n2\nend", "#{keyword} a\nelse\n  2\nend"
    assert_format "#{keyword} a\n2\nelse\n3\nend", "#{keyword} a\n  2\nelse\n  3\nend"
    assert_format "#{keyword} a\n2\n3\nelse\n4\n5\nend", "#{keyword} a\n  2\n  3\nelse\n  4\n  5\nend"
    assert_format "#{keyword} a\n#{keyword} b\n3\nelse\n4\nend\nend", "#{keyword} a\n  #{keyword} b\n    3\n  else\n    4\n  end\nend"
    assert_format "#{keyword} a\n#{keyword} b\nelse\n4\nend\nend", "#{keyword} a\n  #{keyword} b\n  else\n    4\n  end\nend"
    assert_format "#{keyword} a\n    # hello\n 2\nend", "#{keyword} a\n  # hello\n  2\nend"
    assert_format "#{keyword} a\n2; 3\nelse\n3\nend", "#{keyword} a\n  2; 3\nelse\n  3\nend"
  end

  assert_format "if 1\n2\nelsif\n3\n4\nend", "if 1\n  2\nelsif 3\n  4\nend"
  assert_format "if 1\n2\nelsif\n3\n4\nelsif 5\n6\nend", "if 1\n  2\nelsif 3\n  4\nelsif 5\n  6\nend"
  assert_format "if 1\n2\nelsif\n3\n4\nelse\n6\nend", "if 1\n  2\nelsif 3\n  4\nelse\n  6\nend"
  assert_format "ifdef a\n2\nelsif b\n4\nend", "ifdef a\n  2\nelsif b\n  4\nend"
  assert_format "ifdef !a\n2\nend", "ifdef !a\n  2\nend"

  assert_format "if 1\n2\nend\nif 3\nend", "if 1\n  2\nend\nif 3\nend"
  assert_format "if 1\nelse\n2\nend\n3", "if 1\nelse\n  2\nend\n3"

  assert_format "1 ? 2 : 3"
  assert_format "1 ?\n  2    :   \n 3", "1 ? 2 : 3"

  assert_format "1   if   2", "1 if 2"
  assert_format "1   unless   2", "1 unless 2"

  assert_format "[] of Int32\n1"

  assert_format "(1)"
  assert_format "  (  1;  2;   3  )  ", "(1; 2; 3)"
  assert_format "begin; 1; end", "begin\n  1\nend"
  assert_format "begin\n1\n2\n3\nend", "begin\n  1\n  2\n  3\nend"
  assert_format "begin\n1 ? 2 : 3\nend", "begin\n  1 ? 2 : 3\nend"

  assert_format "def   foo  \n  end", "def foo\nend"
  assert_format "def foo\n1\nend", "def foo\n  1\nend"
  assert_format "def foo\n\n1\n\nend", "def foo\n  1\nend"
  assert_format "def foo()\n1\nend", "def foo\n  1\nend"
  assert_format "def foo   (   )   \n1\nend", "def foo\n  1\nend"
  assert_format "def self . foo\nend", "def self.foo\nend"
  assert_format "def   foo (  x )  \n  end", "def foo(x)\nend"
  assert_format "def   foo   x  \n  end", "def foo x\nend"
  assert_format "def   foo (  x , y )  \n  end", "def foo(x, y)\nend"
  assert_format "def   foo (  x , y , )  \n  end", "def foo(x, y)\nend"
  assert_format "def   foo (  x , y ,\n)  \n  end", "def foo(x, y)\nend"
  assert_format "def   foo (  x ,\n y )  \n  end", "def foo(x,\n        y)\nend"
  assert_format "def   foo (\nx ,\n y )  \n  end", "def foo(\n        x,\n        y)\nend"
  assert_format "def   foo (  @x)  \n  end", "def foo(@x)\nend"
  assert_format "def   foo (  @x, @y)  \n  end", "def foo(@x, @y)\nend"
  assert_format "def   foo (  @@x)  \n  end", "def foo(@@x)\nend"
  assert_format "def   foo (  &@block)  \n  end", "def foo(&@block)\nend"
  assert_format "def foo(a, &@b)\nend"
  assert_format "def   foo (  x  =   1 )  \n  end", "def foo(x = 1)\nend"
  assert_format "def   foo (  x  :  Int32 )  \n  end", "def foo(x : Int32)\nend"
  assert_format "def   foo (  x  :  self )  \n  end", "def foo(x : self)\nend"
  assert_format "def   foo (  x  :  Foo.class )  \n  end", "def foo(x : Foo.class)\nend"
  assert_format "def   foo (  x  :  Foo+ )  \n  end", "def foo(x : Foo+)\nend"
  assert_format "def   foo (  x  =   1  :  Int32 )  \n  end", "def foo(x = 1 : Int32)\nend"
  assert_format "abstract  def   foo  \n  1", "abstract def foo\n\n1"
  assert_format "def foo( & block )\nend", "def foo(&block)\nend"
  assert_format "def foo  & block  \nend", "def foo &block\nend"
  assert_format "def foo( x , & block )\nend", "def foo(x, &block)\nend"
  assert_format "def foo( x , & block  : Int32 )\nend", "def foo(x, &block : Int32)\nend"
  assert_format "def foo( x , & block  : Int32 ->)\nend", "def foo(x, &block : Int32 ->)\nend"
  assert_format "def foo( x , & block  : Int32->Float64)\nend", "def foo(x, &block : Int32 -> Float64)\nend"
  assert_format "def foo( x , & block  :   ->)\nend", "def foo(x, &block : ->)\nend"
  assert_format "def foo( x , * y )\nend", "def foo(x, *y)\nend"
  assert_format "class Bar\nprotected def foo(x)\na=b(c)\nend\nend", "class Bar\n  protected def foo(x)\n    a = b(c)\n  end\nend"
  assert_format "def foo=(x)\nend"
  assert_format "def +(x)\nend"
  assert_format "def   foo  :  Int32 \n  end", "def foo : Int32\nend"
  assert_format "def   foo ( x )  :  Int32 \n  end", "def foo(x) : Int32\nend"
  assert_format "def   foo  x   :  Int32 \n  end", "def foo x : Int32\nend"
  assert_format "def %(x)\n  1\nend"
  assert_format "def `(x)\n  1\nend"
  assert_format "def /(x)\n  1\nend"

  assert_format "foo"
  assert_format "foo()"
  assert_format "foo(  )", "foo()"
  assert_format "foo  1", "foo 1"
  assert_format "foo  1  ,   2", "foo 1, 2"
  assert_format "foo(  1  ,   2 )", "foo(1, 2)"

  assert_format "foo . bar", "foo.bar"
  assert_format "foo . bar()", "foo.bar"
  assert_format "foo . bar( x , y )", "foo.bar(x, y)"
  assert_format "foo do  \n x \n end", "foo do\n  x\nend"
  assert_format "foo do  | x | \n x \n end", "foo do |x|\n  x\nend"
  assert_format "foo do  | x , y | \n x \n end", "foo do |x, y|\n  x\nend"
  assert_format "if 1\nfoo do  | x , y | \n x \n end\nend", "if 1\n  foo do |x, y|\n    x\n  end\nend"
  assert_format "foo do   # hello\nend", "foo do # hello\nend"
  assert_format "foo{}", "foo { }"
  assert_format "foo{|x| x}", "foo { |x| x }"
  assert_format "foo{|x|\n x}", "foo { |x|\n  x\n}"
  assert_format "foo   &.bar", "foo &.bar"
  assert_format "foo   &.bar( 1 , 2 )", "foo &.bar(1, 2)"
  assert_format "foo.bar  &.baz( 1 , 2 )", "foo.bar &.baz(1, 2)"
  assert_format "foo   &.bar", "foo &.bar"
  assert_format "foo   &.==(2)", "foo &.==(2)"
  assert_format "foo   &.>=(2)", "foo &.>=(2)"
  assert_format "join io, &.inspect"
  assert_format "foo . bar  =  1", "foo.bar = 1"
  assert_format "foo  x:  1", "foo x: 1"
  assert_format "foo  x:  1,  y:  2", "foo x: 1, y: 2"
  assert_format "foo a , b ,  x:  1", "foo a, b, x: 1"
  assert_format "foo a , *b", "foo a, *b"
  assert_format "foo   &bar", "foo &bar"
  assert_format "foo 1 ,  &bar", "foo 1, &bar"
  assert_format "foo(&.bar)"
  assert_format "foo.bar(&.baz)"
  assert_format "foo(1, &.bar)"
  assert_format "::foo(1, 2)"
  assert_format "args.any? &.name.baz"
  assert_format "foo(\n  1, 2)", "foo(\n     1, 2)"
  assert_format "foo(\n1,\n 2  \n)", "foo(\n     1,\n     2\n   )"
  assert_format "foo(\n1,\n\n 2  \n)", "foo(\n     1,\n\n     2\n   )"
  assert_format "foo 1,\n2", "foo 1,\n    2"
  assert_format "foo 1, a: 1,\nb: 2,\nc: 3", "foo 1, a: 1,\n       b: 2,\n       c: 3"
  assert_format "foo 1,\na: 1,\nb: 2,\nc: 3", "foo 1,\n    a: 1,\n    b: 2,\n    c: 3"
  assert_format "foo(\n  1, 2, &block)", "foo(\n     1, 2, &block)"
  assert_format "foo(\n  1, 2,\n&block)", "foo(\n     1, 2,\n     &block)"
  assert_format "foo 1, a: 1,\nb: 2,\nc: 3,\n&block", "foo 1, a: 1,\n       b: 2,\n       c: 3,\n       &block"
  assert_format "foo 1, do\n2\nend", "foo 1 do\n  2\nend"
  assert_format "a.b &.[c]?\n1"
  assert_format "a.b &.[c]\n1"
  assert_format "foo(1, 2,)", "foo(1, 2)"
  assert_format "foo(1, 2,\n)", "foo(1, 2)"
  assert_format "foo(1,\n2,\n)", "foo(1,\n    2,\n   )"
  assert_format "foo(out x)", "foo(out x)"
  assert_format "foo(\n     1,\n     a: 1,\n     b: 2,\n   )"

  assert_format "foo.bar\n.baz", "foo.bar\n   .baz"
  assert_format "foo.bar.baz\n.qux", "foo.bar.baz\n       .qux"
  assert_format "foo\n.bar\n.baz", "foo\n   .bar\n   .baz"

  assert_format "foo.\nbar", "foo\n   .bar"

  assert_format "foo   &.is_a?(T)", "foo &.is_a?(T)"
  assert_format "foo   &.responds_to?(:foo)", "foo &.responds_to?(:foo)"

  %w(return break next yield).each do |keyword|
    assert_format keyword
    assert_format "#{keyword}( 1 )", "#{keyword}(1)"
    assert_format "#{keyword}  1", "#{keyword} 1"
    assert_format "#{keyword}( 1 , 2 )", "#{keyword}(1, 2)"
    assert_format "#{keyword}  1 ,  2", "#{keyword} 1, 2"
    assert_format "#{keyword} { 1 ,  2 }", "#{keyword} {1, 2}" unless keyword == "yield"
  end

  assert_format "yield 1\n2", "yield 1\n2"
  assert_format "yield 1 , \n2", "yield 1,\n      2"
  assert_format "yield 1 , \n2", "yield 1,\n      2"
  assert_format "yield(1 , \n2)", "yield(1,\n      2,\n     )"
  assert_format "yield(\n1 , \n2)", "yield(\n        1,\n        2,\n     )"

  assert_format "with foo yield bar"

  assert_format "1   +   2", "1 + 2"
  assert_format "1   >   2", "1 > 2"
  assert_format "1   *   2", "1 * 2"
  assert_format "1/2", "1 / 2"
  assert_format "10/a", "10 / a"
  assert_format "! 1", "!1"
  assert_format "- 1", "-1"
  assert_format "~ 1", "~1"
  assert_format "+ 1", "+1"
  assert_format "a-1", "a - 1"
  assert_format "a+1", "a + 1"
  assert_format "1 + \n2", "1 +\n  2"
  assert_format "1 +  # foo\n2", "1 + # foo\n  2"
  assert_format "a = 1 +  #    foo\n2", "a = 1 + #    foo\n      2"

  assert_format "foo[]", "foo[]"
  assert_format "foo[ 1 , 2 ]", "foo[1, 2]"
  assert_format "foo[ 1,  2 ]?", "foo[1, 2]?"
  assert_format "foo[] =1", "foo[] = 1"
  assert_format "foo[ 1 , 2 ]   =3", "foo[1, 2] = 3"

  assert_format "1  ||  2", "1 || 2"
  assert_format "a  ||  b", "a || b"
  assert_format "1  &&  2", "1 && 2"
  assert_format "1 &&\n2", "1 &&\n  2"
  assert_format "1 &&\n2 &&\n3", "1 &&\n  2 &&\n  3"
  assert_format "if 0\n1 &&\n2 &&\n3\nend", "if 0\n  1 &&\n    2 &&\n    3\nend"
  assert_format "if 1 &&\n2 &&\n3\n4\nend", "if 1 &&\n   2 &&\n   3\n  4\nend"
  assert_format "if 1 &&\n   (2 || 3)\n  1\nelse\n  2\nend"
  assert_format "while 1 &&\n2 &&\n3\n4\nend", "while 1 &&\n      2 &&\n      3\n  4\nend"

  assert_format "def foo(x =  __FILE__ )\nend", "def foo(x = __FILE__)\nend"

  assert_format "a=1", "a = 1"

  assert_format "while 1\n2\nend", "while 1\n  2\nend"
  assert_format "until 1\n2\nend", "until 1\n  2\nend"

  assert_format "a = begin\n1\n2\nend", "a = begin\n      1\n      2\n    end"
  assert_format "a = if 1\n2\n3\nend", "a = if 1\n      2\n      3\n    end"
  assert_format "a = if 1\n2\nelse\n3\nend", "a = if 1\n      2\n    else\n      3\n    end"
  assert_format "a = if 1\n2\nelsif 3\n4\nend", "a = if 1\n      2\n    elsif 3\n      4\n    end"
  assert_format "a = [\n1,\n2]", "a = [\n      1,\n      2,\n    ]"
  assert_format "a = while 1\n2\nend", "a = while 1\n      2\n    end"
  assert_format "a = case 1\nwhen 2\n3\nend", "a = case 1\n    when 2\n      3\n    end"
  assert_format "a = case 1\nwhen 2\n3\nelse\n4\nend", "a = case 1\n    when 2\n      3\n    else\n      4\n    end"
  assert_format "a = \nif 1\n2\nend", "a =\n  if 1\n    2\n  end"
  assert_format "a, b = \nif 1\n2\nend", "a, b =\n  if 1\n    2\n  end"

  assert_format %(require   "foo"), %(require "foo")

  assert_format "private   getter   foo", "private getter foo"

  assert_format %("foo \#{ 1  +  2 }"), %("foo \#{1 + 2}")
  assert_format %("foo \#{ 1 } \#{ __DIR__ }"), %("foo \#{1} \#{__DIR__}")
  assert_format %("foo \#{ __DIR__ }"), %("foo \#{__DIR__}")
  assert_format "__FILE__", "__FILE__"
  assert_format "__DIR__", "__DIR__"
  assert_format "__LINE__", "__LINE__"

  assert_format "%w(one   two  three)", "%w(one two three)"
  assert_format "%i(one   two  three)", "%i(one two three)"

  assert_format "/foo/"
  assert_format "/foo/imx"
  assert_format "/foo \#{ bar }/", "/foo \#{bar}/"
  assert_format "%r(foo \#{ bar })", "%r(foo \#{bar})"
  assert_format "foo(/ /)"
  assert_format "foo(1, / /)"
  assert_format "/ /"
  assert_format "begin\n  / /\nend"
  assert_format "a = / /"
  assert_format "1 == / /"
  assert_format "if / /\nend"
  assert_format "while / /\nend"
  assert_format "[/ /, / /]"
  assert_format "{/ / => / /, / / => / /}"
  assert_format "case / /\nwhen / /, / /\n  / /\nend"
  assert_format "/\#{1}/imx"

  assert_format "`foo`"
  assert_format "`foo \#{ bar }`", "`foo \#{bar}`"
  assert_format "%x(foo \#{ bar })", "%x(foo \#{bar})"

  assert_format "module   Moo \n\n 1  \n\nend", "module Moo\n  1\nend"
  assert_format "class   Foo \n\n 1  \n\nend", "class Foo\n  1\nend"
  assert_format "struct   Foo \n\n 1  \n\nend", "struct Foo\n  1\nend"
  assert_format "class   Foo  < \n  Bar \n\n 1  \n\nend", "class Foo < Bar\n  1\nend"
  assert_format "module Moo ( T )\nend", "module Moo(T)\nend"
  assert_format "class Foo ( T )\nend", "class Foo(T)\nend"
  assert_format "abstract  class Foo\nend", "abstract class Foo\nend"
  assert_format "class Foo;end", "class Foo; end"
  assert_format "class Foo; 1; end", "class Foo\n  1\nend"
  assert_format "module Foo;end", "module Foo; end"
  assert_format "module Foo; 1; end", "module Foo\n  1\nend"
  assert_format "enum Foo;end", "enum Foo; end"
  assert_format "enum Foo; A = 1; end", "enum Foo\n  A = 1\nend"

  assert_format "@a", "@a"
  assert_format "@@a", "@@a"
  assert_format "$a", "$a"
  assert_format "$~", "$~"
  assert_format "$~.bar", "$~.bar"
  assert_format "$~ = 1", "$~ = 1"
  assert_format "$?", "$?"
  assert_format "$?.bar", "$?.bar"
  assert_format "$? = 1", "$? = 1"
  assert_format "$1", "$1"
  assert_format "$1.bar", "$1.bar"

  assert_format "foo . is_a? ( Bar )", "foo.is_a?(Bar)"
  assert_format "foo . responds_to?( :bar )", "foo.responds_to?(:bar)"
  assert_format "foo . is_a? Bar", "foo.is_a? Bar"
  assert_format "foo . responds_to? :bar", "foo.responds_to? :bar"

  assert_format "include  Foo", "include Foo"
  assert_format "extend  Foo", "extend Foo"

  assert_format "x  ::  Int32", "x :: Int32"
  assert_format "x  ::  Int32*", "x :: Int32*"
  assert_format "x  ::  Int32**", "x :: Int32**"
  assert_format "x  ::  A  |  B", "x :: A | B"
  assert_format "x  ::  A?", "x :: A?"
  assert_format "x  ::  Int32[ 8 ]", "x :: Int32[8]"
  assert_format "x  ::  (A | B)", "x :: (A | B)"
  assert_format "x  ::  (A -> B)", "x :: (A -> B)"
  assert_format "x  ::  (A -> B)?", "x :: (A -> B)?"
  assert_format "x  ::  {A, B}", "x :: {A, B}"
  assert_format "class Foo\n@x :: Int32\nend", "class Foo\n  @x :: Int32\nend"
  assert_format "class Foo\nx = 1\nend", "class Foo\n  x = 1\nend"

  assert_format "x = 1\nx    +=   1", "x = 1\nx += 1"
  assert_format "x[ y ] += 1", "x[y] += 1"
  assert_format "@x   ||=   1", "@x ||= 1"
  assert_format "@x   &&=   1", "@x &&= 1"
  assert_format "@x[ 1 ]   ||=   2", "@x[1] ||= 2"
  assert_format "@x[ 1 ]   &&=   2", "@x[1] &&= 2"
  assert_format "@x[ 1 ]   +=   2", "@x[1] += 2"
  assert_format "foo.bar   +=   2", "foo.bar += 2"
  assert_format "a[b] ||= c"

  assert_format "case  1 \n when 2 \n 3 \n end", "case 1\nwhen 2\n  3\nend"
  assert_format "case  1 \n when 2 \n 3 \n else \n 4 \n end", "case 1\nwhen 2\n  3\nelse\n  4\nend"
  assert_format "case  1 \n when 2 , 3 \n 4 \n end", "case 1\nwhen 2, 3\n  4\nend"
  assert_format "case  1 \n when 2 ,\n 3 \n 4 \n end", "case 1\nwhen 2,\n     3\n  4\nend"
  assert_format "case  1 \n when 2 ; 3 \n end", "case 1\nwhen 2; 3\nend"
  assert_format "case  1 \n when 2 ;\n 3 \n end", "case 1\nwhen 2\n  3\nend"
  assert_format "case  1 \n when 2 ; 3 \n when 4 ; 5\nend", "case 1\nwhen 2; 3\nwhen 4; 5\nend"
  assert_format "case  1 \n when 2 then 3 \n end", "case 1\nwhen 2 then 3\nend"
  assert_format "case  1 \n when 2 then \n 3 \n end", "case 1\nwhen 2\n  3\nend"
  assert_format "case  1 \n when 2 \n 3 \n when 4 \n 5 \n end", "case 1\nwhen 2\n  3\nwhen 4\n  5\nend"
  assert_format "if 1\ncase 1\nwhen 2\n3\nend\nend", "if 1\n  case 1\n  when 2\n    3\n  end\nend"
  assert_format "case  1 \n when  .foo? \n 3 \n end", "case 1\nwhen .foo?\n  3\nend"
  assert_format "case 1\nwhen 1 then\n2\nwhen 3\n4\nend", "case 1\nwhen 1\n  2\nwhen 3\n  4\nend"
  assert_format "case  1 \n when 2 \n 3 \n else 4 \n end", "case 1\nwhen 2\n  3\nelse 4\nend"

  assert_format "foo.@bar"

  assert_format "@[Foo]"
  assert_format "@[Foo()]", "@[Foo]"
  assert_format "@[Foo( 1, 2 )]", "@[Foo(1, 2)]"
  assert_format "@[Foo( 1, 2, foo: 3 )]", "@[Foo(1, 2, foo: 3)]"
  assert_format "@[Foo]\ndef foo\nend"
  assert_format "@[Foo(\n       1,\n     )]"

  assert_format "1   as   Int32", "1 as Int32"
  assert_format "foo.bar  as   Int32", "foo.bar as Int32"

  assert_format "1 .. 2", "1..2"
  assert_format "1 ... 2", "1...2"

  assert_format "typeof( 1, 2, 3 )", "typeof(1, 2, 3)"
  assert_format "sizeof( Int32 )", "sizeof(Int32)"
  assert_format "instance_sizeof( Int32 )", "instance_sizeof(Int32)"
  assert_format "pointerof( @a )", "pointerof(@a)"

  assert_format "_ = 1"

  assert_format "a , b  = 1  ,  2", "a, b = 1, 2"
  assert_format "a[1] , b[2] = 1  ,  2", "a[1], b[2] = 1, 2"

  assert_format "begin\n1\nensure\n2\nend", "begin\n  1\nensure\n  2\nend"
  assert_format "begin\n1\nrescue\n3\nensure\n2\nend", "begin\n  1\nrescue\n  3\nensure\n  2\nend"
  assert_format "begin\n1\nrescue   ex\n3\nend", "begin\n  1\nrescue ex\n  3\nend"
  assert_format "begin\n1\nrescue   ex   :   Int32 \n3\nend", "begin\n  1\nrescue ex : Int32\n  3\nend"
  assert_format "begin\n1\nrescue   ex   :   Int32  |  Float64  \n3\nend", "begin\n  1\nrescue ex : Int32 | Float64\n  3\nend"
  assert_format "begin\n1\nrescue   ex\n3\nelse\n4\nend", "begin\n  1\nrescue ex\n  3\nelse\n  4\nend"
  assert_format "begin\n1\nrescue   Int32 \n3\nend", "begin\n  1\nrescue Int32\n  3\nend"
  assert_format "if 1\nbegin\n2\nensure\n3\nend\nend", "if 1\n  begin\n    2\n  ensure\n    3\n  end\nend"
  assert_format "1 rescue 2"

  assert_format "def foo\n1\nrescue\n2\nend", "def foo\n  1\nrescue\n  2\nend"
  assert_format "def foo\n1\nensure\n2\nend", "def foo\n  1\nensure\n  2\nend"
  assert_format "class Foo\ndef foo\n1\nensure\n2\nend\nend", "class Foo\n  def foo\n    1\n  ensure\n    2\n  end\nend"
  assert_format "def run\n  \nrescue\n  2\n  3\nend"

  assert_format "macro foo\nend"
  assert_format "macro foo()\nend", "macro foo\nend"
  assert_format "macro foo( x , y )\nend", "macro foo(x, y)\nend"
  assert_format "macro foo( x  =   1, y  =  2,  &block)\nend", "macro foo(x = 1, y = 2, &block)\nend"
  assert_format "macro foo\n  1 + 2\nend"
  assert_format "macro foo\n  if 1\n 1 + 2 \n end \nend"
  assert_format "macro foo\n  {{ 1 + 2 }} \nend", "macro foo\n  {{1 + 2}} \nend"
  assert_format "macro foo\n  {% 1 + 2 %} \nend", "macro foo\n  {% 1 + 2 %} \nend"
  assert_format "macro foo\n  {{ 1 + 2 }}\\ \nend", "macro foo\n  {{1 + 2}}\\ \nend"
  assert_format "macro foo\n  {{ 1 + 2 }}\\ \n 1\n end", "macro foo\n  {{1 + 2}}\\ \n 1\n end"
  assert_format "macro foo\n  {%1 + 2%}\\ \nend", "macro foo\n  {% 1 + 2 %}\\ \nend"
  assert_format "macro foo\n  {% if 1 %} 2 {% end %} \nend"
  assert_format "macro foo\n  {% unless 1 %} 2 {% end %} \nend"
  assert_format "macro foo\n  {% if 1 %} 2 {% else %} 3 {% end %} \nend"
  assert_format "macro foo\n  {% if 1 %}\\ 2 {% else %}\\ 3 {% end %}\\ \nend"
  assert_format "macro foo\n  {% for x in y %} 2 {% end %} \nend"
  assert_format "macro foo\n  {% for x in y %}\\ 2 {% end %}\\ \nend"
  assert_format "macro foo\n  %foo \nend"
  assert_format "macro def foo : Int32\n  %foo \nend"
  assert_format "class Foo\n  macro foo\n    1\n  end\nend"
  assert_format "   {{ 1 + 2 }}", "{{1 + 2}}"
  assert_format "  {% for x in y %} 2 {% end %}", "{% for x in y %} 2 {% end %}"
  assert_format "  {% if 1 %} 2 {% end %}", "{% if 1 %} 2 {% end %}"
  assert_format "  {% if 1 %} {% if 2 %} 2 {% end %} {% end %}", "{% if 1 %} {% if 2 %} 2 {% end %} {% end %}"
  assert_format "if 1\n  {% if 2 %} {% end %}\nend"
  assert_format "if 1\n  {% for x in y %} {% end %}\nend"
  assert_format "if 1\n  {{1 + 2}}\nend"
  assert_format "macro def foo : self | Nil\n  nil\nend"
  assert_format "macro foo(x)\n  {% if 1 %} 2 {% end %} \nend"
  assert_format "macro foo()\n  {% if 1 %} 2 {% end %} \nend", "macro foo\n  {% if 1 %} 2 {% end %} \nend"
  assert_format "macro flags\n  {% if 1 %}\\\n  {% end %}\\\nend"
  assert_format "macro flags\n  {% if 1 %}\\\n 1 {% else %}\\\n {% end %}\\\nend"
  assert_format "macro flags\n  {% if 1 %}{{1}}a{{2}}{% end %}\\\nend"
  assert_format "  {% begin %} 2 {% end %}", "{% begin %} 2 {% end %}"
  assert_format "macro foo\n  \\{ \nend"

  assert_format "def foo\na = bar do\n1\nend\nend", "def foo\n  a = bar do\n        1\n      end\nend"
  assert_format "def foo\nend\ndef bar\nend", "def foo\nend\n\ndef bar\nend"
  assert_format "a = 1\ndef bar\nend", "a = 1\n\ndef bar\nend"
  assert_format "def foo\nend\n\n\n\ndef bar\nend", "def foo\nend\n\ndef bar\nend"
  assert_format "def foo\nend;def bar\nend", "def foo\nend\n\ndef bar\nend"
  assert_format "class Foo\nend\nclass Bar\nend", "class Foo\nend\n\nclass Bar\nend"

  assert_format "alias  Foo  =   Bar", "alias Foo = Bar"
  assert_format "alias A = (B)"
  assert_format "alias A = (B) -> C"

  assert_format "lib Foo\nend"
  assert_format "lib Foo\ntype  Foo  =   Bar\nend", "lib Foo\n  type Foo = Bar\nend"
  assert_format "lib Foo\nfun foo\nend", "lib Foo\n  fun foo\nend"
  assert_format "lib Foo\nfun foo  :  Int32\nend", "lib Foo\n  fun foo : Int32\nend"
  assert_format "lib Foo\nfun foo()  :  Int32\nend", "lib Foo\n  fun foo : Int32\nend"
  assert_format "lib Foo\nfun foo ()  :  Int32\nend", "lib Foo\n  fun foo : Int32\nend"
  assert_format "lib Foo\nfun foo(x   :   Int32, y   :   Float64)  :  Int32\nend", "lib Foo\n  fun foo(x : Int32, y : Float64) : Int32\nend"
  assert_format "lib Foo\nfun foo(x : Int32,\ny : Float64) : Int32\nend", "lib Foo\n  fun foo(x : Int32,\n          y : Float64) : Int32\nend"
  assert_format "lib Foo\nfun foo( ... )  :  Int32\nend", "lib Foo\n  fun foo(...) : Int32\nend"
  assert_format "lib Foo\nfun foo(x : Int32, ... )  :  Int32\nend", "lib Foo\n  fun foo(x : Int32, ...) : Int32\nend"
  assert_format "lib Foo\n  fun foo(Int32) : Int32\nend"
  assert_format "fun foo(x : Int32) : Int32\n  1\nend"
  assert_format "lib Foo\n  fun foo = bar(Int32) : Int32\nend"
  assert_format "lib Foo\n  fun foo = \"bar\"(Int32) : Int32\nend"
  assert_format "lib Foo\n  $foo  :  Int32 \nend", "lib Foo\n  $foo : Int32\nend"
  assert_format "lib Foo\n  $foo = hello  :  Int32 \nend", "lib Foo\n  $foo = hello : Int32\nend"
  assert_format "lib Foo\nalias  Foo  =  Bar -> \n$a : Int32\nend", "lib Foo\n  alias Foo = Bar ->\n  $a : Int32\nend"
  assert_format "lib Foo\nstruct Foo\nend\nend", "lib Foo\n  struct Foo\n  end\nend"
  assert_format "lib Foo\nstruct Foo\nx  :  Int32\nend\nend", "lib Foo\n  struct Foo\n    x : Int32\n  end\nend"
  assert_format "lib Foo\nstruct Foo\nx  :  Int32\ny : Float64\nend\nend", "lib Foo\n  struct Foo\n    x : Int32\n    y : Float64\n  end\nend"
  assert_format "lib Foo\nstruct Foo\nx  ,  y  :  Int32\nend\nend", "lib Foo\n  struct Foo\n    x, y : Int32\n  end\nend"
  assert_format "lib Foo\nstruct Foo\nx  ,  y  , z :  Int32\nend\nend", "lib Foo\n  struct Foo\n    x, y, z : Int32\n  end\nend"
  assert_format "lib Foo\nunion Foo\nend\nend", "lib Foo\n  union Foo\n  end\nend"

  assert_format "enum Foo\nend"
  assert_format "enum Foo\nA  \nend", "enum Foo\n  A\nend"
  assert_format "enum Foo\nA = 1\nend", "enum Foo\n  A = 1\nend"
  assert_format "enum Foo : Int32\nA = 1\nend", "enum Foo : Int32\n  A = 1\nend"
  assert_format "enum Foo : Int32\nA = 1\ndef foo\n1\nend\nend", "enum Foo : Int32\n  A = 1\n\n  def foo\n    1\n  end\nend"
  assert_format "lib Bar\n  enum Foo\n  end\nend"
  assert_format "lib Bar\n  enum Foo\n    A\n  end\nend"
  assert_format "lib Bar\n  enum Foo\n    A = 1\n  end\nend"

  assert_format "foo = 1\n->foo.bar"
  assert_format "foo = 1\n->foo.bar(Int32)"
  assert_format "foo = 1\n->foo.bar(Int32*)"
  assert_format "->{ x }"
  assert_format "->{\nx\n}", "->{\n  x\n}"
  assert_format "->do\nx\nend", "->do\n  x\nend"
  assert_format "->( ){ x }", "->{ x }"
  assert_format "->() do x end", "->do x end"
  assert_format "->( x , y )   { x }", "->(x, y) { x }"
  assert_format "->( x : Int32 , y )   { x }", "->(x : Int32, y) { x }"

  {:+, :-, :*, :/, :^, :>>, :<<, :|, :&}.each do |sym|
    assert_format ":#{sym}"
  end
  assert_format ":\"foo bar\""

  assert_format %("foo" \\\n "bar"), %("foo" \\\n"bar")
  assert_format %("foo" \\\n "bar" \\\n "baz"), %("foo" \\\n"bar" \\\n"baz")
  assert_format %("foo \#{bar}" \\\n "baz"), %("foo \#{bar}" \\\n"baz")

  assert_format "1   # foo", "1 # foo"
  assert_format "1  # foo\n2  # bar", "1 # foo\n2 # bar"
  assert_format "1  #foo  \n2  #bar", "1 # foo\n2 # bar"
  assert_format "if 1\n2  # foo\nend", "if 1\n  2 # foo\nend"
  assert_format "if 1\nelse\n2  # foo\nend", "if 1\nelse\n  2 # foo\nend"
  assert_format "if # some comment\n 2 # another\n 3 # final \n end # end ", "if  # some comment\n2 # another\n  3 # final\nend # end"
  assert_format "while 1\n2  # foo\nend", "while 1\n  2 # foo\nend"
  assert_format "def foo\n2  # foo\nend", "def foo\n  2 # foo\nend"
  assert_format "if 1\n# nothing\nend", "if 1\n  # nothing\nend"
  assert_format "if 1\nelse\n# nothing\nend", "if 1\nelse\n  # nothing\nend"
  assert_format "if 1 # foo\n2\nend", "if 1 # foo\n  2\nend"
  assert_format "if 1  # foo\nend", "if 1 # foo\nend"
  assert_format "while 1  # foo\nend", "while 1 # foo\nend"
  assert_format "while 1\n# nothing\nend", "while 1\n  # nothing\nend"
  assert_format "class Foo  # foo\nend", "class Foo # foo\nend"
  assert_format "class Foo\n# nothing\nend", "class Foo\n  # nothing\nend"
  assert_format "module Foo  # foo\nend", "module Foo # foo\nend"
  assert_format "module Foo\n# nothing\nend", "module Foo\n  # nothing\nend"
  assert_format "case 1 # foo\nwhen 2\nend", "case 1 # foo\nwhen 2\nend"
  assert_format "def foo\n# hello\n1\nend", "def foo\n  # hello\n  1\nend"
  assert_format "struct Foo(T)\n# bar\n1\nend", "struct Foo(T)\n  # bar\n  1\nend"
  assert_format "struct Foo\n  # bar\n  # baz\n1\nend", "struct Foo\n  # bar\n  # baz\n  1\nend"
  assert_format "(size - 1).downto(0) do |i|\n  yield @buffer[i]\nend"
  assert_format "(a).b { }\nc"
  assert_format "begin\n  a\nend.b { }\nc"
  assert_format "if a\n  b &c\nend"
  assert_format "foo (1).bar"
  assert_format "foo a: 1\nb"
  assert_format "if 1\n2 && 3\nend", "if 1\n  2 && 3\nend"
  assert_format "if 1\n  node.is_a?(T)\nend"
  assert_format "case 1\nwhen 2\n#comment\nend", "case 1\nwhen 2\n  # comment\nend"
  assert_format "case 1\nwhen 2\n\n#comment\nend", "case 1\nwhen 2\n  # comment\nend"
  assert_format "1 if 2\n# foo", "1 if 2\n# foo", strict: true
  assert_format "1 if 2\n# foo\n3"
  assert_format "1\n2\n# foo"
  assert_format "1\n2  \n  # foo", "1\n2\n# foo"
  assert_format "if 1\n2\n3\n# foo\nend", "if 1\n  2\n  3\n  # foo\nend"
  assert_format "def foo\n1\n2\n# foo\nend", "def foo\n  1\n  2\n  # foo\nend"
  assert_format "if 1\nif 2\n3 # foo\nend\nend", "if 1\n  if 2\n    3 # foo\n  end\nend"
  assert_format "class Foo\n1\n\n# foo\nend", "class Foo\n  1\n\n  # foo\nend"
  assert_format "module Foo\n1\n\n# foo\nend", "module Foo\n  1\n\n  # foo\nend"
  assert_format "if 1\n1\n\n# foo\nend", "if 1\n  1\n\n  # foo\nend"
  assert_format "while true\n1\n\n# foo\nend", "while true\n  1\n\n  # foo\nend"
  assert_format "def foo\nend\n\ndef bar\nend\n\n# foo"
  assert_format "1 && (\n       2 || 3\n     )"
  assert_format "class Foo\n  def foo\n    # nothing\n  end\nend"
  assert_format "while 1 # foo\n  # bar\n  2\nend"
  assert_format "foo(\n # foo\n1,\n\n # bar\n2,  \n)", "foo(\n     # foo\n     1,\n\n     # bar\n     2,\n   )"
  assert_format "foo do;\n1; end", "foo do\n  1\nend"
  assert_format "if 1;\n2; end", "if 1\n  2\nend"
  assert_format "while 1;\n2; end", "while 1\n  2\nend"
  assert_format "if 1;\n2;\nelse;\n3;\nend", "if 1\n  2\nelse\n  3\nend"
  assert_format "if 1;\n2;\nelsif 3;\n4;\nend", "if 1\n  2\nelsif 3\n  4\nend"
  assert_format "def foo\n  1\n  2\nrescue IO\n  1\nend"
  assert_format "def execute\n  begin\n    1\n  ensure\n    2\n  end\n  3\nend"
  assert_format "foo.bar=(2)\n1"
  assert_format "inner &.color=(@color)\n1"
  assert_format "ary.size = (1).to_i"
  assert_format "b &.[c].d"
  assert_format "b &.[c]?.d"
  assert_format "a &.b[c]?"
  assert_format "+ a + d", "+a + d"
  assert_format "  ((1) + 2)", "((1) + 2)"
  assert_format "if 1\n  ((1) + 2)\nend"

  # This case is special and must be fixed in the parser
  assert_format "def   foo  x   :  self ? \n  end", "def foo x : self ?\nend"

  assert_format "  macro foo\n  end\n\n  :+", "macro foo\n  end\n\n:+"
  assert_format "[\n1, # a\n2, # b\n 3 # c\n]", "[\n  1, # a\n  2, # b\n  3, # c\n]"
  assert_format "[\n  a() # b\n]", "[\n  a(), # b\n]"
  assert_format "[\n  a(), # b\n]", "[\n  a(), # b\n]"
  assert_format "[\n  a(),\n]", "[\n  a(),\n]"
  assert_format "if 1\n[\n  a() # b\n]\nend", "if 1\n  [\n    a(), # b\n  ]\nend"
end