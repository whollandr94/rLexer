require_relative 'tags'

class Tokenizer
  attr_accessor :html, :type, :Tags

  def initialize(html)
    @html = html.gsub('"', '\'')
    @type = :EOF
    @tokens = []
  end

  def tokenize
    @html.each_char.with_index do |ch, idx|
      comment_end(idx)
      next if @type == :COMMENT
      if open_tag?(ch) or close_tag?(ch)
        process(idx)
      end
    end
    consume_attributes
  end

  def process(idx)
    set_type(idx); consume(idx)
  end

  def consume(idx)
    if @type == :COMMENT
      consume_comment(idx)
    elsif @type == :OPEN or @type == :CLOSE
      consume_tag(idx)
    elsif @type == :DOCTYPE
      #consume_doctype(idx)
    elsif @type == :DATA
      consume_data(idx)
    end
  end

  def set_type(idx)
    if comment_start?(idx)
      @type = :COMMENT
    elsif end_tag?(idx)
      @type = :CLOSE
    elsif doctype?(idx)
      @type = :DOCTYPE
    elsif close_tag?(current_char(idx)) or comment_end?(idx)
      @type = :DATA
    elsif open_tag?(current_char(idx))
      @type = :OPEN
    end
  end

  def set_token(slice)
    @tokens.push([@type, slice])
  end

  def consume_comment(idx)
    slice = @html[idx..-1]
    slice = slice[Tags::START_COMMENT.length..end_comment_index(slice)]
    set_token(slice)
  end

  def consume_tag(idx)
    slice = @html[idx..-1]
    slice = slice[tag_index(slice)..slice.index(Tags::CLOSE_TAG) -1]
    set_token(slice)
  end

  def consume_attributes
    atts_new = []
    @tokens.each.with_index do |token, i|
      atts = token[1].split(' ')[1..-1]
      if token[0] == :OPEN and !atts[0].nil?
        atts_new.push([i, atts.join(' ').split("' ")])
      end
      @tokens[i][1] = @tokens[i][1].split(' ')[0] unless @tokens[i][0] == :COMMENT or @tokens[i][0] == :DATA
    end
    c = 1
    atts_new.each.with_index do |x|
      @tokens.insert(x[0] + c, [:ATTRIBUTES, x[1]])
      c += 1
    end
  end

  def consume_data(idx)
    return if next_char?(idx)

    slice = @html[idx..-1]
    slice = slice[Tags::CLOSE_TAG.length..slice.index(Tags::OPEN_TAG) -1]
    slice.strip!

    set_token(slice) unless slice == ''
  end

  def current_char(idx)
    @html[idx]
  end

  def end_comment_index(html)
    idx = html.index(Tags::END_COMMENT)
    (not idx.nil?) ? (idx + 2) - Tags::END_COMMENT.length : -1
  end

  def tag_index(html)
    (@type == :OPEN) ? Tags::OPEN_TAG.length : Tags::CLOSING_TAG.length
  end

  def comment_end(idx)
    return if not @type == :COMMENT
    if comment_end?(idx)
      set_type(idx)
    end
  end

  def comment_end?(idx)
    suitable?(idx, Tags::END_COMMENT)
  end

  def next_char?(idx)
    @html[idx +1] == Tags::OPEN_TAG or @html[idx +1].nil?
  end

  def end_tag?(idx)
    suitable?(idx, Tags::CLOSING_TAG)
  end

  def doctype?(idx)
    false
  end

  def comment_start?(idx)
    suitable?(idx, Tags::START_COMMENT)
  end

  def suitable?(idx, tag)
    tag == @html.byteslice(idx, tag.length)
  end

  def open_tag?(char)
    char == Tags::OPEN_TAG
  end

  def close_tag?(char)
    char == Tags::CLOSE_TAG
  end

  def tokens
    @tokens
  end
end
