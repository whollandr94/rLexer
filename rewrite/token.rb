class Token
  attr_accessor :name, :public_identifier, :system_idenitifier,
                :force_quirks, :self_closing, :attributes,
                :comment_or_character_data, :type

  def initialize
    @name = ""
    @force_quirks = false
    @self_closing = false
    @attributes = {}
    @comment_or_character_data = ""
  end

  def name
    @name
  end

  def comment_or_character_data
    @comment_or_character_data
  end
end
