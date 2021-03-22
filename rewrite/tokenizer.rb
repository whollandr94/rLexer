require_relative 'token'
require 'strscan'

class Tokenizer

	attr_accessor :state, :input, :cursor, :current, :all_tokens, :token, :return_state,
							  :temporary_buffer, :cursor_offset

	def initialize(input)
		@state = :Data
		@input = input
		@cursor = -1
		@all_tokens = []
	end

	def run
		loop do
			consume

			case @state
			when :Data
				if peek?('&')
					@return_state = @state
					@state = :CharacterReference
					next
				end
				if peek?('<')
					@state = :TagOpen
					next
				end
				if eof?
					new_token(:EOF)
					@all_tokens.push(@token)
					break
				end
			when :CharacterReference
				@temporary_buffer = ""
				@temporary_buffer.concat('&')
				if ascii_alpha? or ascii_numeric?
					@state = :NamedCharacterReference
					reconsume
					next
				end
				if peek?('#')
					@temporary_buffer.concat(current_char)
					@state = :NumericCharacterReference
					next
				end
				#TODO - Add character buffer to attributes inclusive
				@temporary_buffer.each_char do |code_point|
					new_token(:CharacterReference)
					@token.comment_or_character_data.concat(code_point)
					@all_tokens.push(@token)
				end
			when :NamedCharacterReference
				offset = @cursor
				until NamedCharacters.new.potential_characters(@input[offset..@cursor]) == 0
					@temporary_buffer.concat(current_char)
					consume
				end

				# TODO - Add character buffer to attributes inclusive
				if false
				end
				if @temporary_buffer[-1]
				end
			when :TagOpen
				if peek?('!')
					@state = :MarkupDeclarationOpen
					next
				end
			when :MarkupDeclarationOpen
				if peek?('--')
					consume_characters('--')
					new_token(:Comment)
					@state = :CommentStart
					next
				end
				if peek?('DOCTYPE')
					consume_characters('DOCTYPE')
					@state = :DOCTYPE
					next
				end
			when :CommentStart
				if peek?('-')
					@state = :CommentStartDash
					next
				end
				if peek?('>')
					parse_error("abrupt-closing-of-empty-comment")
					@all_tokens.push(@token)
					@state = :Data
					next
				end
				@state = :Comment
				reconsume
				next
			when :CommentStartDash
				if peek?('-')
					@state = :CommentEnd
					next
				end
				if peek?('>')
					parse_error("abrupt-closing-of-empty-comment")
					@all_tokens.push(@token)
					@state = :Data
					next
				end
				if eof?
					parse_error("eof-in-comment")
					@all_tokens.push(@token)
					new_token(:EOF)
					@all_tokens.push(@token)
					break
				end
				@token.comment_or_character_data.concat('-')
				@state = :Comment
				reconsume
				next
			when :Comment
				if peek?('<')
					@token.comment_or_character_data.concat(current_char)
					@state = :CommentLessThanSign
					next
				end
				if peek?('-')
					@state = :CommentEndDash
					next
				end
				if peek?('0')
					parse_error("unexpected-null-character")
					@token.comment_or_character_data.concat("U+FFFD")
					next
				end
				if eof?
					parse_error("eof-in-comment")
					@all_tokens.push(@token)
					new_token(:EOF)
					@all_tokens.push(@token)
					break
				end
				@token.comment_or_character_data.concat(current_char)
				next
			when :CommentLessThanSign
				if peek?('!')
					@token.comment_or_character_data.concat(current_char)
					@state = :CommentLessThanSignBang
					next
				end
				if peek?('<')
					@state.comment_or_character_data.concat(current_char)
					next
				end
				@state = :Comment
				reconsume
			when :CommentLessThanSignBang
				if peek?('-')
					@state = :CommentLessThanSignBangDash
					next
				end
				@state = :Comment
				reconsume
			when :CommentLessThanSignBangDash
				if peek?('-')
					@state = :CommentLessThanSignBangDashDash
					next
				end
				@state = :CommentEndDash
				reconsume
			when :CommentLessThanSignBangDashDash
				if peek?('>') or eof?
					@state = :CommentEnd
					reconsume
					next
				end
				parse_error("nested-comment")
				@state = :CommentEnd
				reconsume
			when :CommentEndDash
				if peek?('-')
					@state = :CommentEnd
					next
				end
				if eof?
					parse_error("eof-in-comment")
					@all_tokens.push(@token)
					new_token(:EOF)
					@all_tokens.push(@token)
					break
				end
				@token.comment_or_character_data.concat('-')
				@state = :Comment
				reconsume
				next
			when :CommentEnd
				if peek?('>')
					@all_tokens.push(@token)
					@state = :Data
					next
				end
				if peek?('!')
					@state = :CommentEndBang
					next
				end
				if peek?('-')
					@token.comment_or_character_data.concat('-')
					next
				end
				if eof?
					parse_error("eof-in-comment")
					@all_tokens.push(@token)
					new_token(:EOF)
					@all_tokens.push(@token)
					break
				end
				@token.comment_or_character_data.concat('--')
				@state = :Comment
				reconsume
				next
			when :CommentEndBang
				if peek?('-')
					@token.comment_or_character_data.concat('--!')
					@state = :CommentEndDash
					next
				end
				if peek?('>')
					parse_error("incorrectly-closed-comment")
					@all_tokens.push(@token)
					@state = :Data
					next
				end
				if eof?
					parse_error("eof-in-comment")
					@all_tokens.push(@token)
					new_token(:EOF)
					@all_tokens.push(@token)
					break
				end
				@token.comment_or_character_data.concat('--!')
				@state = :Comment
				reconsume
				next
			when :DOCTYPE
				if whitespace?
					@state = :BeforeDOCTYPEName
					next
				end
			when :BeforeDOCTYPEName
				if whitespace?
					next
				end
				if ascii_alpha?
					new_token(:DOCTYPE)
					@token.name.concat(current_char)
					@state = :DOCTYPEName
					next
				end

			#Emit means push token to tokens array
			when :DOCTYPEName
				if whitespace?
					@state = :AfterDOCTYPEName
					next
				end
				if ascii_alpha?
					@token.name.concat(current_char)
					next
				end
				if peek?('>')
					@all_tokens.push(@token)
					@state = :Data
					next
				end
			else
				pp "#{@state} << EOF or something has gone wrong"
			end
		end
	end

	def peek?(pattern)
		return false if current_char.nil?
		return false if pattern.length == 0
		return false if get_scanner.peek(pattern.length) != pattern
		return true
	end

	def whitespace?
		return false if current_char.nil?
		return false if !["\t", "\n", "\f", " "].include?(current_char)
		return true
	end

	def ascii_alpha?
		return false if current_char.nil?
		return false if current_char.upcase == current_char.downcase
		return true
	end

	def ascii_numeric?
		return false if current_char.nil?
		return false if !current_char.match(/\d/)
		return true
	end

	def get_scanner
		pos = @cursor
		str = @input[pos..]
		return StringScanner.new(str)
	end

	def consume
		next_character
	end

	def reconsume
		prev_character
	end

	def consume_characters(characters)
		@cursor += characters.length-1
	end

	def next_character
		@cursor += 1
	end

	def prev_character
		@cursor -= 1
	end

	def current_char
		return @input[@cursor]
	end

	def eof?
		return false if !current_char.nil?
		return true
	end

	def parse_error(error)
		pp "Tokenization error: #{error}"
	end

	def new_token(token_type)
		@token = Token.new
		@token.type = token_type
	end
end
