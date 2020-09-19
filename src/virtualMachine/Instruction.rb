class Instruction
    attr_accessor :command, :value

    def initialize(command, value='')
        @command = command
        @value = value
    end
end