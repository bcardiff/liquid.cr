require "./context"

module Liquid::Nodes
  abstract class Node
    getter children
    @children = Array(Node).new

    abstract def initialize(token)

    abstract def render(data, io)

    def <<(node : Node)
      @children << node
    end

    def_equals @children
  end

  class Root < Node
    def initialize
    end
    def initialize(token : Tokens::Token)
    end
    def render(data, io)
      @children.each &.render(data, io)
    end
  end

  class Unknow < Node
    def initialize(token : Tokens::Token)
    end
    def render(data, io)
    end
  end

  class Expression < Node
    @var : String
    def initialize(token : Tokens::Expression)
      @var = token.content
    end
    def render(data, io)
      io << data.get(@var)
    end
  end

  class Raw < Node
    @content : String
    def initialize(token : Tokens::Raw)
      @content = token.content
    end

    def render(data, io)
      io << @content
    end

    def_equals @children, @content

  end

  # Inside of a for-loop block, you can access some special variables:
  # Variable      	Description
  # loop.index 	    The current iteration of the loop. (1 indexed)
  # loop.index0   	The current iteration of the loop. (0 indexed)
  # loop.revindex 	The number of iterations from the end of the loop (1 indexed)
  # loop.revindex0 	The number of iterations from the end of the loop (0 indexed)
  # loop.first    	True if first iteration.
  # loop.last     	True if last iteration.
  # loop.length    	The number of items in the sequence.
  class For < Node
    GLOBAL = /for (?<var>\w+) in (?<range>.+)/
    RANGE = /(?<start>[0-9]+)\.\.(?<end>[0-9]+)/

    @loop_var : String
    @begin : Int32 | Iterator(Context::DataType)
    @end : Int32 | Iterator(Context::DataType)

    def initialize(token : Tokens::ForStatement)
      @loop_var = ""
      @begin = @end = 0
      if gmatch = token.content.match GLOBAL
        @loop_var = gmatch["var"]
        if rmatch = gmatch["range"].match RANGE
          @begin = rmatch["start"].to_i
          @end = rmatch["end"].to_i
        end
      end
    end

    def render_with_range(data, io)
      data = Context.new data
      i = 0
      start = @begin.as(Int32)
      stop = @end.as(Int32)
      start.upto stop do |x|
        data.set(@loop_var, x)
        data.set("loop.index", i+1)
        data.set("loop.index0", i)
        data.set("loop.revindex", stop - start - i + 1)
        data.set("loop.revindex0", stop - start - i)
        data.set("loop.first", x == start)
        data.set("loop.last", x == stop)
        data.set("loop.length", stop - start)
        children.each &.render(data, io)
        i +=1
      end
    end

    def render(data, io)
      if @begin.is_a?(Int32) && @end.is_a?(Int32)
        render_with_range data, io
      else

      end
    end
  end

  class If < Node

    @elsif : Array(ElsIf)?
    @else : Else?

    def initialize(token : Tokens::IfStatement)
    end
    def render(data, io)
    end

    def add_elsif(token : Tokens::ElsIfStatement) : ElsIf
      @elsif ||= Array(ElsIf).new
      @elsif.not_nil! << ElsIf.new token
      @elsif.not_nil!.last
    end

    def set_else(token : Tokens::ElseStatement) : Else
      @else = Else.new token
    end

     def set_else(node : Else) : Else
      @else = node
    end

    def_equals @elsif, @else, @children
  end

  class Else < Node
    def initialize(token : Tokens::ElseStatement)
    end
    def render(data, io)
    end
  end

  class ElsIf < Node
    def initialize(token : Tokens::ElsIfStatement)
    end
    def render(data, io)
    end
  end

end
