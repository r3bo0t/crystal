module Crystal
  class Formatter < Visitor
    def self.format(source)
      nodes = Parser.parse(source)

      formatter = new(source)
      nodes.accept formatter
      formatter.to_s
    end

    def initialize(source)
      @lexer = Lexer.new(source)
      @lexer.comments_enabled = true
      @lexer.count_whitespace = true
      @lexer.wants_raw = true
      @token = next_token

      @output = StringIO.new(source.bytesize)
      @indent = 0
      @column = 0
    end

    def visit(node : Expressions)
      prelude indent: false

      old_indent = @indent
      base_ident = old_indent
      next_needs_indent = true

      has_paren = false
      has_begin = false

      if @token.type == :"("
        write "("
        next_needs_indent = false
        next_token
        has_paren = true
      elsif @token.keyword?(:begin)
        write "begin"
        write_line
        next_token_skip_space_or_newline
        if @token.type == :";"
          next_token_skip_space_or_newline
        end
        has_begin = true
        @indent += 2
        base_ident = @indent
      end

      node.expressions.each_with_index do |exp, i|
        @indent = 0 unless next_needs_indent
        exp.accept self
        @indent = base_ident

        skip_space

        if @token.type == :";"
          write "; " unless last?(i, node.expressions)
          next_token_skip_space_or_newline
          next_needs_indent = false
        else
          next_needs_indent = true
        end

        if last?(i, node.expressions)
          skip_space_or_newline
        else
          consume_newlines
        end
      end

      @indent = old_indent

      if has_paren
        check :")"
        write ")"
        next_token
      end

      if has_begin
        check_end
        next_token
        write_line
        @indent -= 2
        write_indent
        write "end"
      end

      false
    end

    def visit(node : Nop)
      prelude

      false
    end

    def visit(node : NilLiteral)
      prelude

      check_keyword :nil
      write "nil"
      next_token

      false
    end

    def visit(node : BoolLiteral)
      prelude

      check_keyword :false, :true
      write node.value
      next_token

      false
    end

    def visit(node : CharLiteral)
      prelude

      check :CHAR
      write @token.raw
      next_token

      false
    end

    def visit(node : SymbolLiteral)
      prelude

      check :SYMBOL
      write @token.raw
      next_token

      false
    end

    def visit(node : NumberLiteral)
      prelude

      check :NUMBER
      write @token.raw
      next_token

      false
    end

    def visit(node : StringLiteral)
      prelude

      check :DELIMITER_START

      write @token.raw
      @token = @lexer.next_string_token(@token.delimiter_state)

      while @token.type == :STRING
        write @token.raw
        @token = @lexer.next_string_token(@token.delimiter_state)
      end

      check :DELIMITER_END
      write @token.raw
      next_token

      false
    end

    def visit(node : ArrayLiteral)
      prelude

      case @token.type
      when :"["
        write "["

        bracket_indent = @indent + 1
        has_newlines = false
        next_token

        old_indent = @indent
        @indent = 0

        node.elements.each_with_index do |element, i|
          skip_space
          if @token.type == :NEWLINE
            @indent = bracket_indent
            write_line
            has_newlines = true
          elsif i > 0
            write " "
          end
          skip_space_or_newline
          element.accept self
          @indent = 0
          skip_space_or_newline

          if @token.type == :","
            write "," unless last?(i, node.elements)
            next_token
          end
        end

        @indent = old_indent

        skip_space_or_newline
        check :"]"

        if has_newlines
          write ","
          write_line
          write_indent
        end

        write "]"
      when :"[]"
        write "[]"
      end

      next_token_skip_space

      if node_of = node.of
        check_keyword :of
        write " of "
        next_token_skip_space_or_newline
        no_indent { node_of.accept self }
      end

      false
    end

    def visit(node : Path)
      prelude

      if node.global
        check :"::"
        write "::"
        next_token_skip_space_or_newline
      end

      node.names.each do |name|
        skip_space_or_newline
        check :CONST
        write @token.value
        next_token_skip_space
        if @token.type == :"::"
          write "::"
          next_token
        end
      end

      false
    end

    def visit(node : If)
      visit_if_or_unless node, :if, "if "
    end

    def visit(node : Unless)
      visit_if_or_unless node, :unless, "unless "
    end

    def visit_if_or_unless(node, keyword, prefix)
      prelude

      # This is the case of `cond ? exp1 : exp2`
      if keyword == :if && !@token.keyword?(:if)
        no_indent { node.cond.accept self }
        skip_space_or_newline
        check :"?"
        write " ? "
        next_token_skip_space_or_newline
        no_indent { node.then.accept self }
        skip_space_or_newline
        check :":"
        write " : "
        next_token_skip_space_or_newline
        no_indent { node.else.accept self }
        return false
      end

      check_keyword keyword
      write prefix
      next_token_skip_space_or_newline

      no_indent { node.cond.accept self }

      write_line

      unless node.then.is_a?(Nop)
        indent { node.then.accept self }
        write_line
      end

      skip_space_or_newline

      if @token.keyword?(:else)
        write_indent
        write "else"
        write_line
        next_token_skip_space_or_newline

        unless node.else.is_a?(Nop)
          indent { node.else.accept self }
        end
        @output.puts
      end

      write_indent
      write "end"

      false
    end

    def visit(node : Def)
      prelude

      check_keyword :def
      write "def "
      next_token_skip_space_or_newline

      if receiver = node.receiver
        no_indent { receiver.accept self }
        skip_space_or_newline
        check :"."
        write "."
        next_token_skip_space_or_newline
      end

      write node.name
      next_token_skip_space_or_newline

      to_skip = write_def_args node
      body = node.body

      if to_skip > 0
        body = node.body
        if body.is_a?(Expressions)
          body.expressions = body.expressions[to_skip .. -1]
          if body.expressions.empty?
            body = Nop.new
          end
        else
          body = Nop.new
        end
      end

      unless body.is_a?(Nop)
        write_line
        indent { body.accept self }
      end
      write_line
      write_indent

      skip_space_or_newline
      check_end
      write "end"
      next_token

      false
    end

    def write_def_args(node)
      to_skip = 0

      # If there are no args, remove extra "()", if any
      if node.args.empty?
        if @token.type == :"("
          next_token_skip_space_or_newline
          check :")"
          next_token_skip_space_or_newline
        end
      else
        prefix_size = @column + 1

        old_indent = @indent
        next_needs_indent = false
        has_newlines = false
        @indent = 0

        if @token.type == :"("
          write "("
          next_token_skip_space
          if @token.type == :NEWLINE
            write_line
            next_needs_indent = true
            has_newlines = true
          end
          skip_space_or_newline
        else
          write " "
        end

        node.args.each_with_index do |arg, i|
          @indent = prefix_size if next_needs_indent

          # The parser transforms `def foo(@x); end` to `def foo(x); @x = x; end` so if we
          # find an instance var we later need to skip the first expressions in the body
          if @token.type == :INSTANCE_VAR || @token.type == :CLASS_VAR
            to_skip += 1
          end

          arg.accept self
          @indent = 0
          skip_space_or_newline
          if @token.type == :","
            write "," unless last?(i, node.args)
            next_token_skip_space
            if @token.type == :NEWLINE
              write_line
              next_needs_indent = true
              has_newlines = true
            else
              next_needs_indent = false
              write " " unless last?(i, node.args)
            end
            skip_space_or_newline
          end
        end

        if @token.type == :")"
          if has_newlines
            write ","
            write_line
            @indent = prefix_size - 1
            write_indent
          end

          write ")"
          next_token_skip_space_or_newline
        end

        @indent = old_indent
      end

      to_skip
    end

    def visit(node : Arg)
      prelude
      write @token.value
      next_token

      if default_value = node.default_value
        skip_space_or_newline
        check :"="
        write " = "
        next_token_skip_space_or_newline
        no_indent { default_value.accept self }
      end

      if restriction = node.restriction
        skip_space_or_newline
        check :":"
        write " : "
        next_token_skip_space_or_newline
        no_indent { restriction.accept self }
      end

      false
    end

    def visit(node : Var)
      prelude
      write node.name
      next_token
      false
    end

    def visit(node : ASTNode)
      node.raise "missing handler for #{node.class}"
      true
    end

    def to_s(io)
      io << @output
    end

    def next_token
      @token = @lexer.next_token
    end

    def next_token_skip_space
      next_token
      skip_space
    end

    def next_token_skip_space_or_newline
      next_token
      skip_space_or_newline
    end

    def skip_space
      while @token.type == :SPACE
        next_token
      end
    end

    def skip_space_or_newline
      while @token.type == :SPACE || @token.type == :NEWLINE
        next_token
      end
    end

    def skip_semicolon
      while @token.type == :";"
        next_token
      end
    end

    def write_comment
      while @token.type == :COMMENT
        write_indent
        write @token.value
        next_token_skip_space
        consume_newlines
        skip_space_or_newline
      end
    end

    def consume_newlines
      if @token.type == :NEWLINE
        write_line
        next_token

        if @token.type == :NEWLINE
          write_line
        end

        skip_space_or_newline
      end
    end

    def prelude(indent = true)
      skip_space_or_newline
      write_comment
      write_indent if indent
    end

    def indent
      @indent += 2
      yield
      @indent -= 2
    end

    def no_indent
      old_indent = @indent
      @indent = 0
      yield
      @indent = old_indent
    end

    def write_indent
      @indent.times { write " " }
    end

    def write(string : String)
      @output << string
      @column += string.size
    end

    def write(obj)
      write obj.to_s
    end

    def write_line
      @output.puts
      @column = 0
    end

    def check_keyword(*keywords)
      raise "expecting keyword #{keywords.join " or "}, not #{@token.type}, #{@token.value}" unless keywords.any? { |k| @token.keyword?(k) }
    end

    def check(token_type)
      raise "expecting #{token_type}, not #{@token.type}" unless @token.type == token_type
    end

    def check_end
      check_keyword :end
    end

    def last?(index, collection)
      index == collection.size - 1
    end
  end
end
